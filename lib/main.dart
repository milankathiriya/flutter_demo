import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'helpers/firebase_auth_helper.dart';
import 'screens/dash_board.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

/*
Ch. 13

Publish Code to GitHub
- What is GitHub?
- Installation of Git
- Creating GitHub Account
- Create first GitHub Repository
- Push first App on GitHub
- Grab Project from GitHub
* */

Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification!.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_messageHandler);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => HomePage(),
        'dashboard': (context) => DashBoard(),
      },
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _emailLoginController = TextEditingController();
  final TextEditingController _passwordLoginController =
      TextEditingController();

  String email = "";
  String password = "";

  checkFCMPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  @override
  void initState() {
    super.initState();

    messaging.getToken().then((token) => print(token));

    checkFCMPermission();

    // foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Foreground Notification"),
          content: Text(
              "Notification: ${message.notification}\nData: ${message.data}"),
        ),
      );
    });

    // background => click => app open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("From Background Notification"),
          content: Text(
              "Notification: ${message.notification}\nData: ${message.data}"),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter App"),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Send FCM"),
              style: ElevatedButton.styleFrom(
                primary: Colors.deepOrange,
              ),
              onPressed: sendFCM,
            ),
            ElevatedButton(
              child: const Text("Login Anonymously"),
              onPressed: () async {
                UserCredential userCredential =
                    await FirebaseAuthHelper.instance.loginAnonymously();

                print(
                    "User logged in successfully with UID: ${userCredential.user!.uid} ");

                Navigator.of(context)
                    .pushNamed('dashboard', arguments: userCredential);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  child: const Text("Register"),
                  onPressed: registerUser,
                ),
                ElevatedButton(
                  child: const Text("Login with Email/Password"),
                  onPressed: loginUser,
                ),
              ],
            ),
            ElevatedButton(
              child: const Text("Sign in with Google"),
              style: ElevatedButton.styleFrom(
                primary: Colors.deepOrange,
              ),
              onPressed: () async {
                UserCredential? userCredential =
                    await FirebaseAuthHelper.instance.signInWithGoogle();

                print("Successful login with Google...");

                Navigator.of(context)
                    .pushNamed('dashboard', arguments: userCredential);

                print("UID: ${userCredential.user!.uid}");
                print("Email: ${userCredential.user!.email}");
                print("Username: ${userCredential.user!.displayName}");
                print("Photo URL: ${userCredential.user!.photoURL}");
              },
            ),
          ],
        ),
      ),
    );
  }

  void registerUser() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text("Register User"),
          ),
          content: Form(
            key: _registerFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter any email first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      email = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                    hintText: "Enter email here",
                  ),
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter any password first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      password = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Password",
                    hintText: "Enter password here",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Cancel"),
              onPressed: () {
                _emailController.clear();
                _passwordController.clear();

                setState(() {
                  email = "";
                  password = "";
                });

                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Register"),
              onPressed: () async {
                if (_registerFormKey.currentState!.validate()) {
                  _registerFormKey.currentState!.save();

                  UserCredential userCredential = await FirebaseAuthHelper
                      .instance
                      .registerWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  _emailController.clear();
                  _passwordController.clear();

                  setState(() {
                    email = "";
                    password = "";
                  });

                  Navigator.of(context).pop();

                  print(
                      "USER: ${userCredential.user!.uid}\nEmail: ${userCredential.user!.email}");
                }
              },
            ),
          ],
        );
      },
    );
  }

  void loginUser() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text("Login User"),
          ),
          content: Form(
            key: _loginFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailLoginController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter any email first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      email = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                    hintText: "Enter email here",
                  ),
                ),
                TextFormField(
                  controller: _passwordLoginController,
                  obscureText: true,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter any password first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      password = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Password",
                    hintText: "Enter password here",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Cancel"),
              onPressed: () {
                _emailLoginController.clear();
                _passwordLoginController.clear();

                setState(() {
                  email = "";
                  password = "";
                });

                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Login"),
              onPressed: () async {
                if (_loginFormKey.currentState!.validate()) {
                  _loginFormKey.currentState!.save();

                  try {
                    UserCredential userCredential = await FirebaseAuthHelper
                        .instance
                        .signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    _emailLoginController.clear();
                    _passwordLoginController.clear();

                    setState(() {
                      email = "";
                      password = "";
                    });

                    Navigator.of(context).pop();

                    print("Successfull Logged In...\n"
                        "USER: ${userCredential.user!.uid}\nEmail: ${userCredential.user!.email}");

                    Navigator.of(context)
                        .pushNamed('dashboard', arguments: userCredential);
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'user-not-found') {
                      print("User not found with provided credentials.");
                    } else if (e.code == 'wrong-password') {
                      print("Password is incorrect.");
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  sendFCM() async {
    String url = "https://fcm.googleapis.com/fcm/send";
    Map<String, String> myHeaders = {
      "Content-type": "application/json",
      "Authorization":
          "key=AAAAd-nuySo:APA91bHqGxCUK1Sg9oGfAVWNn7zKpSDItpoOdmdxzsT3pB_c9N6i6Usx0_qK_FolJaGU4RUmd8R3sAo-ZmXayORJSC9Iq_zz0iuzJFSu4IMi12byjOIOL3p2t2MZY-5oPiN2hED1nafS",
    };

    Map myBody = {
      "registration_ids": [
        "fslsi_EOQLyjqkyoVlaKw9:APA91bE3HHTy9yCSo-tiNAz4Q4QKGfqL_PUfFbnUsDMm0I0BKkbNVNulZ3bnLev4vy9TrB6EV7GGGGMgw-XBqKuml9YIZ0HsJswlFdMMb0r_fT9qvgiuS3CC8t13a3TUvumSQvCY1Sbn"
      ],
      "notification": {
        "title": "hello",
        "body": "New announcement assigned",
        "content_available": true,
        "priority": "high"
      },
      "data": {
        "priority": "high",
        "content_available": true,
        "bodyText": "New Announcement assigned",
        "organization": "Elementary school",
        "custom_key": "my_custom_val"
      }
    };

    var response = await http.post(Uri.parse(url),
        headers: myHeaders, body: jsonEncode(myBody));

    if (response.statusCode == 200) {
      print("FCM Successfully done...");
      print(response.body);
    }
  }
}
