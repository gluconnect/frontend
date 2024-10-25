import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'brains.dart';
import 'pages.dart';
import 'redbone.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences test = await SharedPreferences.getInstance();
  print(test);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers:[
        ChangeNotifierProvider(create: (_)=>MyAppState()),
        ChangeNotifierProvider(create: (_)=>LocalStorageState())
      ],
      child: MaterialApp(
        title: 'GLUCONNECT',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        ),
        home: MyFatHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  String m = "Aloha";
  void logOut() {
    setState(() {
      selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    MyAppState appState = Provider.of<MyAppState>(context, listen: true);
    Widget page;
    switch (selectedIndex) {
      case 0:
        if (!appState.userIsAuthed) {
          page = LogInPage(callback: setState);
        } else {
          page = HomePage(); //show gluco readings and trends
        }
        break;
      case 1:
        page =
            const ConnectPage(); //Expanded(child:ConnectGlucometer(glucometer:{"dev":null}));//connect, remove, and manage glucose monitors
        break;
      case 2:
        page = Settings(callback: logOut); //accoutn settings and stuff
        break;
      case 3:
        page = const SelectPatientsPage(); //select and manage patients
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
            if (appState.userIsAuthed)
              SafeArea(
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
                    if (!appState.ishttpying) {
                      setState(() {
                        selectedIndex = value;
                      });
                    }
                  },
                  type: BottomNavigationBarType.fixed,
                ),
              )
          ],
        ),
      );
    });
  }
}

class MyFatHomePage extends StatefulWidget {
  const MyFatHomePage({super.key});

  @override
  State<MyFatHomePage> createState() => _MyFatHomePageState();
}

class _MyFatHomePageState extends State<MyFatHomePage> {
  Map<String, Function?> s = {};
  @override
  Widget build(BuildContext ctx) {
    s = {'cb': null};
    //ONLY BUILD ONCE
    MyAppState appState = Provider.of<MyAppState>(ctx, listen: false);
    return Column(children: [
      const Expanded(child: MyHomePage()),
      Midget(
        message: "Refresh",
        callback: () async {
          return await appState.getReadingsFromServerToLocal();
      }),
      Midget(
          message: "Get Readings",
          callback: () async {
            return await appState.updateGlucometers(s["cb"]);
      })
    ]);
  }
}
