import 'package:finkiaid/HomePage.dart';
import 'package:finkiaid/firebase_auth/RegisterScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/UserFinki.dart';
import '../service/user_management.dart';
import 'Validations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _email = "";
  String _password = "";
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    //signInWithGoogle();
  }

  void _handleLogin() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      _errorMessage = '';
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message!;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
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
                const SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    Center(
                      child: Text(_errorMessage,
                          style: const TextStyle(color: Colors.red)),
                    ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              //back stack na activities !!
                              if (_formKey.currentState!.validate()) {
                                _handleLogin();
                              }
                            },
                            child: Text("Login"),
                          ),
                          SizedBox(width: 10), // Add space between buttons
                          Text('or'),
                          SizedBox(width: 10), // Add space between buttons
                          ElevatedButton.icon(
                            onPressed: () async {
                              signInWithGoogle();
                            },
                            icon: Image.asset("assets/google_img.png",
                                height: 24),
                            label: const Text("Login via Google"),
                          ),
                        ],
                      ),
                    ),
                    const Text('Do not have an account yet? Register!'),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                                (route) => route.isFirst);
                      },
                      child: const Text("Register"),
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

  signInWithGoogle() async {
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);

    final UserCredential userCredential =
    await _auth.signInWithCredential(credential);

    // Extract user information
    final User? user = userCredential.user;
    final String? displayName = user?.displayName;
    final String? _email = user?.email;

    if (user != null && _email != null && displayName != null) {
      List<String> nameParts = displayName.split(' ');
      String _name = nameParts.first;
      String _surname = nameParts.length > 1 ? nameParts.last : '';

      if (nameParts.length == 0) {
        _name = displayName;
        _surname = "";
      }

      UserFinki user = UserFinki(id: userCredential.user!.uid,
          name: _name,
          surname: _surname,
          email: _email,
          password: '',
          userRole: UserRole.user);

      UserManagement().storeNewUser(user, context);

      // UserManagement().storeNewUser(UserFinki(
      //   name: firstName,
      //   surname: lastName,
      //   email: email,
      //   password: '',
      //     userRole: UserRole.user
      // ), context);
    }
  }
}
