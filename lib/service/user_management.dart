import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

import '../model/UserFinki.dart';

class UserManagement {
  Future<void> storeNewUser(UserFinki user, BuildContext context) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc();
    await userDoc.set({
      'id': user.id,
      'name': user.name,
      'surname': user.surname,
      'email': user.email,
      'role': user.userRole.name
    });

    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed('/home');
  }
}