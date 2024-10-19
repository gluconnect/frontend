import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final TextEditingController thresholdController = TextEditingController();
final TextEditingController accountController = TextEditingController();
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
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 36, 255, 134)),
        ),
        home: LoginScreen(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Username:', textScaler: TextScaler.linear(1.4)),
            const SizedBox(height: 10),
            const SizedBox(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Username",
                )
              ),
            ),
            const SizedBox(height: 20),
            const Text("Password:", textScaler: TextScaler.linear(1.4)),
            const SizedBox(height: 10),
            const SizedBox(
              width: 250,
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                )
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              child: ElevatedButton(
                child: const Text("Submit"),
                onPressed: () {
                  _navigateToNextScreen(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _navigateToNextScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HomePage()));
  }
}

class HomePage extends StatefulWidget {
 const HomePage({super.key});

 @override
 State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int threshold = 1;
  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 235, 255, 55)),
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.auto_graph_outlined)),
                Tab(icon: Icon(Icons.connect_without_contact_rounded)),
                Tab(icon: Icon(Icons.settings)),
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: TabBarView(
            children: [
              const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("hello")
                    ],
                  ),
                ),
              ),


              const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("world")
                    ],
                  ),
                ),
              ),


              Scaffold(
                body: Center(
                  child: Scrollbar(
                    child: Column(
                      children: [
                        const Spacer(),
                        const Text("Unique User ID: 00000"),
                        const Spacer(),
                        Text("Current Alert Threshold: $threshold"),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: thresholdController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Enter New Threshold",
                            ),
                          ),
                        ),
                        ElevatedButton(
                          child: const Text("Change Threshold"),
                          onPressed: () {
                            try{
                              setState(() {
                                threshold = int.parse(thresholdController.text);
                              });
                            }
                            on FormatException
                            {
                                const AlertDialog(content: Text("Please Enter a number"));
                            }
                          },
                        ),
                        const Spacer(),
                          const Text("Change Account Name: "),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: accountController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Enter New Account Name",
                            ),
                          ),
                        ),
                        ElevatedButton(
                          child: const Text("Enter"),
                          onPressed: () {

                          }
                        ),
                        const Spacer(),
                        const Text("Change Password:"),
                        const SizedBox(
                          width: 200,
                          child: TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Enter New Password",
                            ),
                          ),
                        ),
                        ElevatedButton(
                          child: const Text("Enter"),
                          onPressed: () {

                          }
                        ),
                        const Spacer(),
                        SizedBox(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 255, 56, 41),
                            ),
                            child: const Text(
                              "Log Out",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            }
                          ),
                        ),
                      const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}