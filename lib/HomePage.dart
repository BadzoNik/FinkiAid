import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
        title: const Text('Home Page'),
        actions: [
          IconButton(
            onPressed: () async {
              if (!isLoggedIn) {
                Navigator.of(context).pushNamed('/login');
              } else {
                Navigator.of(context).pushNamed('/profile');
              }
            },
            icon: isLoggedIn
                ? const Icon(Icons.person_rounded)
                : const Icon(Icons.person_off_rounded),
          )
        ],
      ),
      body: Center(
          child: Column(
        children: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/subjects');
              },
              child: const Text('Subjects')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/professors');
              },
              child: const Text('Professors')),
          if (!isLoggedIn)
            Row(
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    child: const Text('Login'))
              ],
            ),
        ],
      )),
    );
  }
}
