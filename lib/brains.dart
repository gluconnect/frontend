import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_ble/universal_ble.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'redbone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Caretaker {
  static var count = 1;
  Caretaker({this.id = "", this.name = "Glucometer"});
  String name = "HELLOWORLD";
  String id;
}

class Patient {
  static var count = 1;
  Patient({this.id = "", this.name = "Glucometer"});
  String name = "HELLOWORLD";
  String id; //email
}

class GlucoReading {
  DateTime timestamp = DateTime(0);
  double value = 0.0;
  String meal = "Before Meal";
  String comment = "";
  String measure_method = "blood sample";
  Map<String, dynamic>? extra_data;
  bool isDangerous = false;
  GlucoReading(dynamic thing) {
    timestamp = DateTime.parse(thing['time']);
    value = thing['value'];
    meal = thing['meal'];
    if (true) {
      comment = thing['comment'];
    }
    measure_method = thing['measure_method']!;
    extra_data = null; //thing['extra_data'];
  }
}

class LogInResponse {
  //
}

class MyAppState extends ChangeNotifier {
  var userIsAuthed = false;
  List glucometers = <Glucometer>[];
  List caretakers = <Caretaker>[];
  List patients = <Patient>[];
  List<GlucoReading> myReadings = <GlucoReading>[];
  List<GlucoReading> patientReadings = <GlucoReading>[];
  bool readingscorrect = false;
  bool patientreadingscorrect = false;
  String lastreadingsemail = "";
  var lastinfo = {"user": "", "pass": "", "name": ""};
<<<<<<< HEAD
  //var URL = "http://occidentalis.local:8008";
=======
  // var URL = "http://occidentalis.local:8008";
>>>>>>> b8515e75b6d15df10fc5ea96b72c98b5be486e9c
  var URL = "http://localhost:8008";
  var servdowncode = 501;
  var ishttpying = false;
  bool istoothing = false;
  bool nup = false;
  void addGlucometer({String name = "", BleDevice? dev}) {
    glucometers.add(Glucometer(id: Glucometer.count, name: name, meter: dev));
    Glucometer.count++;
    //nup = true;
  }

  Future<String> updateGlucometers(Function? callback) async {
    if (istoothing) {
      return "PRevious reading not done!!!!!!";
    }
    nup = false;
    istoothing = true;
    String ress = "";
    for (Glucometer g in glucometers) {
      String res = await g.update(this);
      ress += "$res;";
    }
    if (nup) {
      if (callback != null) callback();
    }
    //print("BLESS: $ress");
    istoothing = false;
    nup = false;
    return ress;
  }

  Future<http.Response> tagTimeout(Future<http.Response> r) {
    return r.timeout(const Duration(seconds: 5));
  }
  void flagReadings() {
    for (GlucoReading g in myReadings) {
      if (g.value >= double.parse(lastinfo['threshold']!)) {
        g.isDangerous = true;
      } else {
        g.isDangerous = false;
      }
    }
  }
  void flagPatientReadings() {
    for (GlucoReading g in patientReadings) {
      if (g.value >= double.parse(lastinfo['othreshold']!)) {
        g.isDangerous = true;
      } else {
        g.isDangerous = false;
      }
    }
  }
  bool alreadyHaveReadingLocally(DateTime reading_timestamp) {
    return myReadings.any((GlucoReading e) => reading_timestamp == e.timestamp);
  }

  Future<int> addReadingLocallyAndToServer( DateTime timestamp, double value, meal, method, comments) async {
    if (alreadyHaveReadingLocally(timestamp)) {
      return 0;
    }

    Future<int> sendReadingToServer(String u, String p, DateTime timestamp, double value, meal, method, comments) async {
      ishttpying = true;
      final response = await tagTimeout(http.post(
        Uri.parse('$URL/add_reading'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': u,
          'password': p,
          'time': timestamp.toIso8601String(),
          'value': value,
          'meal': meal,
          'measure_method': method,
          'comment': comments,
          'extra_data': "{}"
        }),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        //If the server return 200, add caretaker
        return response.statusCode; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        //fail and tell user
        return response.statusCode;
      } else {
        return 0;
      }
    }

    int rp = 500;
    try {
      //print("ADDDDDD");
      rp = await sendReadingToServer(lastinfo["user"]!, lastinfo["pass"]!, timestamp, value,
          meal, method, comments);
    } catch (e) {
      //print(e);
    }
    if (rp == 200) {
      //print('{"time": "${timestamp.toIso8601String()}","value": $value,"meal": "$meal","comment": "$comments","measure_method": "$method","extra_data": {}}');
      dynamic ss = jsonDecode(
          '{"time": "${timestamp.toIso8601String()}","value": $value,"meal": "$meal","comment": "$comments","measure_method": "$method","extra_data": {}}');
      //print("suxes $ss");
      nup = true;
      myReadings.add(GlucoReading(ss));
      flagReadings();
      readingscorrect = false;
      //print(myReadings);
      notifyListeners();
    } else {
      //callback("User does not exist");
    }
    return rp;
  }

  //request the server to authorize another user as a caretaker. If successful, return the correct code so that the user can be added to the list
  Future<int> addCaretaker(email) async {
    Future<int> addCT(String u, String p, String ou) async {
      ishttpying = true;
      final response = await tagTimeout(http.post(
        Uri.parse('$URL/connect_user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'uemail': ou}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        //If the server return 200, add caretaker
        return response.statusCode; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        //fail and tell user
        return response.statusCode;
      } else {
        return 0;
      }
    }

    int rp = 500;
    try {
      rp = await addCT(lastinfo["user"]!, lastinfo["pass"]!, email);
    } catch (e) {
      //print(e);
    }
    if (rp == 200) {
      caretakers.add(Caretaker(id: email, name: email /*TODO*/));
      //callback();
    } else {
      //callback("User does not exist");
    }
    return rp;
  }

  void deleteGlucometer(id) {
    glucometers.removeWhere((i) => i.id == id);
  }

  Future<int> deleteCaretaker(id, Function callback) async {
    Future<int> remCT(String u, String p, String ou) async {
      ishttpying = true;
      final response = await tagTimeout(http.post(
        Uri.parse('$URL/disconnect_user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'uemail': ou}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response.statusCode; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response.statusCode; //throw Exception('Failed to load album');
      } else {
        return 0;
      }
    }

    int rp = 500;
    try {
      rp = await remCT(lastinfo["user"]!, lastinfo["pass"]!, id);
    } catch (e) {
      //print(e);
    }
    if (rp == 200) {
      caretakers.removeWhere((i) => i.id == id);
      callback();
    } else {
      callback("Something went wrong");
    }
    return rp;
  }

  Future<int> deletePatient(id, Function callback) async {
    Future<int> remPT(String u, String p, String ou) async {
      ishttpying = true;
      final response = await tagTimeout(http.post(
        Uri.parse('$URL/disconnect_patient'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'uemail': ou}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response.statusCode; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response.statusCode; //throw Exception('Failed to load album');
      } else {
        return 0;
      }
    }

    int rp = 500;
    try {
      rp = await remPT(lastinfo["user"]!, lastinfo["pass"]!, id);
    } catch (e) {
      //print(e);
    }
    if (rp == 200) {
      patients.removeWhere((i) => i.id == id);
      callback();
    } else {
      callback("Something went wrong");
    }
    return rp;
  }

  Future<List?> getPatients() async {
    Future<http.Response> getPT(String u, String p) async {
      //print("$u $p");
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/get_patients'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await getPT(lastinfo["user"]!, lastinfo["pass"]!);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      List res = jsonDecode(rp.body);
      //print(res);
      patients =
          res.map((v) => Patient(id: v['email'], name: v['name'])).toList();
      return res;
    } else {
      return null;
    }
  }

  Future<List?> getCaretakersFromServerToLocal() async {
    Future<http.Response> getCaretakersHTTP(String u, String p) async {
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/get_viewers'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await getCaretakersHTTP(lastinfo["user"]!, lastinfo["pass"]!);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      List res = jsonDecode(rp.body);
      //print(res);
      caretakers =
          res.map((v) => Caretaker(id: v['email'], name: v['name'])).toList();
      return res;
    } else {
      return null;
    }
  }

  Future<List?> getReadingsFromServerToLocal() async {
    Future<http.Response> getReadingsFromServerHTTP(String u, String p) async {
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/get_readings'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await getReadingsFromServerHTTP(lastinfo["user"]!, lastinfo["pass"]!);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      List<dynamic> res = jsonDecode(rp.body);
      //print(res);
      try {
        this.myReadings = res.map((v) => GlucoReading(v)).toList();
      } catch (e) {
        //print(e);
        return null;
      }
      flagReadings();
      print("myReadings now: $myReadings");
      readingscorrect = true;
      notifyListeners();

      return myReadings;
    } else {
      return null;
    }
  }

  Future<List?> getPatientReadingsFromServerToLocal(otheremail) async {
    Future<http.Response> getPatientReadingsFromServerHTTP(String u, String p, String o) async {
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/spectate_readings'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'uemail': o}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await getPatientReadingsFromServerHTTP(lastinfo["user"]!, lastinfo["pass"]!, otheremail);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      List<dynamic> res = jsonDecode(rp.body);
      try {
        patientReadings = res.map((v) => GlucoReading(v)).toList();
        flagPatientReadings();
        //print(patientReadings);
      } catch (e) {
        return null;
      }

      patientreadingscorrect = true;
      notifyListeners();
      return patientReadings;
    } else {
      return null;
    }
  }

  Future<String?> getPatientName(otheremail) async {
    Future<http.Response> getRD(String u, String p, String o) async {
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/get_patient_name'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'uemail': o}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await getRD(lastinfo["user"]!, lastinfo["pass"]!, otheremail);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      String s = rp.body;
      //print("name obtained: $s");
      //lastinfo['othreshold'] = threshold.toString();
      return s;
    } else {
      return null;
    }
  }

  Future<String?> getCaretakerName(otheremail) async {
    Future<http.Response> getRD(String u, String p, String o) async {
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/get_user_name'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'uemail': o}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await getRD(lastinfo["user"]!, lastinfo["pass"]!, otheremail);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      String s = rp.body;
      //lastinfo['othreshold'] = threshold.toString();
      return s;
    } else {
      return null;
    }
  }

  Future<double?> getThreshold() async {
    Future<http.Response> getRD(String u, String p) async {
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/get_threshold'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await getRD(lastinfo["user"]!, lastinfo["pass"]!);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      //print("got threshold in req");
      double threshold = double.parse(rp.body);
      lastinfo['threshold'] = threshold.toString();
      //print("Benchmark 2");
      return threshold;
    } else {
      return null;
    }
  }

  Future<double?> spectateThreshold(otheremail) async {
    Future<http.Response> getRD(String u, String p, String o) async {
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/spectate_threshold'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'uemail': o}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await getRD(lastinfo["user"]!, lastinfo["pass"]!, otheremail);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      double threshold = double.parse(rp.body);
      lastinfo['othreshold'] = threshold.toString();
      return threshold;
    } else {
      return null;
    }
  }

  Future<double?> changeThreshold(double nname) async {
    Future<http.Response> change(String u, String p, double nname) async {
      //print("$u $p");
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/change_threshold'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, dynamic>{'email': u, 'password': p, 'threshold': nname}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await change(lastinfo["user"]!, lastinfo["pass"]!, nname);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      lastinfo['threshold'] = nname.toString();
      flagReadings();
      return double.parse(rp.body);
    } else {
      return null;
    }
  }

  Future<String?> changeName(String nname) async {
    Future<http.Response> change(String u, String p, String nname) async {
      //print("$u $p");
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/change_name'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'newname': nname}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await change(lastinfo["user"]!, lastinfo["pass"]!, nname);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      lastinfo["name"] = rp.body;
      return rp.body;
    } else {
      return null;
    }
  }

  Future<String?> changePass(String npass) async {
    Future<http.Response> change(String u, String p, String npass) async {
      //print("$u $p");
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/change_password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'email': u, 'password': p, 'newpassword': npass}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await change(lastinfo["user"]!, lastinfo["pass"]!, npass);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      lastinfo["pass"] = npass;
      return rp.body;
    } else {
      return null;
    }
  }

<<<<<<< HEAD
  Future<int> logIn(username, password, serv, LocalStorageState ls) async {
    print("${"User: " + username} Password: " + password);
=======
  Future<int> logIn(username, password, serv) async {
    //print("${"User: " + username} Password: " + password);
>>>>>>> b8515e75b6d15df10fc5ea96b72c98b5be486e9c

    Future<int> logInHTTP(String u, String p) async {
      ishttpying = true;
      final response = await tagTimeout(http.post(
        Uri.parse('$URL/verify'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'email': u, 'password': p}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        userIsAuthed = true;
        lastinfo["name"] = response.body;

        return response.statusCode; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response.statusCode; //throw Exception('Failed to load album');
      } else {
        return 0;
      }
    }

    int rp = 500;
    URL = serv;
    try {
      rp = await logInHTTP(username, password);
    } catch (e) {
      //print(e);
    }

    if (rp == 200) {
      lastinfo["user"] = username;
      lastinfo["pass"] = password;
      ls.updateLoginInfo(lastinfo);
    }

    return rp;
  }

  Future<int> register(username, password, nickname) async {
    //print("${"User: " + username} Password: " + password);
    Future<int> logIn(String u, String p, String n) async {
      ishttpying = true;
      final response = await tagTimeout(http.post(
        Uri.parse('$URL/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body:
            jsonEncode(<String, String>{'email': u, 'password': p, 'name': n}),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response.statusCode; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response.statusCode; //throw Exception('Failed to load album');
      } else {
        return 0;
      }
    }

    int rp = 500;
    try {
      rp = await logIn(username, password, nickname);
    } catch (e) {
      //print(e);
    }
    //print(rp);
    return rp;
  }

  Future<void> logOut(LocalStorageState ls) async{
    lastinfo["user"] = "";
    lastinfo["pass"] = "";
    userIsAuthed = false;
    myReadings = [];
    readingscorrect = false;
    await ls.clearLoginInfo();
  }

  Future<int> deleteAccount(LocalStorageState ls) async {
    Future<http.Response> change(String u, String p) async {
      //print("$u $p");
      ishttpying = true;
      final http.Response response = await tagTimeout(http.post(
        Uri.parse('$URL/delete'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      ));
      ishttpying = false;
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response; // as Map<String, String>;
      } else if (response.statusCode == 401) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response; //throw Exception('Failed to load album');
      } else {
        return response;
      }
    }

    http.Response? rp;
    try {
      rp = await change(lastinfo["user"]!, lastinfo["pass"]!);
    } catch (e) {
      //print(e);
    }
    if (rp != null && rp.statusCode == 200) {
      await logOut(ls);
      return rp.statusCode;
    } else {
      return 0;
    }
  }
}
class LocalStorageState extends ChangeNotifier{
  SharedPreferencesAsync? prefs;
  LocalStorageState(){
    initPrefs();
  }
  void initPrefs()async{
    prefs = SharedPreferencesAsync();
  }
  void updateLoginInfo(Map<String, String> loginfo) async{
    await prefs?.setString("authuser", loginfo["user"]!);
    await prefs?.setString("authpass", loginfo["pass"]!);
    print("updating local info "+loginfo.toString());
  }
  void updateGlucometerInfo(List<Glucometer> l) async{
    List<String> res = [];
    for(Glucometer g in l){
      if(g.meter!=null){
        res.add(g.meter!.deviceId);
      }
    }
    await prefs?.setStringList("bleglucometers", res);
  }
  void tryFetchLoginInfo(MyAppState s) async{
    if(prefs==null){
      print("login fetch: No preferences");
      initPrefs();
      print("nevermind");
      if(prefs==null)return;
    }
    String? user = await prefs!.getString("authuser");
    String? pass = await prefs!.getString("authpass");
    if(user!=null&&pass!=null){
      s.lastinfo['user'] = user;
      s.lastinfo['pass'] = pass;
      print("login info found");
      notifyListeners();
    }
  }
  void tryFetchGlucometerInfo(MyAppState s) async{
    if(prefs==null)return;
    List<String>? gms = await prefs!.getStringList("bleglucometers");
    if(gms!=null){
      //
      notifyListeners();
    }
  }
  Future<void> clearLoginInfo() async{
    if(prefs==null)return;
    await prefs?.clear();
    print("cleared log in info");
  }
}