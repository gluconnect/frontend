import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'brains.dart';
import 'pages.dart';
import 'redbone.dart';

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
        page = ConnectPage();//Expanded(child:ConnectGlucometer(glucometer:{"dev":null}));//connect, remove, and manage glucose monitors
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
                    if(!appState.ishttpying)
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