
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  user,
  admin,
}

class UserFinki {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String password;
  final UserRole userRole;

  UserFinki({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    required this.userRole
  });

  static Future<bool> checkCurrentUserIsAdmin() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData =
          querySnapshot.docs.first.data() as Map<String, dynamic>;
          final userRole = userData['role'];
          return userRole == "admin";
        } else {
          print('User document not found');
          return false;
        }
      } else {
        print('No user is currently logged in');
        return false;
      }
    } catch (error) {
      print('Error fetching user document: $error');
      return false;
    }
  }
}
