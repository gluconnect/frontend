import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glucotest/main.dart';
import 'package:provider/provider.dart';
import 'package:universal_ble/universal_ble.dart';
import 'redbone.dart';
import 'dart:async';
import 'brains.dart';

class LogInPage extends StatefulWidget {
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
  Future<void> doTheThing(
      MyAppState s, String u, String p, String n, String v) async {
    if (islogin) {
      FutureOr<int> f = 0;
      var rep = await s.logIn(u, p, v);
      if (rep == 200) {
        setState(() {
          if (callback != null) {
            callback!(() {
              //
            });
          }
          print("SD");
        });
      } else if (rep == 401) {
        setState(() {
          message = "Email or password is incorrect";
          islogin = true;
        });
      } else {
        setState(() {
          message = "Something went wrong, please try again later";
        });
      }
    } else {
      var rep = await s.register(u, p, n);
      if (rep == 200) {
        setState(() {
          message = "Your account has been successfully created";
          islogin = true;
        });
      } else if (rep == 401) {
        setState(() {
          message = "An account associated with this email already exists";
          islogin = false;
        });
      } else {
        setState(() {
          message = "Something went wrong, please try again later";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final formKey = GlobalKey<FormState>();
    TextEditingController userc = TextEditingController();
    TextEditingController passc = TextEditingController();
    TextEditingController nickc = TextEditingController();
    //TextEditingController nick2c = TextEditingController();
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        islogin ? 'Log In' : 'Register',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 50),
                      ),
                      if (message != "")
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
                      if (!islogin)
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
                              } else if (value != passc.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                        ),
                      if (!islogin)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: nickc,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter your name',
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          ),
                        ),
                      /*Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: nick2c,
                      initialValue: appState.URL,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter server url',
                      ),
                      validator: (String? value) {
                        return null;
                      },
                    ),
                  ),*/
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (formKey.currentState!.validate()) {
                              //_formKey.currentState.save();
                              doTheThing(appState, userc.text, passc.text,
                                  nickc.text, appState.URL /*nick2c.text*/);
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                    ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(!islogin ? "Already a user? " : "No account yet? "),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        islogin = !islogin;
                      });
                    },
                    child: Text(!islogin ? "Log In" : "Register"))
              ]),
            )
          ],
        ),
      ),
    );
  }
}

bool isNumeric(String s) {
  return double.tryParse(s) != null;
}

class HomePage extends StatefulWidget {
  String oemail;
  Map<String, Function?>? ccb;
  HomePage({super.key, this.oemail = ""});
  @override
  State<HomePage> createState() => _HomePageState(oemail: oemail, ccb: ccb);
}

class _HomePageState extends State<HomePage> {
  bool isconnecting = false; //adding readings manually?
  bool needsupdate = true; //fetch readings first TODO(run every 10 seconds or so)
  String errormsg = "";
  bool waitfornext = false;
  bool nthres = false;
  bool firsttime = true;
  double currthres = 0;
  String currname = "";
  String oemail;
  Map<String, Function?>? ccb;
  _HomePageState({this.oemail = "", this.ccb});
  Future<void> addReading(
      MyAppState s, DateTime timec, double valc, mealc, methc, commc) async {
    int result = await s.addReadingLocallyAndToServer(timec, valc, mealc, methc, commc);
    print("reading appears");
    if (result == 200) {
      //
    } else {
      setState(() {
        errormsg = "NO";
      });
    }
  }

  Future<void> changeThreshold(MyAppState s, double timec) async {
    double? result = await s.changeThreshold(timec);
    if (result != null) {
      currthres = result;
      setState(() {
        needsupdate = true;
        nthres = false;
        errormsg = "Threshold updated successfully";
      });
    } else {
      setState(() {
        errormsg = "Something went wrong...";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);
    // appState.addListener(() {
    //   setState(() {
    //     needsupdate = true;
    //   });
    // });
    String oname = appState.lastinfo["name"]!;
    String title =
        oemail == "" ? "Welcome, $oname!" : "Viewing $oname's readings";
    //appState.addGlucometers();
    if(firsttime){
      firsttime = false;
      if(oemail=="")appState.getReadingsFromServerToLocal();
      else appState.getPatientReadingsFromServerToLocal(oemail);
    }else if (nthres) {
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        nthres = false;
                      });
                    },
                    child: const Icon(Icons.cancel)),
              ],
            ),
            const Text(
              'Set Warning Threshold',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (errormsg != "")
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
                            hintText: 'New Warning Threshold',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            } else if (!isNumeric(value) ||
                                double.parse(value) < 0) {
                              return 'Should be a non-negative number';
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
                              changeThreshold(
                                  appState, double.parse(userc.text));
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                    ]),
              ),
            ),
          ],
        ),
        //),
      );
    } else if (isconnecting) {
      final formKey = GlobalKey<FormState>();
      TextEditingController timec = TextEditingController();
      TextEditingController methc = TextEditingController();
      TextEditingController valc = TextEditingController();
      TextEditingController mealc = TextEditingController();
      TextEditingController commc = TextEditingController();
      return Center(
        //child: Container(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isconnecting = false;
                      });
                    },
                    child: const Icon(Icons.cancel)),
              ],
            ),
            const Text(
              "Add Manual Glucose Reading",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (errormsg != "")
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(errormsg),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: timec,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Time',
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
                          controller: methc,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Method',
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
                          controller: valc,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Value',
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
                          controller: mealc,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Meal Time',
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
                          controller: commc,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Comments?',
                          ),
                          validator: (String? value) {
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
                              addReading(
                                  appState,
                                  DateTime.parse(timec.text),
                                  double.parse(valc.text),
                                  mealc.text,
                                  methc.text,
                                  commc.text);
                              //TODO
                              setState(() {
                                isconnecting = false;
                                needsupdate = true;
                              });
                            }
                          },
                          child: const Text('Add Glucose Level Reading'),
                        ),
                      ),
                    ]),
              ),
            ),
          ],
        ),
        //),
      );
      //return ElevatedButton(child: Text("Connect Glucometer"), onPressed: (){});
    }
    return ListView(children: <Widget>[
      Center(
          child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
      )),
      Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                oemail == ""
                    ? (currthres < 0
                        ? "Set a Warning Threshold Now!"
                        : "Your current warning threshold is:")
                    : (currthres < 0
                        ? "$oname does not have a warning threshold set yet!"
                        : "$oname's warning threshold is:"),
                style: const TextStyle(fontSize: 25)),
          ],
        ),
      ),
      if (currthres >= 0)
        Center(
          child: Text(currthres.toString(),
              style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
        ),
      if (oemail == "")
        Center(
          child: ElevatedButton(
              onPressed: () {
                setState(() {
                  nthres = true;
                });
              },
              child: Text(currthres < 0 ? "Set Threshold" : "Change")),
        ),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('${oemail == "" ? "You have" : oname + " has"} ${oemail == "" ? appState.myReadings.length
           : appState.patientReadings.length} glucose readings'),
        ),
      ),
      if (oemail == "")
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isconnecting = true;
                  });
                },
                child: const Icon(Icons.add)),
          ),
        ),
      Consumer<MyAppState>(
          builder: (context, value, child) => Table(children: [
                TableRow(children: [
                  for (int i = 0; i < 5; i++)
                    const Divider(color: Colors.black, thickness: 2.0),
                ]),
                const TableRow(children: [
                  Text("Time",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Meal Time",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Glucose Reading Value",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Measuring Method",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Additional Comments",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                TableRow(children: [
                  for (int i = 0; i < 5; i++)
                    const Divider(color: Colors.black, thickness: 2.0),
                ]),
                // Use SomeExpensiveWidget here, without rebuilding every time.
                for (GlucoReading i in (oemail == "" ? value.myReadings : value.patientReadings))
                  TableRow(
                    children: [
                      Text(i.timestamp.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(i.meal,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text((i.value).toStringAsFixed(0),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(i.measure_method,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(i.comment,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
              ])),
    ]);
  }
}

class Settings extends StatefulWidget {
  final Function? callback;
  const Settings({super.key, this.callback});
  @override
  State<Settings> createState() => _SettingsState(callback: callback);
}

class _SettingsState extends State<Settings> {
  Function? callback;
  _SettingsState({this.callback});
  int microsettings =
      0; //0 - nothing, 1 - delete account, 2 - change name, 3 - change pass
  String errormsg = "";
  //request to change the name of the user to string t, if not, show error msg
  Future<void> changeName(MyAppState mas, String t) async {
    print("changing name $t");
    String? n = await mas.changeName(t);
    if (n != null) {
      setState(() {
        microsettings = 0;
        errormsg = "Name change successful";
      });
    } else {
      setState(() {
        errormsg = "Something went wrong";
      });
    }
  }

  Future<void> changePass(MyAppState mas, String t) async {
    print("changing pass $t");
    String? n = await mas.changePass(t);
    if (n != null) {
      setState(() {
        microsettings = 0;
        errormsg = "Password change successful";
      });
    } else {
      setState(() {
        errormsg = "Something went wrong";
      });
    }
  }

  Future<void> deleteAccount(MyAppState mas) async {
    int n = await mas.deleteAccount();
    if (n == 200) if (callback != null) {
      callback!();
    } else {
      setState(() {
        microsettings = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    if (microsettings == 0) {
      return SizedBox.expand(
        child: ListView(children: [
          IntrinsicHeight(
            child: Column(
              children: [
                const Text(
                  "Settings",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 50),
                ),
                if (errormsg != "") Text(errormsg),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        "Current Name: ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      Text(
                        appState.lastinfo["name"]!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              microsettings = 2;
                            });
                          },
                          child: const Text("Change Name")),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          microsettings = 3;
                        });
                      },
                      child: const Text("Change Password")),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: () {
                        appState.logOut();
                        if (callback != null) {
                          callback!();
                        }
                      },
                      child: const Text("Log Out")),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          microsettings = 1;
                        });
                      },
                      child: const Text("Delete Account")),
                ),
              ],
            ),
          ),
        ]),
      );
    } else if (microsettings == 1) {
      return SizedBox.expand(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        microsettings = 0;
                      });
                    },
                    child: const Icon(Icons.cancel)),
              ],
            ),
            const Text(
              "Delete Account?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
            ),
            ElevatedButton(
                onPressed: () {
                  deleteAccount(appState);
                },
                child: const Text("DELETE ACCOUNT")),
          ],
        ),
      );
    } else if (microsettings == 2) {
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        microsettings = 0;
                      });
                    },
                    child: const Icon(Icons.cancel)),
              ],
            ),
            const Text(
              'Change Account Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (errormsg != "")
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
                    ]),
              ),
            ),
          ],
        ),
        //),
      );
    } else if (microsettings == 3) {
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        microsettings = 0;
                      });
                    },
                    child: const Icon(Icons.cancel)),
              ],
            ),
            const Text(
              'Change Account Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (errormsg != "")
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
                    ]),
              ),
            ),
          ],
        ),
        //),
      );
    } else {
      return const Placeholder();
    }
  }
}

class ConnectPage extends StatefulWidget {
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
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    //appState.addGlucometers();
    var list = appState.glucometers;
    if (isconnecting) {
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return SingleChildScrollView(
        child: Center(
          //child: Container(
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isconnecting = false;
                        });
                      },
                      child: const Icon(Icons.cancel)),
                ],
              ),
              const Text(
                'Connect Glucose Monitor',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (errormsg != "")
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
                        ConnectGlucometer(glucometer: glucometer),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Validate will return true if the form is valid, or false if
                              // the form is invalid.
                              if (formKey.currentState!.validate()) {
                                //_formKey.currentState.save();
                                if (glucometer['dev'] == null) {
                                  setState(() {
                                    errormsg = "Please connect a glucometer";
                                  });
                                  return;
                                }
                                appState.addGlucometer(
                                    name: userc.text, dev: glucometer['dev']);
                                //TODO
                                //connectGlucometer();
                                setState(() {
                                  isconnecting = false;
                                });
                              }
                            },
                            child: const Text('Connect Glucometer'),
                          ),
                        ),
                      ]),
                ),
              ),
            ],
          ),
          //),
        ),
      );
      //return ElevatedButton(child: Text("Connect Glucometer"), onPressed: (){});
    } else if (list.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text(
              "Connect Glucose Monitors",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
            ),
            const Text('No connected glucose monitors yet'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isconnecting = true;
                    });
                  },
                  child: const Icon(Icons.add)),
            )
          ],
        ),
      );
    }
    return ListView(children: <Widget>[
      const Text(
        "Connect Glucose Monitors",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
      ),
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
              const Spacer(),
              ElevatedButton(
                  child: const Icon(Icons.delete /*TODO*/),
                  onPressed: () {
                    appState.deleteGlucometer(glucometer.id);
                    setState(() {});
                  })
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
            onPressed: () {
              setState(() {
                isconnecting = true;
              });
            },
            child: const Icon(Icons.add)),
      )
      /*for(WordPair wp in list)
          BigCard(thing: wp),*/
    ]);
  }
}

class SelectPatientsPage extends StatefulWidget {
  final Function? callback;
  const SelectPatientsPage({super.key, this.callback});
  @override
  State<SelectPatientsPage> createState() =>
      _SelectPatientsPageState(callback: callback);
}

class _SelectPatientsPageState extends State<SelectPatientsPage> {
  var glucometers = 0;
  bool needsupdate = true; //whether to run fetchlists when building
  bool isconnecting = false;
  String spectate = "";
  String errormsg = "";
  Function? callback;
  _SelectPatientsPageState({this.callback});
  void nuPage(int mode, [String o = ""]) {
    if (mode == 0) {
      setState(() {
        isconnecting = true;
      });
    } else {
      setState(() {
        spectate = o;
      });
    }
  }

  Future<void> addUser(MyAppState s, String email) async {
    var rp = await s.addCaretaker(email);
    if (rp == 200) {
      setState(() {
        isconnecting = false;
      });
    } else {
      setState(() {
        errormsg = "Something went wrong, please try again";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //appState.addGlucometers();
    var appState = context.watch<MyAppState>();
    if (spectate != "") {
      return Column(
        children: [
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      spectate = "";
                    });
                  },
                  child: const Icon(Icons.cancel)),
            ],
          ),
          Expanded(child: HomePage(oemail: spectate))
        ],
      );
    } else if (isconnecting) {
      final formKey = GlobalKey<FormState>();
      TextEditingController userc = TextEditingController();
      return Center(
        //child: Container(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isconnecting = false;
                      });
                    },
                    child: const Icon(Icons.cancel)),
              ],
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Authorize User',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 50),
                      ),
                      if (errormsg != "")
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
                    ]),
              ),
            ),
          ],
        ),
        //),
      );
    } else {
      if (false && appState.caretakers.isEmpty) {
        return SizedBox.expand(
          child: Column(
            children: [
              Expanded(child: PatientList(callback: nuPage)),
              Expanded(child: CaretakerList(callback: nuPage))
            ],
          ),
        );
      } else {
        return SizedBox.expand(
          child: Column(
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

class PatientList extends StatefulWidget {
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
  Future<void> fetchLists(MyAppState s) async {
    //var clist = await s.getCaretakers();
    print("starting request");
    var plist = await s.getPatients();
    print("request complete");
    if (plist != null) {
      setState(() {
        needsupdate = false;
      });
    } else {
      setState(() {
        errormsg = "Something went wrong, please try again later...Retrying";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    //appState.addGlucometers();
    var list = appState.patients;
    if (needsupdate) {
      fetchLists(appState);
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Loading..."),
        ],
      );
    } else if (errormsg != "") {
      return Text(errormsg);
    } else if (list.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Text('No connected patients yet'),
          ],
        ),
      );
    }
    return ListView(children: <Widget>[
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text(
          "Patients",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You can view '
              '${appState.patients.length} patients:'),
        ),
      ]),
      for (Patient glucometer in appState.patients)
        ListTile(
          leading: const Icon(Icons.person),
          title: Row(
            children: [
              Text(glucometer.name),
              const Spacer(),
              ElevatedButton(
                  child: const Icon(Icons.search),
                  onPressed: () {
                    //TODO: VIEW PATIENT
                    callback!(1, glucometer.id);
                  }),
              ElevatedButton(
                  child: const Icon(Icons.delete /*TODO*/),
                  onPressed: () {
                    appState.deletePatient(glucometer.id, ({String msg = ""}) {
                      setState(() {
                        errormsg = msg;
                      });
                    });
                    setState(() {});
                  })
            ],
          ),
        ),
      /*for(WordPair wp in list)
          BigCard(thing: wp),*/
    ]);
  }
}

class CaretakerList extends StatefulWidget {
  final Function? callback;
  const CaretakerList({super.key, this.callback});
  @override
  State<CaretakerList> createState() => _CaretakerListState(callback: callback);
}

class _CaretakerListState extends State<CaretakerList> {
  Function? callback;
  bool needsupdate = true;
  bool waitfornext = false;
  String errormsg = "";
  _CaretakerListState({this.callback});
  Future<void> fetchLists(MyAppState s) async {
    //var clist = await s.getCaretakers();
    if (waitfornext) await Future.delayed(const Duration(seconds: 5));
    print("starting request");
    var plist = await s.getCaretakersFromServerToLocal();
    print("request complete");
    if (plist != null) {
      setState(() {
        needsupdate = false;
        waitfornext = false;
      });
    } else {
      setState(() {
        errormsg = "Something went wrong, please try again later...Retrying";
        waitfornext = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    //appState.addGlucometers();
    var list = appState.caretakers;
    if (needsupdate) {
      fetchLists(appState);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (errormsg != "") Text(errormsg),
          const Text("Loading..."),
        ],
      );
    } else if (errormsg != "") {
      return Text(errormsg);
    } else if (list.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('No authorized users yet'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () {
                    callback!(0);
                  },
                  child: const Icon(Icons.add)),
            )
          ],
        ),
      );
    }
    return ListView(children: <Widget>[
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text(
          "Authorized Users",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.caretakers.length} authorized users:'),
        ),
      ]),
      for (Caretaker glucometer in appState.caretakers)
        ListTile(
          leading: const Icon(Icons.person),
          title: Row(
            children: [
              Text(glucometer.name),
              const Spacer(),
              ElevatedButton(
                  child: const Icon(Icons.delete /*TODO*/),
                  onPressed: () {
                    appState.deleteCaretaker(glucometer.id, (
                        {String msg = ""}) {
                      setState(() {
                        errormsg = msg;
                      });
                    });
                    setState(() {});
                  })
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
            onPressed: () {
              callback!(0);
            },
            child: const Icon(Icons.add)),
      )
      /*for(WordPair wp in list)
          BigCard(thing: wp),*/
    ]);
  }
}

class ModForm extends StatelessWidget {
  const ModForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
