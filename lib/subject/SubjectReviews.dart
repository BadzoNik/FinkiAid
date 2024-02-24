
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finkiaid/model/Subject.dart';
import 'package:finkiaid/subject/SubjectDetailScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/UserFinki.dart';
import '../notifications/Notifications.dart';

class SubjectReviews extends StatefulWidget {
  final Subject subject;

  const SubjectReviews(this.subject, {super.key});

  @override
  State<SubjectReviews> createState() => _SubjectReviewsState();
}

class _SubjectReviewsState extends State<SubjectReviews> {

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool isLoggedIn = false;
  List<Map<String, dynamic>> allComments = [];


  @override
  void initState() {
    super.initState();
    _updateAuthState();
    _getAllComments();
  }

  void _updateAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        isLoggedIn = user != null;
      });
    });
  }

  void _getAllComments() async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('subjectsComments')
          .where('subjectName', isEqualTo: widget.subject.name)
          .get();

      List<Map<String, String>> comments = [];

      querySnapshot.docs.forEach((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Handle conversion of timestamp field
        dynamic timestampData = data['timestamp'];
        Timestamp timestamp;
        if (timestampData is Timestamp) {
          timestamp = timestampData;
        } else {
          timestamp = Timestamp.fromDate(DateTime.parse(timestampData));
        }
        String formattedTimestamp = timestamp.toDate().toString();

        Map<String, String> commentMap = {
          'subjectId': data['subjectId'],
          'subjectName': data['subjectName'],
          'userId': data['userId'],
          'userName': data['userName'],
          'userEmail': data['userEmail'],
          'comment': data['comment'],
          'timestamp': formattedTimestamp,
        };

        comments.add(commentMap);
      });

      setState(() {
        allComments = comments;
      });
    } catch (error) {
      print('_getAllComments(): Error retrieving comments: $error');
    }
  }

  void _submitComment(String commentText, StateSetter setState) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        var userName = user.displayName;
        final userEmail = user.email;

        QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          final userData =
          usersSnapshot.docs.first.data() as Map<String, dynamic>;
          userName = '${userData['name']} ${userData['surname']}';
        }

        Map<String, dynamic> commentData = {
          'subjectId': widget.subject.id,
          'subjectName': widget.subject.name,
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'comment': commentText,
          'timestamp': DateTime.now().toString(),
        };
        Map<String, String> commentMap = commentData.cast<String, String>();

        final subjectDoc = FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subject.id);
        final subjectSnapshot = await subjectDoc.get();

        if (subjectSnapshot.exists) {
          final subjectData =
          subjectSnapshot.data() as Map<String, dynamic>;
          final List<dynamic> comments = subjectData['comments'] ?? [];
          comments.add(commentText);
          await subjectDoc.update({'comments': comments});
        }

        await FirebaseFirestore.instance
            .collection('subjectsComments')
            .add(commentMap);

        setState(() {
          allComments.add(commentMap);
        });
        Notifications.showPopUpMessage(
            context, 'Comment submitted successfully!');
      } else {
        print('User not logged in');
      }
    } catch (error) {
      print('Error submitting comment: $error');
    }
  }

  void _removeComment(var commentTimestamp, String userComment,
      StateSetter setState) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final commentQuerySnapshot = await FirebaseFirestore.instance
            .collection('subjectsComments')
            .where('subjectId', isEqualTo: widget.subject.id)
            .get();

        if (commentQuerySnapshot.docs.isNotEmpty) {
          final commentDocId = commentQuerySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('subjectsComments')
              .doc(commentDocId)
              .delete();

          final subjectDoc = FirebaseFirestore.instance
              .collection('subjects')
              .doc(widget.subject.id);
          final subjectSnapshot = await subjectDoc.get();

          if (subjectSnapshot.exists) {
            final subjectData =
            subjectSnapshot.data() as Map<String, dynamic>;
            final List<dynamic> comments = subjectData['comments'] ?? [];
            comments.removeWhere((comment) => comment == userComment);
            await subjectDoc.update({'comments': comments});

            Notifications.showPopUpMessage(
                context, 'Comment removed successfully!');
          }

          setState(() {
            allComments.removeWhere((comment) =>
            comment['timestamp'] == commentTimestamp &&
                comment['comment'] == userComment);
          });
        }
      } else {
        print('_removeComment(): User not logged in');
      }
    } catch (error) {
      print('_removeComment(): Error removing comment: $error');
    }
  }


  void _viewComments(BuildContext context, SubjectReviews widget,
      ) async {
    TextEditingController _commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.subject.name),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(labelText: 'Add a comment'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                String newComment = _commentController.text.trim();
                if (newComment.isNotEmpty) {
                  _submitComment(newComment , setState);
                  _commentController.clear();
                }
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan.shade200,
        title: Text(widget.subject.name),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.cyan.shade200, Colors.blue.shade500],
          ),
        ),
        child: ListView.builder(
          itemCount: allComments.length,
          itemBuilder: (context, index) {
            final comment = allComments[index];
            return Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${comment['userName']} - ${comment['userEmail']}'),
                subtitle: Text(comment['comment']),
                trailing: IconButton(
                  icon: Icon(Icons.delete), // Use the trash can icon
                  onPressed: () {
                    _removeComment(
                      comment['timestamp'],
                      comment['comment'],
                      setState,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _viewComments(context, widget);
        },
        child: Icon(Icons.comment),
      ),
    );
  }
}