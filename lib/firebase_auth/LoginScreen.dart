import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finkiaid/HomePage.dart';
import 'package:finkiaid/firebase_auth/RegisterScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/UserFinki.dart';
import '../service/user_management.dart';
import 'Validations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late ConnectivityResult _connectivityResult;
  String _email = "";
  String _password = "";
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectivityResult = result;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = connectivityResult;
    });
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
        backgroundColor: Colors.cyan.shade200,
        title: const Text(''),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.cyan.shade200, Colors.blue.shade500],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 70),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                          labelText: "Email",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
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
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                          labelText: "Password",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
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
                                  onPressed: _connectivityResult !=
                                          ConnectivityResult.none
                                      ? () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            _handleLogin();
                                          }
                                        }
                                      : null,
                                  child: const Text("Login"),
                                ),
                                const SizedBox(width: 10),
                                const Text('or'),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _connectivityResult !=
                                          ConnectivityResult.none
                                      ? () async {
                                          signInWithGoogle();
                                        }
                                      : null,
                                  icon: Image.asset(
                                    "assets/google_img.png",
                                    height: 24,
                                  ),
                                  label: const Text("Login via Google"),
                                ),
                              ],
                            ),
                          ),
                          const Text('Do not have an account yet? Register!'),
                          ElevatedButton(
                            onPressed:
                                _connectivityResult != ConnectivityResult.none
                                    ? () {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const RegisterScreen(),
                                          ),
                                          (route) => route.isFirst,
                                        );
                                      }
                                    : null,
                            child: const Text("Register"),
                          )
                        ],
                      ),
                    ],
                  ),
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

      UserFinki user = UserFinki(
          id: userCredential.user!.uid,
          name: _name,
          surname: _surname,
          email: _email,
          password: '',
          userRole: UserRole.user,
          userImage: "");

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
