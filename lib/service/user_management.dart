import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../model/UserFinki.dart';

class UserManagement {
  void storeNewUser(UserFinki user, BuildContext context) {
    FirebaseFirestore.instance.collection('users')
        .add({
      'name': user.name,
      'surname': user.surname,
      'email': user.email,
      'role': user.userRole.name
    }).then((value) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed('/home');
    }).catchError((e) {
      debugPrint("Error in user management: $e");
    });
  }
}