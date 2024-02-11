import 'package:finkiaid/HomePage.dart';
import 'package:finkiaid/firebase_auth/LoginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _updateAuthState();
  }

  void _updateAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        isLoggedIn = user != null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: Column(
            children: [
              Container(
                child: Icon(Icons.person_rounded),
              ),
              if (isLoggedIn)
                TextButton(
                    onPressed: () {
                      _firebaseAuth.signOut();
                      setState(() {
                        isLoggedIn = false;
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Logout')),
            ]
        )
    );
  }
}
