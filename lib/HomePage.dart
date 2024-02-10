import 'package:flutter/material.dart';

import 'LoginScreen.dart';
import 'ProfessorsScreen.dart';
import 'RegisterScreen.dart';
import 'SubjectsScreen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SubjectsScreen()
                      )
                  );
                },
                child: const Text('Subjects')
            ),
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfessorsScreen()
                    )
                  );
                },
                child: const Text('Professors')
            ),
            Row(
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()
                          )
                      );
                    },
                    child: const Text('Login')
                ),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()
                          )
                      );
                    },
                    child: const Text('Register')
                )
              ],
            ),
          ],
        )
      ),
    );
  }
}


