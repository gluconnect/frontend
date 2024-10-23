var bodyParser = require('body-parser');
var cookieParser = require('cookie-parser');
var cors = require('cors');
var express = require('express');
var socketio = require('socket.io');
var crypto = require('crypto');
var session = require('express-session');
var fs = require('fs');
var hostname = "127.0.0.1";
var app = express();
var server = require('http').createServer(app);
var port = 8008;
app.use(cors());
// Configuring body parser middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cookieParser());
app.use(session({ saveUninitialized: true, resave: true, secret: "ogbdfoodbkfpobfskpod32332323|_+sevsdvv//?~ZZ" }));
var Users = [{
        id: 'jack',
        name: "jackk",
        password: 'd74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1',
        readings: [
            {
                timestamp: new Date('December 17, 1995 03:24:00'),
                value: '120.4',
                meal: 'After Meal',
                comment: '',
                measure_method: 'blood sample',
                extra_data: new Map()
            },
            {
                timestamp: new Date('December 21, 1997 02:14:03'),
                value: '110.2',
                meal: 'Before Meal',
                comment: '',
                measure_method: 'blood sample',
                extra_data: new Map()
            }
        ]
    },
    {
        id: 'jack2',
        name: "jackk2",
        password: 'd74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1'
    }];
function toReading(x) {
    var glooc = {
        timestamp: new Date(),
        value: x.value,
        meal: x.meal,
        comment: x.comment,
        measure_method: x.measure_method,
        extra_data: new Map
    };
    //decode timestamp
    var _a = x.timestamp.split(' '), datePart = _a[0], timePart = _a[1];
    var _b = datePart.split('-'), year = _b[0], month = _b[1], day = _b[2];
    var _c = timePart.split(':'), hours = _c[0], minutes = _c[1], seconds = _c[2];
    glooc.timestamp = new Date(year, month - 1, day, hours, minutes, seconds);
    //
    return glooc;
}
function serializeReading(x) {
    var glooc = {
        timestamp: "",
        value: x.value,
        meal: x.meal,
        comment: x.comment,
        measure_method: x.measure_method,
        extra_data: ""
    };
    var date = x.timestamp;
    var year = date.getFullYear();
    var month = String(date.getMonth() + 1).padStart(2, '0'); // Months are zero-indexed
    var day = String(date.getDate()).padStart(2, '0');
    var hours = String(date.getHours()).padStart(2, '0');
    var minutes = String(date.getMinutes()).padStart(2, '0');
    var seconds = String(date.getSeconds()).padStart(2, '0');
    glooc.timestamp = "".concat(year, "-").concat(month, "-").concat(day, " ").concat(hours, ":").concat(minutes, ":").concat(seconds);
    return glooc;
}
//NumerIt code
function hash(value) {
    var hash = crypto.createHash('sha256');
    hash.update(value);
    return hash.digest('hex');
}
app.post('/register', function (req, res) {
    if (!req.body.email || !req.body.password) {
        res.sendStatus(401);
    }
    else {
        if (Users.some(function (user) { return user.id === req.body.email; })) {
            res.sendStatus(401);
        }
        else {
            Users.push({ id: req.body.email, password: hash(req.body.password), name: req.body.name });
            console.log(Users);
            res.sendStatus(200);
        }
    }
});
function verify(email, password) {
    if (!email || !password) {
        return null;
    }
    else {
        console.log("BENCH");
        var res_1 = null;
        Users.filter(function (user) {
            if (user.id === email && user.password === hash(password)) {
                console.log("crit");
                res_1 = user;
            }
        });
        return res_1;
    }
}
function getUser(req) {
    return Users.find(function (val) { return (req.session && req.session.user && val.id === req.session.user.email) || val.id === req.body.email; });
}
app.post('/verify', function (req, res) {
    var ree = verify(req.body.email, req.body.password);
    if (ree) {
        req.session.user = ree;
        console.log("HEY LOGIN WORKED");
        res.status(200).send(ree.name);
    }
    else {
        console.log("HEY LOGIN FALI");
        res.sendStatus(401);
    }
});
app.get('/logout', function (req, res) {
    req.session.destroy(function () {
        console.log("User logged out");
    });
    res.response(200);
});
//check if the provided creds are correct, if not, throw error and fail next step *use as middeware in all user account functions
function checkLogin(req, res, next) {
    if (req.session.user) {
        next();
    }
    else if (verify(req.body.email, req.body.password)) {
        next();
    }
    else {
        var err = new Error("Not logged in");
        next(err);
    }
}
app.post('/add_reading', checkLogin, function (req, res) {
    if (!req.body) { //TODO: VALIDATE BODY
        res.sendStatus(401);
    }
    else {
        var user = getUser(req);
        if (!user.readings)
            user.readings = [];
        user.readings.push(toReading(req.body));
        console.log(user.readings);
        res.sendStatus(200);
    }
});
app.post('/get_readings', checkLogin, function (req, res) {
    var user = getUser(req);
    console.log(user.readings);
    if (!user.readings)
        user.readings = [];
    res.status(200).json(user.readings.map(function (i) { return serializeReading(i); }));
});
app.post('/clear_readings', checkLogin, function (req, res) {
    var user = getUser(req);
    console.log(user.readings);
    user.readings = [];
    res.sendStatus(200);
});
app.post('/spectate_readings', checkLogin, function (req, res) {
    var user = getUser(req);
    if (!user.patients.some(function (v) { return v.email == req.uemail; })) { //make sure user authorizes patient.
        res.sendStatus(401);
        return;
    }
    var u = getUser({ body: { email: req.uemail } });
    res.status(200).json(u.readings.map(function (i) { return serializeReading(i); }));
});
app.post('/get_viewers', checkLogin, function (req, res) {
    var user = getUser(req);
    if (!user.viewers)
        user.viewers = [];
    var rs = user.viewers.map(function (i) {
        var u = getUser({ body: { email: i.email } });
        i.name = u.name;
        return i;
    });
    res.status(200).json(rs);
});
app.post('/get_patients', checkLogin, function (req, res) {
    var user = getUser(req);
    if (!user.patients)
        user.patients = [];
    var rs = user.patients.map(function (i) {
        var u = getUser({ body: { email: i.email } });
        i.name = u.name;
        return i;
    });
    res.status(200).json(rs);
});
app.post('/change_threshold', checkLogin, function (req, res) {
    var user = getUser(req);
    if (typeof req.body.threshold !== 'number') {
        res.sendStatus(401);
        return;
    }
    user.threshold = req.body.threshold;
    console.log(Users);
    res.status(200).send(req.body.threshold + "");
});
app.post('/get_threshold', checkLogin, function (req, res) {
    var user = getUser(req);
    console.log(Users);
    if (!user.threshold)
        user.threshold = -1;
    res.status(200).send(user.threshold + "");
});
app.post('/spectate_threshold', checkLogin, function (req, res) {
    var user = getUser(req);
    if (!user.patients.some(function (v) { return v.email == req.uemail; })) { //make sure user authorizes patient.
        res.sendStatus(401);
        return;
    }
    var u = getUser({ body: { email: req.uemail } });
    if (!u.threshold)
        u.threshold = -1;
    res.status(200).send(u.threshold);
});
app.post('/change_name', checkLogin, function (req, res) {
    var user = getUser(req);
    user.name = req.body.newname;
    console.log(Users);
    res.status(200).send(req.body.newname);
});
app.post('/change_password', checkLogin, function (req, res) {
    var user = getUser(req);
    user.password = hash(req.body.newpassword);
    console.log(Users);
    res.sendStatus(200);
});
app.post('/delete', function (req, res) {
    var user = getUser(req);
    if (user.viewers)
        for (var _i = 0, _a = user.viewers; _i < _a.length; _i++) { //remove connected users
            var v = _a[_i];
            var prey = getUser({ body: { email: v.email } });
            prey.patients = prey.patients.filter(function (val) { return val.email !== req.body.email; });
        }
    if (user.patients)
        for (var _b = 0, _c = user.patients; _b < _c.length; _b++) { //remove connected patients
            var v = _c[_b];
            var prey = getUser({ body: { email: v.email } });
            prey.viewers = prey.viewers.filter(function (val) { return val.email !== req.body.email; });
        }
    Users = Users.filter(function (val) { return !(val.id === req.body.email || (req.session && req.session.user && val.id === req.session.user.id)); });
    req.session.destroy(function () {
        console.log("User deleted");
    });
    console.log(Users);
    res.sendStatus(200);
});
app.post('/connect_user', checkLogin, function (req, res) {
    if (!req.body.uemail) {
        res.sendStatus(401);
    }
    else {
        var user = getUser(req);
        if (!user.viewers)
            user.viewers = [];
        else if (user.viewers.some(function (v) { return v.email === req.body.uemail; })) { //user already exists
            res.sendStatus(401);
            return;
        }
        user.viewers.push({ email: req.body.uemail, threshold: user.threshold });
        var prey = getUser({ body: { email: req.body.uemail } });
        if (!prey.patients)
            prey.patients = [];
        prey.patients.push({ email: req.body.email, threshold: user.threshold });
        res.sendStatus(200);
    }
});
app.post('/disconnect_user', checkLogin, function (req, res) {
    if (!req.body.uemail) {
        res.sendStatus(401);
    }
    else {
        console.log("disconnect user called");
        var user = getUser(req);
        console.log(user);
        if (!user.viewers)
            user.viewers = [];
        /*if(user.viewers){
          res.sendStatus(401);
          return;
        }*/
        user.viewers = user.viewers.filter(function (val) { return val.email !== req.body.uemail; });
        var prey = getUser({ body: { email: req.body.uemail } });
        console.log(prey);
        if (!prey.patients)
            prey.patients = [];
        prey.patients = prey.patients.filter(function (val) { return val.email !== req.body.email; });
        res.sendStatus(200);
    }
});
app.post('/disconnect_patient', checkLogin, function (req, res) {
    if (!req.body.uemail) {
        res.sendStatus(401);
    }
    else {
        console.log("disconnect patient called");
        var user = getUser(req);
        console.log(user);
        console.log(req.body.uemail === 'jack');
        if (!user.patients)
            user.patients = [];
        /*if(user.viewers){
          res.sendStatus(401);
          return;
        }*/
        user.patients = user.patients.filter(function (val) { return val.email !== req.body.uemail; });
        var prey = getUser({ body: { email: req.body.uemail } });
        console.log(prey);
        if (!prey.viewers)
            prey.viewers = [];
        prey.viewers = prey.viewers.filter(function (val) { return val.email !== req.body.email; });
        res.sendStatus(200);
    }
});
app.get('/', function(req, res){
  res.send("Hello");
})
/*app.use('/welcome', (err, req, res, next)=>{
  console.log(err)
  res.redirect('/login')
})
app.use('/delete', (err, req, res, next)=>{
  console.log(err)
  res.redirect('/login')
})
app.use('/setnum', (err, req, res, next)=>{
  console.log(err)
  res.redirect('/login')
})*/
server.listen(port, function () { return console.log("Le serveur est listener sur porte ".concat(port, "!")); });