import 'dart:io';
import 'package:universal_ble/universal_ble.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'GLUCOTESTF',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: MyHomePage(),
      ),
    );
  }
}
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
  var current = WordPair.random();
  var favorites = <WordPair>[];
  var userIsAuthed = false;
  List glucometers = <Glucometer>[];
  List caretakers = <Caretaker>[];
  List patients = <Patient>[];
  List readings = <GlucoReading>[];
  var lastinfo = {"user": "", "pass": "", "name": ""};
  var URL = "http://localhost:8008";
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
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
      caretakers.add(Caretaker(id: email, name: current.toString()));
      getNext();//remove later
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
      getNext();//remove later
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
      getNext();//remove later
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
      patients = res.map((v)=>Patient(id: v['email'], name: v['email'])).toList();
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
      caretakers = res.map((v)=>Caretaker(id: v['email'], name: v['email'])).toList();
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
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  void logOut(){
    setState((){selectedIndex = 0;});
  }
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    Widget page;
    switch (selectedIndex) {
      case 0:
        if(!appState.userIsAuthed){
          page = LogInPage(callback: setState);
        }else{
          page = HomePage();//show gluco readings and trends
        }
        break;
      case 1:
        page = ConnectPage();//connect, remove, and manage glucose monitors
        break;
      case 2:
        page = Settings(callback: logOut);//accoutn settings and stuff
        break;
      case 3:
        page = SelectPatientsPage();//select and manage patients
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
              if(appState.userIsAuthed)SafeArea(
                child: BottomNavigationBar(
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.link),
                      label: 'Connect',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'My Patients',
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    setState((){
                      selectedIndex = value;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var thing  = appState.current;
    IconData icon;
    if (appState.favorites.contains(thing)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('A random Awesome idea:'),
            BigCard(thing: thing.asLowerCase),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavorite();
                  },
                  icon: Icon(icon),
                  label: const Text('Like'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.thing,
  });

  final String thing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(thing, style: style, semanticsLabel: thing),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget{
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var list = appState.favorites;
    if (list.isEmpty) {
      return const Center(
        child: Text('No favorites yet.'),
      );
    }
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: const Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
        /*for(WordPair wp in list)
          BigCard(thing: wp),*/
      ]
    );
  }
}

class LogInPage extends StatefulWidget{
  final Function? callback;
  const LogInPage({super.key, this.callback});
  @override
  State<LogInPage> createState() => _LogInPageState(callback: callback);
}

class _LogInPageState extends State<LogInPage> {
  var islogin = true;
  Function? callback;
  String message = "";
  _LogInPageState({this.callback});
  Future<void> doTheThing(MyAppState s, String u, String p) async{
    //
    if(islogin){
      FutureOr<int> f = 0;
      var rep = await s.logIn(u, p).timeout(const Duration(seconds: 5), onTimeout: (){return f;});
      if(rep==200){
        setState((){
          if(callback!=null){
            callback!((){
              //
            });
          }
          print("SD");
        });
      }else if(rep==401){
        setState((){
          message = "Email or password is incorrect";
          islogin = true;
        });
      }else{
        setState((){message = "Something went wrong, please try again later";});
      }
    }
    else{
      var rep = await s.register(u, p);
      if(rep==200){
        setState((){
          message = "Your account has been successfully created";
          islogin = true;
        });
      }else if(rep==401){
        setState((){
          message = "An account associated with this email already exists";
          islogin = false;
        });
      }else{
        setState((){message = "Something went wrong, please try again later";});
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final formKey = GlobalKey<FormState>();
    TextEditingController userc = TextEditingController();
    TextEditingController passc = TextEditingController();
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth:400),
        child: Column(
          children: [
            Expanded(child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(islogin?'Log In':'Register', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
                  if(message!="")
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(message),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: userc,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your email',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      obscureText: true,
                      controller: passc,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your password',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                  if(!islogin)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your password again',
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }else if(value!=passc.text){
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate will return true if the form is valid, or false if
                        // the form is invalid.
                        if (formKey.currentState!.validate()) {
                          //_formKey.currentState.save();
                          doTheThing(appState, userc.text, passc.text);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ]
              ),
            ),),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(!islogin?"Already a user? ":"No account yet? "),
                        ElevatedButton(onPressed: (){
                          setState((){islogin = !islogin;});
                        },
                        child: Text(!islogin?"Log In":"Register"))
                      ]
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget{
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isconnecting = false;//adding readings manually?
  bool needsupdate = true;//fetch readings first TODO(run every 10 seconds or so)
  String errormsg = "";
  Future<void> fetchLists(MyAppState s)async{
    //var clist = await s.getCaretakers();
    print("starting request");
    var plist = await s.getCaretakers();
    print("request complete");
    if(plist!=null){
      setState((){
        needsupdate = false;
      });
    }else{
      setState((){
        errormsg = "Something went wrong, please try again later...Retrying";
      });
    }
  }
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    //appState.addGlucometers();
    var list = appState.glucometers;
    if(isconnecting){
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
          child: Column(
            children: [
              Row(
                children: [
                  Spacer(),
                  ElevatedButton(onPressed: (){setState((){isconnecting = false;});}, child: Icon(Icons.cancel)),
                ],
              ),
              Text('Connect Glucose Monitor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
              Container(
                constraints: const BoxConstraints(maxWidth:400),
                child: Expanded(child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(errormsg!="")
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(errormsg),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: userc,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Name',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (formKey.currentState!.validate()) {
                              //_formKey.currentState.save();
                              //appState.addReading(timestamp: ?, );
                              //TODO
                              setState((){isconnecting = false;});
                            }
                          },
                          child: const Text('Connect Glucometer'),
                        ),
                      ),
                    ]
                  ),
                ),),
              ),
            ],
          ),
        //),
      );
      //return ElevatedButton(child: Text("Connect Glucometer"), onPressed: (){});
    }else if (needsupdate){
      fetchLists(appState);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Loading..."),
        ],
      );
    }else if(errormsg!=""){
      return Text(errormsg);
    }else if (list.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text("Home", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
            const Text('No readings available yet'),
            if(appState.glucometers.isEmpty)
              Text("You have no connected glucose monitors...Go to the connect tab to connect one"),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: (){
                setState((){isconnecting = true;});
              }, child: const Icon(Icons.add)),//TODO remove later
            )
          ],
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Text("Connect Glucose Monitors", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.glucometers.length} connected glucose monitors:'),
        ),
        for (Glucometer glucometer in appState.glucometers)
          ListTile(
            leading: const Icon(Icons.wifi),
            title: Row(
              children: [
                Text(glucometer.name),
                Spacer(),
                ElevatedButton(child: Icon(Icons.settings), onPressed: (){
                  appState.deleteGlucometer(glucometer.id);
                  setState((){});
                })
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(onPressed: (){
            setState((){isconnecting = true;});
          }, child: const Icon(Icons.add)),
        )
        /*for(WordPair wp in list)
          BigCard(thing: wp),*/
      ]
    );
  }
}

class Settings extends StatefulWidget{
  final Function? callback;
  const Settings({super.key, this.callback});
  @override
  State<Settings> createState() => _SettingsState(callback: callback);
}

class _SettingsState extends State<Settings> {
  Function? callback;
  _SettingsState({this.callback});
  int microsettings = 0;//0 - nothing, 1 - delete account, 2 - change name, 3 - change pass
  String errormsg = "";
  //request to change the name of the user to string t, if not, show error msg
  Future<void> changeName(MyAppState mas, String t) async{
    print("changing name "+t);
    String? n = await mas.changeName(t);
    if(n!=null)setState((){microsettings = 0;errormsg = "Name change successful";});
    else setState((){errormsg = "Something went wrong";});
  }
  Future<void> changePass(MyAppState mas, String t) async{
    print("changing pass "+t);
    String? n = await mas.changePass(t);
    if(n!=null)setState((){microsettings = 0;errormsg = "Password change successful";});
    else setState((){errormsg = "Something went wrong";});
  }
  Future<void> deleteAccount(MyAppState mas) async{
    int n = await mas.deleteAccount();
    if(n==200)if(callback!=null){callback!();}
    else setState((){microsettings = 0;});
  }
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    if(microsettings==0){
      return SizedBox.expand(
        child: Column(
          children: [
            Text("Settings", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
            if(errormsg!="")
              Text(errormsg),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text("Current Name: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                  Text(appState.lastinfo["name"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                  ElevatedButton(onPressed: (){setState((){microsettings = 2;});}, child: const Text("Change Name")),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: (){setState((){microsettings = 3;});}, child: const Text("Change Password")),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: (){appState.logOut();if(callback!=null){callback!();}}, child: const Text("Log Out")),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: (){setState((){microsettings = 1;});}, child: const Text("Delete Account")),
            ),
          ],
        ),
      );
    }else if(microsettings==1){
      return SizedBox.expand(
        child: Column(
          children: [
            Row(
              children: [
                Spacer(),
                ElevatedButton(onPressed: (){setState((){microsettings = 0;});}, child: Icon(Icons.cancel)),
              ],
            ),
            Text("Delete Account?", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
            ElevatedButton(onPressed: (){deleteAccount(appState);}, child: const Text("DELETE ACCOUNT")),
          ],
        ),
      );
    }else if(microsettings==2){
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
          child: Column(
            children: [
              Row(
                children: [
                  Spacer(),
                  ElevatedButton(onPressed: (){setState((){microsettings = 0;});}, child: Icon(Icons.cancel)),
                ],
              ),
              Text('Change Account Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
              Container(
                constraints: const BoxConstraints(maxWidth:400),
                child: Expanded(child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(errormsg!="")
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(errormsg),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: userc,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'New Name',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (formKey.currentState!.validate()) {
                              //_formKey.currentState.save();
                              changeName(appState, userc.text);
                            }
                          },
                          child: const Text('Change Name'),
                        ),
                      ),
                    ]
                  ),
                ),),
              ),
            ],
          ),
        //),
      );
    }else if(microsettings==3){
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
          child: Column(
            children: [
              Row(
                children: [
                  Spacer(),
                  ElevatedButton(onPressed: (){setState((){microsettings = 0;});}, child: Icon(Icons.cancel)),
                ],
              ),
              Text('Change Account Password', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
              Container(
                constraints: const BoxConstraints(maxWidth:400),
                child: Expanded(child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(errormsg!="")
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(errormsg),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: userc,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'New Password',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (formKey.currentState!.validate()) {
                              //_formKey.currentState.save();
                              changePass(appState, userc.text);
                            }
                          },
                          child: const Text('Change Password'),
                        ),
                      ),
                    ]
                  ),
                ),),
              ),
            ],
          ),
        //),
      );
    }else{
      return Placeholder();
    }
  }
}

class ConnectPage extends StatefulWidget{
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  var glucometers = 0;
  bool isconnecting = false;
  String errormsg = "";
  Map<String, BleDevice?> glucometer = {"dev": null};
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    //appState.addGlucometers();
    var list = appState.glucometers;
    if(isconnecting){
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
          child: Column(
            children: [
              Row(
                children: [
                  Spacer(),
                  ElevatedButton(onPressed: (){setState((){isconnecting = false;});}, child: Icon(Icons.cancel)),
                ],
              ),
              Text('Connect Glucose Monitor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
              Container(
                constraints: const BoxConstraints(maxWidth:400),
                child: Expanded(child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(errormsg!="")
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(errormsg),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: userc,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Name',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        height: 400,
                        child: ConnectGlucometer(glucometer: glucometer)
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (formKey.currentState!.validate()) {
                              //_formKey.currentState.save();
                              if(glucometer['dev']==null){
                                setState((){errormsg = "Please connect a glucometer";});
                                return;
                              }
                              appState.addGlucometer(name: userc.text, dev: glucometer['dev']);
                              //TODO
                              //connectGlucometer();
                              setState((){isconnecting = false;});
                            }
                          },
                          child: const Text('Connect Glucometer'),
                        ),
                      ),
                    ]
                  ),
                ),),
              ),
            ],
          ),
        //),
      );
      //return ElevatedButton(child: Text("Connect Glucometer"), onPressed: (){});
    }else if (list.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text("Connect Glucose Monitors", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
            const Text('No connected glucose monitors yet'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: (){
                setState((){isconnecting = true;});
              }, child: const Icon(Icons.add)),
            )
          ],
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Text("Connect Glucose Monitors", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.glucometers.length} connected glucose monitors:'),
        ),
        for (Glucometer glucometer in appState.glucometers)
          ListTile(
            leading: const Icon(Icons.wifi),
            title: Row(
              children: [
                Text(glucometer.name),
                Spacer(),
                ElevatedButton(child: Icon(Icons.settings), onPressed: (){
                  appState.deleteGlucometer(glucometer.id);
                  setState((){});
                })
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(onPressed: (){
            setState((){isconnecting = true;});
          }, child: const Icon(Icons.add)),
        )
        /*for(WordPair wp in list)
          BigCard(thing: wp),*/
      ]
    );
  }
}
class SelectPatientsPage extends StatefulWidget{
  final Function? callback;
  const SelectPatientsPage({super.key, this.callback});
  @override
  State<SelectPatientsPage> createState() => _SelectPatientsPageState(callback: callback);
}

class _SelectPatientsPageState extends State<SelectPatientsPage> {
  var glucometers = 0;
  bool needsupdate = true;//whether to run fetchlists when building
  bool isconnecting = false;
  String errormsg = "";
  Function? callback;
  _SelectPatientsPageState({this.callback});
  void nuPage(int mode){
    if(mode==0){
      setState((){
        isconnecting = true;
      });
    }
  }
  Future<void> addUser(MyAppState s, String email) async{
    var rp = await s.addCaretaker(email);
    if(rp==200){
      setState((){
        isconnecting = false;
      });
    }else{
      setState((){
        errormsg = "Something went wrong, please try again";
      });
    }
  }
  @override
  Widget build(BuildContext context){
    //appState.addGlucometers();
    var appState = context.watch<MyAppState>();
    if(isconnecting){
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
          child: Column(
            children: [
              Row(
                children: [
                  Spacer(),
                  ElevatedButton(onPressed: (){setState((){isconnecting = false;});}, child: Icon(Icons.cancel)),
                ],
              ),
              Container(
                constraints: const BoxConstraints(maxWidth:400),
                child: Expanded(child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Authorize User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
                      if(errormsg!="")
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(errormsg),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: userc,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter other email',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (formKey.currentState!.validate()) {
                              //_formKey.currentState.save();
                              addUser(appState, userc.text);
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                    ]
                  ),
                ),),
              ),
            ],
          ),
        //),
      );
    }else{
    if(false&&appState.caretakers.isEmpty){
      return SizedBox.expand(
        child: Column(
          children: [
            Expanded(child: PatientList(callback: nuPage)),
            Expanded(child: CaretakerList(callback: nuPage))
          ],
        ),
      );
    }else{
      return SizedBox.expand(
        child:
          Column(
            children: [
              Expanded(child: CaretakerList(callback: nuPage)),
              Expanded(child: PatientList(callback: nuPage))
            ],
          ),
      );
    }
    }
  }
}

class PatientList extends StatefulWidget{
  Function? callback;
  PatientList({super.key, this.callback});
  @override
  State<PatientList> createState() => _PatientListState(callback: callback);
}

class _PatientListState extends State<PatientList> {
  Function? callback;
  bool needsupdate = true;
  String errormsg = "";
  _PatientListState({this.callback});
  Future<void> fetchLists(MyAppState s)async{
    //var clist = await s.getCaretakers();
    print("starting request");
    var plist = await s.getPatients();
    print("request complete");
    if(plist!=null){
      setState((){
        needsupdate = false;
      });
    }else{
      setState((){
        errormsg = "Something went wrong, please try again later...Retrying";
      });
    }
  }
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    //appState.addGlucometers();
    var list = appState.patients;
    if(needsupdate){
      fetchLists(appState);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Loading..."),
        ],
      );
    }else if(errormsg!=""){
      return Text(errormsg);
    }else if (list.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('No connected patients yet'),
          ],
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Patients", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You can view '
              '${appState.patients.length} patients:'),
        ),]),
        for (Patient glucometer in appState.patients)
          ListTile(
            leading: const Icon(Icons.person),
            title: Row(
              children: [
                Text(glucometer.name),
                Spacer(),
                ElevatedButton(child: Icon(Icons.search), onPressed: (){
                  //TODO: VIEW PATIENT
                  setState((){});
                }),
                ElevatedButton(child: Icon(Icons.settings), onPressed: (){
                  appState.deletePatient(glucometer.id, ({String msg = ""}){setState((){errormsg = msg;});});
                  setState((){});
                })
              ],
            ),
          ),
        /*for(WordPair wp in list)
          BigCard(thing: wp),*/
      ]
    );
  }
}

class CaretakerList extends StatefulWidget{
  final Function? callback;
  const CaretakerList({super.key, this.callback});
  @override
  State<CaretakerList> createState() => _CaretakerListState(callback: callback);
}

class _CaretakerListState extends State<CaretakerList> {
  Function? callback;
  bool needsupdate = true;
  String errormsg = "";
  _CaretakerListState({this.callback});
  Future<void> fetchLists(MyAppState s)async{
    //var clist = await s.getCaretakers();
    print("starting request");
    var plist = await s.getCaretakers();
    print("request complete");
    if(plist!=null){
      setState((){
        needsupdate = false;
      });
    }else{
      setState((){
        errormsg = "Something went wrong, please try again later...Retrying";
      });
    }
  }
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    //appState.addGlucometers();
    var list = appState.caretakers;
    if(needsupdate){
      fetchLists(appState);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Loading..."),
        ],
      );
    }else if(errormsg!=""){
      return Text(errormsg);
    }else if (list.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('No authorized users yet'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: (){
                callback!(0);
              }, child: const Icon(Icons.add)),
            )
          ],
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Authorized Users", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.caretakers.length} authorized users:'),
        ),]),
        for (Caretaker glucometer in appState.caretakers)
          ListTile(
            leading: const Icon(Icons.person),
            title: Row(
              children: [
                Text(glucometer.name),
                Spacer(),
                ElevatedButton(child: Icon(Icons.settings), onPressed: (){
                  appState.deleteCaretaker(glucometer.id, ({String msg = ""}){setState((){errormsg = msg;});});
                  setState((){});
                })
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(onPressed: (){
            callback!(0);
          }, child: const Icon(Icons.add)),
        )
        /*for(WordPair wp in list)
          BigCard(thing: wp),*/
      ]
    );
  }
}
class ConnectGlucometer extends StatefulWidget{
  Map<String, BleDevice?>? glucometer;
  ConnectGlucometer({super.key, this.glucometer});

  @override
  State<ConnectGlucometer> createState() => _ConnectGlucometerState(glucometer: glucometer);
}

class _ConnectGlucometerState extends State<ConnectGlucometer> {
  final bleDevices = <BleDevice>[];
  bool isscanning = false;
  AvailabilityState? avSt;
  String errormsg = "";
  Map<String, BleDevice?>? glucometer;
  _ConnectGlucometerState({this.glucometer});
  void err(String msg){
    errormsg = msg;
    print("BLE: "+msg);
  }
  @override
  void initState(){
    super.initState();
    UniversalBle.onAvailabilityChange = (state){
      setState(() {
        avSt = state;
      });
    };
    UniversalBle.onScanResult = (res){
      int i = bleDevices.indexWhere((e)=>e.deviceId==res.deviceId);
      if(i==-1){
        bleDevices.add(res);//add to list of options if not already there
      }else{
        if(res.name==null&&bleDevices[i].name!=null){
          res.name = bleDevices[i].name;//update new info for existing devices
        }
        bleDevices[i] = res;
      }
      setState(() {
        glucometer!["dev"] = res;
      });
    };
  }
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    return Column(
      children: [
        Text(errormsg),
        Row(
          children: [
            ElevatedButton(child: isscanning?Text("Stop Search"):Text("Search for Glucometers"), onPressed: () async{
              if(!isscanning){
                setState(() {
                  bleDevices.clear();
                  isscanning = true;
                });
                try{
                  await UniversalBle.startScan(
                    scanFilter: ScanFilter(
                      withServices: ["0x1808"]
                    )
                  );
                }catch(e){
                  setState(() {
                    isscanning = false;
                    err("Something went wrong");
                  });
                }
              }else{
                await UniversalBle.stopScan();
                setState(() {
                  isscanning = false;
                });
              }
            },),
            if(BleCapabilities.supportsBluetoothEnableApi&&avSt==AvailabilityState.poweredOff)
              ElevatedButton(onPressed: () async{
                bool v = await UniversalBle.enableBluetooth();
                err("Enabled? $v");
              }, child: Text("Enable Bluetooth")),
            if(BleCapabilities.requiresRuntimePermission)
              ElevatedButton(onPressed: () async{
                if(await PermissionHandler.arePermissionsGranted()){
                  err("Permissions Granted");
                }
              }, child: Text("Check Permissions")),
            if(BleCapabilities.supportsConnectedDevicesApi)
              ElevatedButton(onPressed: () async{
                List<BleDevice> devs = await UniversalBle.getSystemDevices();
                if(devs.isEmpty){
                  err("No Connected Devices Found");
                }
                setState(() {
                  bleDevices.clear();
                  bleDevices.addAll(devs);
                });
              }, child: Text("List Connected Devices")),
            if(bleDevices.isNotEmpty)
              ElevatedButton(onPressed: (){
                setState(() {
                  bleDevices.clear();
                });
              }, child: Text("Clear List"))
          ]
        ),
        Text("BLE Availability: ${avSt?.name}"),
        Divider(color: Colors.green.shade900),
        Container(child: isscanning&&bleDevices.isEmpty
          ? Center(child: CircularProgressIndicator.adaptive())
          : !isscanning&&bleDevices.isEmpty
            ? Placeholder()
            : ListView.separated(itemBuilder: (context, index){
                BleDevice dev = bleDevices[bleDevices.length-index-1];
                return Text(dev.deviceId);
              }, separatorBuilder: (context, index)=>Divider(), itemCount: bleDevices.length)
        )
      ],
    );
  }
}
class Midget extends StatefulWidget{
  @override
  State<Midget> createState() => _MidgetState();
}

class _MidgetState extends State<Midget> {
  Timer? timer;
  Function? callback;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 15), (timer){callback!();});
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context){
    return SizedBox.shrink();
  }
}
class PermissionHandler {
  static Future<bool> arePermissionsGranted() async {
    if (!isMobilePlatform) return true;

    var status = await _permissionStatus;
    bool blePermissionGranted = status[0];
    bool locationPermissionGranted = status[1];

    if (locationPermissionGranted && blePermissionGranted) return true;

    if (!blePermissionGranted) {
      PermissionStatus blePermissionCheck =
          await Permission.bluetooth.request();
      if (blePermissionCheck.isPermanentlyDenied) {
        print("Bluetooth Permission Permanently Denied");
        openAppSettings();
      }
      return false;
    }

    if (!locationPermissionGranted) {
      PermissionStatus locationPermissionCheck =
          await Permission.location.request();
      if (locationPermissionCheck.isPermanentlyDenied) {
        print("Location Permission Permanently Denied");
        openAppSettings();
      }
      return false;
    }

    return false;
  }

  static Future<List<bool>> get _permissionStatus async {
    bool blePermissionGranted = false;
    bool locationPermissionGranted = false;

    if (await requiresExplicitAndroidBluetoothPermissions) {
      bool bleConnectPermission =
          (await Permission.bluetoothConnect.request()).isGranted;
      bool bleScanPermission =
          (await Permission.bluetoothScan.request()).isGranted;

      blePermissionGranted = bleConnectPermission && bleScanPermission;
      locationPermissionGranted = true;
    } else {
      PermissionStatus permissionStatus = await Permission.bluetooth.request();
      blePermissionGranted = permissionStatus.isGranted;
      locationPermissionGranted = await requiresLocationPermission
          ? (await Permission.locationWhenInUse.request()).isGranted
          : true;
    }
    return [locationPermissionGranted, blePermissionGranted];
  }

  static bool get isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<bool> get requiresLocationPermission async =>
      !kIsWeb &&
      Platform.isAndroid &&
      (!await requiresExplicitAndroidBluetoothPermissions);

  static Future<bool> get requiresExplicitAndroidBluetoothPermissions async {
    if (kIsWeb || !Platform.isAndroid) return false;
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 31;
  }
}
Future<void> connectGlucometer() async{
  void decode(Uint8List s){
    //
  }
  //connect to glucometer when available, and obtain service to get readings
  UniversalBle.onScanResult = (BleDevice bleDevice) async {
    var deviceId = bleDevice.deviceId;
    print("Device found "+deviceId);
    await UniversalBle.connect(deviceId);
    print("Device connected");
    List<BleService> b = await UniversalBle.discoverServices(deviceId);
    print("Services obtained");
    BleService s = b.firstWhere((t)=>t.uuid=='0x1808');
    print("Service id "+s.uuid);
    Uint8List us = await UniversalBle.readValue(deviceId, s.uuid, '0000-00001-'+deviceId);
    decode(us);
  };
  AvailabilityState state = await UniversalBle.getBluetoothAvailabilityState();
  // Start scan only if Bluetooth is powered on, make sure it is, if not, request perms
  print(state);
  if (state == AvailabilityState.poweredOn) {
    print("Starting scan");
    UniversalBle.startScan(
      /*scanFilter: ScanFilter(
        withServices: ["0x1808"]
      )*/
    );
  }
}