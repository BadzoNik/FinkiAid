import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool isLoggedIn = false;
  late ConnectivityResult _connectivityResult;

  @override
  void initState() {
    super.initState();
    _updateAuthState();
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

  void _updateAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        isLoggedIn = user != null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width * 0.45;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.cyan.shade200,
        actions: [
          if (isLoggedIn)
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/favorites');
              },
              child: const Text('Favorites'),
            ),
          IconButton(
            onPressed: () async {
              if (_connectivityResult != ConnectivityResult.none) {
                if (!isLoggedIn) {
                  Navigator.of(context).pushNamed('/login');
                } else {
                  Navigator.of(context).pushNamed('/profile');
                }
              } else {
                _showConnectivityDialog(context);
              }
            },
            icon: isLoggedIn
                ? const Icon(Icons.person_rounded)
                : const Icon(Icons.person_off_rounded),
          ),
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_connectivityResult != ConnectivityResult.none) {
                    Navigator.of(context).pushNamed('/login');
                  } else {
                    _showConnectivityDialog(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.cyan.shade200, Colors.blue.shade500],
          ),
        ),
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 40),
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_connectivityResult != ConnectivityResult.none) {
                        Navigator.of(context).pushNamed('/subjects');
                      } else {
                        _showConnectivityDialog(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: Size(buttonWidth, buttonWidth),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.book, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Subjects',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_connectivityResult != ConnectivityResult.none) {
                        Navigator.of(context).pushNamed('/professors');
                      } else {
                        _showConnectivityDialog(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: Size(buttonWidth, buttonWidth),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.people, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Professors',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 360),
              Padding(
                padding: EdgeInsets.only(right: 17.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_connectivityResult != ConnectivityResult.none) {
                        print('Favorites Button Pressed!');
                      } else {
                        _showConnectivityDialog(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: Size(buttonWidth * 0.4, buttonWidth * 0.4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.star, size: 24, color: Colors.blue),
                        SizedBox(height: 1),
                        Text(
                          'Favorites',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Internet Connection'),
          content: Text('Please connect to the internet to continue.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
