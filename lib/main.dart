import 'package:finkiaid/dependency_injection.dart';
import 'package:finkiaid/professor/ProfessorsScreen.dart';
import 'package:finkiaid/ProfileScreen.dart';
import 'package:finkiaid/firebase_auth/LoginScreen.dart';
import 'package:finkiaid/firebase_auth/RegisterScreen.dart';
import 'package:finkiaid/subject/FavoriteSubjectsScreen.dart';
import 'package:finkiaid/subject/SubjectDetailScreen.dart';
import 'package:finkiaid/subject/SubjectsScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'firebase_auth/firebase_options.dart';
import 'HomePage.dart';
import 'model/Subject.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
  DependencyInjection.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
      ),
      home: const HomePage(),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => HomePage(),
        '/subjects': (BuildContext context) => SubjectsScreen(),
        '/subjectDetail': (BuildContext context) {
          // Extract the arguments passed to this route
          final arguments = ModalRoute.of(context)?.settings.arguments;
          // Return the SubjectDetailScreen with the provided argument if it's not null
          return SubjectDetailScreen(subject: arguments as Subject, callerIsFavoriteSubjects: false,);
        },
        '/favorites': (BuildContext context) => FavoriteSubjectsScreen(),
        '/professors': (BuildContext context) => ProfessorsScreen(),
        '/profile': (BuildContext context) => ProfileScreen(),
        '/login': (BuildContext context) => LoginScreen(),
        '/register': (BuildContext context) => RegisterScreen(),
      },
    );
  }
}

