import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_ble/universal_ble.dart';
import 'package:flutter/material.dart';
class Caretaker{
  static var count = 1;
  Caretaker({this.id = "", this.name = "Glucometer"});
  String name = "HELLOWORLD";
  String id;
}
class Patient{
  static var count = 1;
  Patient({this.id = "", this.name = "Glucometer"});
  String name = "HELLOWORLD";
  String id;//email
}
class Glucometer{
  static var count = 1;
  Glucometer({this.id = 0, this.name = "Glucometer", this.meter});
  String name = "HELLOWORLD";
  int id;
  BleDevice? meter;
}
class GlucoReading{
  DateTime timestamp = DateTime(0);
  double value = 0;
  String  meal = "Before Meal";
  String comment = "";
  String  measure_method = "blood sample";
  Map<String, dynamic>? extra_data;
  GlucoReading(dynamic thing){
    timestamp = thing['timestamp'];
    value = thing['value'];
    meal = thing['meal'];
    if(true){
      comment = thing['comment'];
    }
    measure_method = thing['measure_method'];
    extra_data = null;//thing['extra_data'];
  }
}
class LogInResponse{
  //
}
class MyAppState extends ChangeNotifier {
  var userIsAuthed = false;
  List glucometers = <Glucometer>[];
  List caretakers = <Caretaker>[];
  List patients = <Patient>[];
  List readings = <GlucoReading>[];
  var lastinfo = {"user": "", "pass": "", "name": ""};
  var URL = "http://localhost:8008";
  void addGlucometer({String name = "", BleDevice? dev}){
    glucometers.add(Glucometer(id: Glucometer.count, name: name, meter: dev));
    Glucometer.count++;
  }
  //request the server to authorize another user as a caretaker. If successful, return the correct code so that the user can be added to the list
  Future<int> addCaretaker(email) async{
    Future<int> addCT(String u, String p, String ou) async {
      final response = await http.post(
        Uri.parse('$URL/connect_user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
          'uemail': ou
        }),
      );
      if (response.statusCode == 200) {
        //If the server return 200, add caretaker
        return response.statusCode;// as Map<String, String>;
      } else if (response.statusCode == 401){
        //fail and tell user
        return response.statusCode;
      }else{
        return 0;
      }
    }
    int rp = await addCT(lastinfo["user"]!, lastinfo["pass"]!, email);
    if(rp==200){
      caretakers.add(Caretaker(id: email, name: email/*TODO*/));
      //callback();
    }else{
      //callback("User does not exist");
    }
    return rp;
  }
  void deleteGlucometer(id){
    glucometers.removeWhere((i)=>i.id==id);
  }
  Future<int> deleteCaretaker(id, Function callback) async{
    Future<int> remCT(String u, String p, String ou) async {
      final response = await http.post(
        Uri.parse('$URL/disconnect_user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
          'uemail': ou
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response.statusCode;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response.statusCode;//throw Exception('Failed to load album');
      }else{
        return 0;
      }
    }
    int rp = await remCT(lastinfo["user"]!, lastinfo["pass"]!, id);
    if(rp==200){
      caretakers.removeWhere((i)=>i.id==id);
      callback();
    }else{
      callback("Something went wrong");
    }
    return rp;
  }
  Future<int> deletePatient(id, Function callback) async{
    Future<int> remPT(String u, String p, String ou) async {
      final response = await http.post(
        Uri.parse('$URL/disconnect_patient'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
          'uemail': ou
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response.statusCode;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response.statusCode;//throw Exception('Failed to load album');
      }else{
        return 0;
      }
    }
    int rp = await remPT(lastinfo["user"]!, lastinfo["pass"]!, id);
    if(rp==200){
      patients.removeWhere((i)=>i.id==id);
      callback();
    }else{
      callback("Something went wrong");
    }
    return rp;
  }
  Future<List?> getPatients() async{
    Future<http.Response> getPT(String u, String p) async {
      print(u+" "+p);
      final http.Response response = await http.post(
        Uri.parse('$URL/get_patients'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response;//throw Exception('Failed to load album');
      }else{
        return response;
      }
    }
    http.Response rp = await getPT(lastinfo["user"]!, lastinfo["pass"]!);
    if(rp.statusCode==200){
      List res = jsonDecode(rp.body);
      print(res);
      patients = res.map((v)=>Patient(id: v['email'], name: v['name'])).toList();
      return res;
    }else{
      return null;
    }
  }
  Future<List?> getCaretakers() async{
    Future<http.Response> getCT(String u, String p) async {
      final http.Response response = await http.post(
        Uri.parse('$URL/get_viewers'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response;//throw Exception('Failed to load album');
      }else{
        return response;
      }
    }
    http.Response rp = await getCT(lastinfo["user"]!, lastinfo["pass"]!);
    if(rp.statusCode==200){
      List res = jsonDecode(rp.body);
      print(res);
      caretakers = res.map((v)=>Caretaker(id: v['email'], name: v['name'])).toList();
      return res;
    }else{
      return null;
    }
  }
  Future<List?> getReadings() async{
    Future<http.Response> getRD(String u, String p) async {
      final http.Response response = await http.post(
        Uri.parse('$URL/get_readings'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response;//throw Exception('Failed to load album');
      }else{
        return response;
      }
    }
    http.Response rp = await getRD(lastinfo["user"]!, lastinfo["pass"]!);
    if(rp.statusCode==200){
      List<dynamic> res = jsonDecode(rp.body);
      readings = res.map((v)=>GlucoReading(v)).toList();
      return res;
    }else{
      return null;
    }
  }
  Future<String?> changeName(String nname) async{
    Future<http.Response> change(String u, String p, String nname) async {
      print(u+" "+p);
      final http.Response response = await http.post(
        Uri.parse('$URL/change_name'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
          'newname': nname
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response;//throw Exception('Failed to load album');
      }else{
        return response;
      }
    }
    http.Response rp = await change(lastinfo["user"]!, lastinfo["pass"]!, nname);
    if(rp.statusCode==200){
      lastinfo["name"] = rp.body;
      return rp.body;
    }else{
      return null;
    }
  }
  Future<String?> changePass(String npass) async{
    Future<http.Response> change(String u, String p, String npass) async {
      print(u+" "+p);
      final http.Response response = await http.post(
        Uri.parse('$URL/change_password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
          'newpassword': npass
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response;//throw Exception('Failed to load album');
      }else{
        return response;
      }
    }
    http.Response rp = await change(lastinfo["user"]!, lastinfo["pass"]!, npass);
    if(rp.statusCode==200){
      lastinfo["pass"] = npass;
      return rp.body;
    }else{
      return null;
    }
  }
  Future<int> logIn(username, password) async{
    print("${"User: "+username} Password: "+password);
    Future<int> logIn(String u, String p) async {
      final response = await http.post(
        Uri.parse('$URL/verify'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        userIsAuthed = true;
        lastinfo["name"] = response.body;
        return response.statusCode;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response.statusCode;//throw Exception('Failed to load album');
      }else{
        return 0;
      }
    }
    int rp = await logIn(username, password);
    print(rp);
    if(rp==200){
      lastinfo["user"] = username;
      lastinfo["pass"] = password;
    }
    return rp;
  }
  Future<int> register(username, password) async{
    print("${"User: "+username} Password: "+password);
    Future<int> logIn(String u, String p) async {
      final response = await http.post(
        Uri.parse('$URL/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response.statusCode;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response.statusCode;//throw Exception('Failed to load album');
      }else{
        return 0;
      }
    }
    int rp = await logIn(username, password);
    print(rp);
    return rp;
  }
  void logOut(){
    lastinfo["user"] = "";
    lastinfo["pass"] = "";
    userIsAuthed = false;
  }
  Future<int> deleteAccount() async{
    Future<http.Response> change(String u, String p) async {
      print(u+" "+p);
      final http.Response response = await http.post(
        Uri.parse('$URL/delete'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': u,
          'password': p,
        }),
      );
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        return response;// as Map<String, String>;
      } else if (response.statusCode == 401){
        // If the server did not return a 200 OK response,
        // then throw an exception.
        return response;//throw Exception('Failed to load album');
      }else{
        return response;
      }
    }
    http.Response rp = await change(lastinfo["user"]!, lastinfo["pass"]!);
    if(rp.statusCode==200){
      logOut();
      return rp.statusCode;
    }else{
      return rp.statusCode;
    }
  }
}