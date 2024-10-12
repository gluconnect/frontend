import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MyApp());
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
class Glucometer{
  static var count = 1;
  Glucometer({this.name = "Glucometer"});
  String name = "HELLOWORLD";
}
class LogInResponse{
  //
}
class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];
  var userIsAuthed = false;
  var glucometers = <Glucometer>[];
  var lastinfo = {"user": "", "pass": ""};
  var URL = "http://TR405-STDNT06:8080";
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
  void addGlucometers(){
    glucometers.add(Glucometer());
  }
  Future<int> logIn(username, password) async{
    print("User: "+username+" Password: "+password);
    Future<int> logIn(String u, String p) async {
      final response = await http.post(
        Uri.parse(URL+'/verify'),
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
    print("User: "+username+" Password: "+password);
    Future<int> logIn(String u, String p) async {
      final response = await http.post(
        Uri.parse(URL+'/register'),
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
}
class MyHomePage extends StatefulWidget {
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
          page = Placeholder();//HomePage(); XXXX
        }
        break;
      case 1:
        page = ConnectPage();//ConnectPage();//connect, remove, and manage glucose monitors
        break;
      case 2:
        page = Settings(callback: logOut);//SettingsPage();//accoutn settings and stuff XXXX
        break;
      case 3:
        page = SelectPatientsPage();//SelectPatientsPage();//select and manage patients
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
                  items: [
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
            Text('A random Awesome idea:'),
            BigCard(thing: thing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavorite();
                  },
                  icon: Icon(icon),
                  label: Text('Like'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                  },
                  child: Text('Next'),
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

  final WordPair thing;

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
        child: Text(thing.asLowerCase, style: style, semanticsLabel: "${thing.first} ${thing.second}"),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var list = appState.favorites;
    if (list.isEmpty) {
      return Center(
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
            leading: Icon(Icons.favorite),
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
      var rep = await s.logIn(u, p).timeout(Duration(seconds: 5), onTimeout: (){return f;});
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
    final _formKey = GlobalKey<FormState>();
    TextEditingController userc = TextEditingController();
    TextEditingController passc = TextEditingController();
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth:400),
        child: Column(
          children: [
            Expanded(child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(islogin?'Log In':'Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),),
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
                        if (_formKey.currentState!.validate()) {
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

class Settings extends StatefulWidget{
  final Function? callback;
  const Settings({super.key, this.callback});
  @override
  State<Settings> createState() => _SettingsState(callback: callback);
}

class _SettingsState extends State<Settings> {
  Function? callback;
  _SettingsState({this.callback});
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    return ElevatedButton(onPressed: (){appState.logOut();if(callback!=null){callback!();}}, child: Text("Log Out"));
  }
}

class ConnectPage extends StatefulWidget{
  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  var glucometers = 0;
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    //appState.addGlucometers();
    var list = appState.glucometers;
    if (list.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text('No connected glucose monitors yet'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: (){
                appState.addGlucometers();
                print(appState.glucometers);
                setState((){});
              }, child: Icon(Icons.add)),
            )
          ],
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.glucometers.length} connected glucose monitors:'),
        ),
        for (Glucometer glucometer in appState.glucometers)
          ListTile(
            leading: Icon(Icons.wifi),
            title: Text(glucometer.name),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(onPressed: (){
            appState.addGlucometers();
            setState((){});
          }, child: Icon(Icons.add)),
        )
        /*for(WordPair wp in list)
          BigCard(thing: wp),*/
      ]
    );
  }
}

class SelectPatientsPage extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    return ElevatedButton(onPressed: (){appState.logOut();}, child: Text("Log Out"));
  }
}