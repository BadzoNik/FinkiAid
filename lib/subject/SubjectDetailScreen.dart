import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finkiaid/model/Subject.dart';
import 'package:finkiaid/notifications/Notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'SubjectExamSessions.dart';
import 'SubjectMidTerms.dart';
import 'SubjectReviews.dart';

class SubjectDetailScreen extends StatefulWidget {
  final Subject subject;
  final bool callerIsFavoriteSubjects;

  const SubjectDetailScreen({
    required this.subject,
    required this.callerIsFavoriteSubjects,
    Key? key,
  }) : super(key: key);

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  bool isLoggedIn = false;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _updateAuthState();
    _checkIfSubjectAlreadyAddedToFavorites();
  }

  void _checkIfSubjectAlreadyAddedToFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteRef = FirebaseFirestore.instance
            .collection('favoriteSubjects')
            .where('userId', isEqualTo: user.uid)
            .where('subjectId', isEqualTo: widget.subject.id);

        final existingFavorite = await favoriteRef.get();

        if (existingFavorite.docs.isNotEmpty) {
          setState(() {
            isFavorite = true;
          });
        } else {
          setState(() {
            isFavorite = false;
          });
        }
      } else {
        print('_checkIfSubjectAlreadyAddedToFavorites(): User not logged in');
      }
    } catch (error) {
      print(
          '_checkIfSubjectAlreadyAddedToFavorites: Error toggling checking status: $error');
    }
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
        title: Text(widget.subject.name),
        leading: widget.callerIsFavoriteSubjects
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil(ModalRoute.withName('/home'));

                  Navigator.pushNamed(context, '/favorites');
                },
              )
            : null,
        actions: [
          IconButton(
            icon:
                isFavorite ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
            onPressed: () {
              // Toggle the favorite status when the heart icon is pressed
              setState(() {
                if (!isLoggedIn) {
                  Navigator.of(context).pushNamed('/login');
                } else {
                  _addToFavorites();
                }
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectMidTerms(widget.subject),
                      ));
                },
                child: const Text('Mid-Terms')),
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SubjectExamSessions(widget.subject),
                      ));
                },
                child: const Text('Exam-Sessions')),
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectReviews(widget.subject),
                      ));
                },
                child: const Text('View Comments'))
          ],
        ),
      ),
    );
  }

  void _addToFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteRef = FirebaseFirestore.instance
            .collection('favoriteSubjects')
            .where('userId', isEqualTo: user.uid)
            .where('subjectId', isEqualTo: widget.subject.id);

        final existingFavorite = await favoriteRef.get();

        if (existingFavorite.docs.isNotEmpty) {
          await existingFavorite.docs.first.reference.delete();
          setState(() {
            isFavorite = false;
          });
          Notifications.showPopUpMessage(
              context, '${widget.subject.name} removed from favorites!');
        } else {
          final userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user.email)
              .get();

          var userName = user.displayName;

          if (userSnapshot.docs.isNotEmpty) {
            final userData =
                userSnapshot.docs.first.data() as Map<String, dynamic>;
            userName = '${userData['name']} ${userData['surname']}';
          }

          final favoriteSubject = {
            "subjectId": widget.subject.id,
            "subjectName": widget.subject.name,
            "userId": user.uid,
            "userName": userName,
            "userEmail": user.email
          };

          await FirebaseFirestore.instance
              .collection('favoriteSubjects')
              .add(favoriteSubject);

          setState(() {
            isFavorite = true;
          });

          Notifications.showPopUpMessage(
              context, '${widget.subject.name} added to favorites!');
        }
      } else {
        print('_addToFavorites(): User not logged in');
      }
    } catch (error) {
      print('Error toggling favorite status: $error');
    }
  }
}
