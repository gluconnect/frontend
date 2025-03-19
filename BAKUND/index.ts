const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const cors = require('cors');
const express = require('express');
const socketio = require('socket.io');
import * as crypto from 'node:crypto';
const session = require('express-session');
const fs = require('fs');
const hostname = "127.0.0.1";

const app = express();
const server = require('http').createServer(app)
const port = 8008;

app.use(cors());

// Configuring body parser middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cookieParser())
app.use(session({ saveUninitialized: true, resave: true, secret: "ogbdfoodbkfpobfskpod32332323|_+sevsdvv//?~ZZ" }))

var Users: User[] = [{
  id: 'jack',
  name: "jackk",
  password: 'd74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1',
  readings: [
    {
      time: new Date('December 17, 1995 03:24:00'),
      value: 120.4,
      meal: 'After Meal',
      comment: '',
      measure_method: 'blood sample',
      extra_data: new Map()
    },
    {
      time: new Date('December 21, 1997 02:14:03'),
      value: 110.2,
      meal: 'Before Meal',
      comment: '',
      measure_method: 'blood sample',
      extra_data: new Map()
    }
  ],
  viewers: [],
  patients: [],
  threshold: -1,
},
{
  id: 'jack2',
  name: "jackk2",
  password: 'd74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1',
  readings: [
    {
      time: new Date('December 17, 2003 03:24:00'),
      value: 20.4,
      meal: 'After Meal',
      comment: '',
      measure_method: 'blood sample',
      extra_data: new Map()
    },
    {
      time: new Date('December 21, 1992 02:14:03'),
      value: 10.2,
      meal: 'Before Meal',
      comment: '',
      measure_method: 'blood sample',
      extra_data: new Map()
    }
  ],
  viewers: [],
  patients: [],
  threshold: -1,
}];
type User = {
  name: string,
  id: string,
  password: string,
  viewers: Array<{ email: string, threshold: number }>,
  patients: Array<{ email: string }>,
  threshold: number,
  readings: Array<GlucoReading>
}
type GlucoReading = {
  time: Date,
  value: number,
  meal: 'After Meal' | 'Before Meal',
  comment: string,
  measure_method: 'blood sample',
  extra_data: Map<string, any>
}
//returns a GlucoReading object from the request body
function toReading(x): GlucoReading {
  let glooc: GlucoReading = {
    time: new Date(x.time),
    value: x.value,
    meal: x.meal,
    comment: x.comment,
    measure_method: x.measure_method,
    extra_data: new Map
  }
  return glooc;
}
//returns a JSON object from a GlucoReading object
function serializeReading(x: GlucoReading) {
  let glooc = {
    timestamp: x.time.toISOString(),
    value: x.value,
    meal: x.meal,
    comment: x.comment,
    measure_method: x.measure_method,
    extra_data: ""
  }
  return glooc;
}
//hashes the password using sha256
function hash(value: string): string {
  const hash = crypto.createHash('sha256');
  hash.update(value);
  return hash.digest('hex');
}
//allow clients to create user accounts. Must have email and password and email must not be duplicate.
app.post('/register', (req, res) => {
  if (!req.body.email || !req.body.password) {
    res.sendStatus(401);
  } else {
    if (Users.some((user) => user.id === req.body.email)) {
      res.sendStatus(401);
    } else {
      Users.push({ id: req.body.email, password: hash(req.body.password), name: req.body.name, viewers: [], patients: [], threshold: -1, readings: [] });
      console.log("New User Created: ", req.body.email);
      res.sendStatus(200);
    }
  }
});
//return the user associated with the email and password if they exist, otherwise return null
function verifyUser(req: any/*TODO*/): User | undefined {
  if (!req.body || !req.body.email || !req.body.password) {
    return undefined;
  } else {
    let user = getUser(req.body.email);
    if (!user) return undefined;
    if(user.password === hash(req.body.password)){
      return user;
    }
  }
}
//TODO: might be deprecated
function getUser(email: string): User | undefined{
  return Users.find(function (user) {
    return user.id === email;
  });
}

//returns user associated with the email "uemail" if it is a patient of the user associated with the email "email" and the password is correct
//otherwise return null
function verifyPatient(req: any/*TODO*/): User | undefined {
  if (!req.body || !req.body.email || !req.body.password || !req.body.uemail) {
    return undefined;
  } else {
    let user = getUser(req.body.email);
    let ouser = getUser(req.body.uemail);
    if (!user) return undefined;
    if (user.patients.some((v) => v.email === req.body.uemail)) {
      return ouser;
    }
  }
}

//returns user associated with the email "uemail" if it is a viewer of the user associated with the email "email" and the password is correct
//otherwise return null
function verifyViewer(req: any/*TODO*/): User | undefined {
  if (!req.body || !req.body.email || !req.body.password || !req.body.uemail) {
    return undefined;
  } else {
    let user = getUser(req.body.email);
    let ouser = getUser(req.body.uemail);
    if (!user) return undefined;
    if (user.viewers.some((v) => v.email === req.body.uemail)) {
      return ouser;
    }
  }
}
//function getPatient(req)
//TODO: might be deprecated
app.get('/logout', function (req, res) {
  req.session.destroy(function () {
    console.log("User logged out")
  })
  res.response(200);
})
//check if the provided creds are correct, if not, throw error and fail next step *use as middeware in all user account functions
function checkLogin(req, res, next) {
  /*if (req.session.user) {
    next();
  } else */
  if (verifyUser(req)) {
    next();
  } else {
    var err = new Error("Not logged in")
    next(err);// Note: skips all remaining routes that can't handle the error
  }
}

//allows user to log in, if the provided email and password are correct
/*Possible response codes
200 - user logged in
401 - user not logged in
*/
app.post('/verify', (req, res) => {
  let user: User | undefined = verifyUser(req);
  if (user) {
    // req.session.user = ree;
    console.log("User logged in: ", user.id);
    res.status(200).send(user.name);
  } else {
    console.log("User failed to log in: ", req.body.email);
    res.sendStatus(401);
  }
})

//allows user to add a reading to their account, if the user is logged in and the request body is valid
/*Possible response codes
200 - reading added
400 - invalid request body
401 - user not logged in
*/
app.post('/add_reading', checkLogin, (req, res) => {
  if (!req.body) {//TODO: VALIDATE BODY
    res.sendStatus(400);
  } else {
    let user = verifyUser(req);
    if(!user){
      res.sendStatus(401);
      return;
    }
    let reading;
    try {
      reading = toReading(req.body);
    } catch (e) {
      res.sendStatus(400);
      return;
    }
    user.readings.push(reading);
    /*if (req.body.value >= user.threshold && user.viewers) {
      for (let v of user.viewers) {
        let u = getUser({ body: { email: v.email } });
        if (!u.warnings) u.warnings = [];
        u.warnings.push({ email: user?.id, reading: reading });
      }
    } TODO*/
    res.sendStatus(200);
  }
})

//returns all readings associated with the user, if the user is logged in
/*Possible response codes
200 - readings returned
401 - user not logged in
*/
app.post('/get_readings', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  if (!user.readings) user.readings = [];
  res.status(200).json(user.readings.map((i) => serializeReading(i)));
})

//clears all readings associated with the user, if the user is logged in
/*Possible response codes
200 - readings cleared
401 - user not logged in
*/
//Note: Not currently used by any client
app.post('/clear_readings', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  user.readings = [];
  res.sendStatus(200);
})

//returns all readings associated with the patient specified by the email in the request body, if the user is logged in and has authorized the patient
/*Possible response codes
200 - readings returned
401 - user not logged in
403 - user not authorized to view patient
*/
app.post('/spectate_readings', checkLogin, (req, res) => {
  let user = verifyPatient(req);
  if (!user) {
    if(verifyUser(req)) {//user is logged in but not authorized to view patient
      res.sendStatus(403);
      return;
    }
    res.sendStatus(401);
    return;
  }
  res.status(200).json(user.readings.map((i) => serializeReading(i)));
})

//returns all viewers associated with the user, if the user is logged in
/*Possible response codes
200 - viewers returned
401 - user not logged in
*/
app.post('/get_viewers', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  let rs = user.viewers.map(function (i) {
    let n = {
      email: i.email,
      threshold: i.threshold,
      name: ''
    }
    let u = getUser(i.email);
    if (!u) return i;
    n.name = u.name;
    return n;
  });
  res.status(200).json(rs);
})

//returns all patients associated with the user, if the user is logged in
/*Possible response codes
200 - patients returned
401 - user not logged in
*/
app.post('/get_patients', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  let rs = user.patients.map(function (i) {
    let n = {
      email: i.email,
      name: ''
    }
    let u = getUser(i.email);
    if (!u) return i;
    n.name = u.name;
    return n;
  });
  res.status(200).json(rs);
})
//returns the threshold associated with the user, if the user is logged in
/*Possible response codes
200 - threshold returned
401 - user not logged in
400 - invalid threshold
*/
app.post('/change_threshold', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  if (typeof req.body.threshold !== 'number') {
    res.sendStatus(400);
    return;
  }
  user.threshold = req.body.threshold;
  res.status(200).send(user.threshold + "");
})

//returns the threshold associated with the user, if the user is logged in
/*Possible response codes
200 - threshold returned
401 - user not logged in
*/
app.post('/get_threshold', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  res.status(200).send(user.threshold + "");
})

//returns the threshold associated with the patient specified by the email in the request body, if the user is logged in and has authorized the patient
/*Possible response codes
200 - threshold returned
401 - user not logged in
403 - user not authorized to view patient
*/
app.post('/spectate_threshold', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  let u = verifyPatient(req);
  if (!u) {
    if (verifyUser(req)) {//user is logged in but not authorized to view patient
      res.sendStatus(403);
      return;
    }
    res.sendStatus(401);
    return;
  }
  res.status(200).send(u.threshold);
})

//changes name and returns the name associated with the user, if the user is logged in
/*Possible response codes
200 - name changed
401 - user not logged in
*/
app.post('/change_name', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  user.name = req.body.newname;
  res.status(200).send(req.body.newname);
})

//changes password and returns the name associated with the user, if the user is logged in
/*Possible response codes
200 - password changed
401 - user not logged in
400 - invalid password
*/
app.post('/change_password', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  if (!req.body.newpassword) {
    res.sendStatus(400);
    return;
  }
  user.password = hash(req.body.newpassword);
  res.sendStatus(200);
})

//deletes the user account and all associated readings, viewers, and patients
/*Possible response codes
200 - user deleted
401 - user not logged in
*/
app.post('/delete', (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  if (user.viewers) for (var v of user.viewers) {//remove connected users
    let prey = getUser(v.email);
    if (!prey) continue; //if prey is not found, skip
    prey.patients = prey.patients.filter((val) => val.email !== req.body.email);
  }
  if (user.patients) for (var v2 of user.patients) {//remove connected patients
    let prey = getUser(v2.email);
    if (!prey) continue; //if prey is not found, skip
    prey.viewers = prey.viewers.filter((val) => val.email !== req.body.email);
  }
  Users = Users.filter((val) => !(val.id === req.body.email || (req.session && req.session.user && val.id === req.session.user.id)));
  req.session.destroy(function () {
    console.log("User deleted: ", req.body.email);
  })
  res.sendStatus(200);
})

//connects the user "viewer/caretaker" to another user "patient/user", allowing them to view their readings and threshold
/*Possible response codes
200 - user connected
401 - user not logged in
403 - user already connected to patient
404 - other user does not exist
*/
app.post('/connect_user', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  let prey = getUser(req.body.uemail);
  if (!prey) {
    res.sendStatus(404); //other user does not exist
    return;
  }
  if (user.viewers.some((e)=>e.email===prey.id)) {
    res.sendStatus(403); //user is already connected to prey
    return;
  }
  user.viewers.push({ email: prey.id, threshold: prey.threshold });
  prey.patients.push({ email: user.id });
  console.log("User connected: ", user.id, " to ", prey.id);
  res.sendStatus(200);
})
app.post('/disconnect_user', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  let prey = verifyViewer(req);
  if (!prey) {
    res.sendStatus(403);
    return;
  }
  console.log("User disconnected: ", user.id, " from ", prey.id);
  user.viewers = user.viewers.filter((val) => val.email !== prey.id);
  prey.patients = prey.patients.filter((val) => val.email !== user.id);
  res.sendStatus(200);
})
app.post('/disconnect_patient', checkLogin, (req, res) => {
  let user = verifyUser(req);
  if (!user) {
    res.sendStatus(401);
    return;
  }
  let prey = verifyPatient(req);
  if (!prey) {
    res.sendStatus(403);
    return;
  }
  console.log("User disconnected: ", user.id, " from ", prey.id);
  user.viewers = user.viewers.filter((val) => val.email !== prey.id);
  prey.patients = prey.patients.filter((val) => val.email !== user.id);
  res.sendStatus(200);
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
server.listen(port, () => console.log(`Le serveur est listener sur porte ${port}!`));