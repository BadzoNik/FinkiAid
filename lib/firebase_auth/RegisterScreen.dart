import 'package:finkiaid/HomePage.dart';
import 'package:finkiaid/firebase_auth/Validations.dart';
import 'package:finkiaid/service/user_management.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/UserFinki.dart';
import 'LoginScreen.dart';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  String _name = "";
  String _surname = "";
  String _email = "";
  String _password = "";
  String _passwordRepeat = "";
  String _errorMessage = '';

  void _handleSignUp(context) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text)
      .then((signedInUser) {
          // UserManagement().storeNewUser(signedInUser, context);
      });
      _errorMessage = '';
    } on FirebaseAuthException catch(e) {
      _errorMessage = e.message!;
    }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: Colors.cyan,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Name",
                  ),
                  validator: Validations.validateName,
                  onChanged: (value) {
                    setState(() {
                      _name = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _surnameController,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Surname",
                  ),
                  validator: Validations.validateName,
                  onChanged: (value) {
                    setState(() {
                      _surname = value;
                      _errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                  ),
                  validator: Validations.validateEmail,
                  onChanged: (value) {
                    setState(() {
                      _email = value;
                      _errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Password",
                  ),
                  validator: Validations.validatePassword,
                  onChanged: (value) {
                    setState(() {
                      _password = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _repeatPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Repeat Password",
                  ),
                  validator: (value) {
                    return Validations.validatePasswordMatch(value, _passwordController.text);
                  },
                  onChanged: (value) {
                    setState(() {
                      _passwordRepeat = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Center(
                      child: Text(_errorMessage, style: TextStyle(color: Colors.red),),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // _handleSignUp(context);
                          FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                              email: _email, 
                              password: _password)
                              .then((signedInUser) {
                            UserFinki user = UserFinki(
                              name: _name,
                              surname: _surname,
                              email: _email,
                              password: _password,
                              userRole: UserRole.user
                            );

                            UserManagement().storeNewUser(user, context);
                          })
                          .catchError((e) {
                            print(e);
                          });
                          setState(() {

                          });
                        }
                      },
                      child: const Text("Register"),
                    ),
                    const Text("Already registered? Log in!"),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ), (route) => route.isFirst
                          );
                        },
                        child:
                        const Text("Log In")
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


