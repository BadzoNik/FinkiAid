import 'package:finkiaid/ProfessorsScreen.dart';
import 'package:finkiaid/ProfileScreen.dart';
import 'package:finkiaid/SubjectsScreen.dart';
import 'package:finkiaid/firebase_auth/LoginScreen.dart';
import 'package:finkiaid/firebase_auth/RegisterScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_auth/firebase_options.dart';
import 'HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
      ),
      home: const HomePage(),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => HomePage(),
        '/subjects': (BuildContext context) => SubjectsScreen(),
        '/professors': (BuildContext context) => ProfessorsScreen(),
        '/profile': (BuildContext context) => ProfileScreen(),
        '/login': (BuildContext context) => LoginScreen(),
        '/register': (BuildContext context) => RegisterScreen()
      },
    );
  }
}

