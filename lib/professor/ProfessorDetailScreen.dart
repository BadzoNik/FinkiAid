import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finkiaid/model/UserFinki.dart';
import 'package:finkiaid/notifications/Notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/Professor.dart';
import 'ProfessorsScreen.dart';

class ProfessorDetailScreen extends StatefulWidget {
  final Professor professor;

  ProfessorDetailScreen(this.professor, {Key? key}) : super(key: key);

  @override
  _ProfessorDetailScreenState createState() => _ProfessorDetailScreenState();
}

class _ProfessorDetailScreenState extends State<ProfessorDetailScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool isLoggedIn = false;
  bool alreadyRated = false;
  int userRating = 0;
  double averageRating = 0.0;
  List<int> allRatings = [];
  List<Map<String, dynamic>> allComments = [];
  bool currentUserIsAdmin = false;

  @override
  void initState() {
    super.initState();
    _updateAuthState();
    _getAllRatings();
    _loadUserRating();
    _getAllComments();
    _checkUserIsAdmin();
  }

  void _checkUserIsAdmin() async {
    bool isAdmin = await UserFinki.checkCurrentUserIsAdmin();

    setState(() {
      currentUserIsAdmin = isAdmin;
    });
  }

  void _loadUserRating() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final ratingSnapshot = await FirebaseFirestore.instance
            .collection('professorsRatings')
            .where('professorId', isEqualTo: widget.professor.id)
            .where('userId', isEqualTo: userId)
            .get();

        if (ratingSnapshot.docs.isNotEmpty) {
          final ratingData = ratingSnapshot.docs.first.data();
          setState(() {
            userRating = ratingData['rating'];
            alreadyRated = true;
          });
        } else {
          setState(() {
            alreadyRated = false;
          });
        }
      }
    } catch (error) {
      print('Error loading user rating: $error');
    }
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
          .collection('professorsComments')
          .where('professorName', isEqualTo: widget.professor.fullName)
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
          'professorId': data['professorId'],
          'professorName': data['professorName'],
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

  void _submitComment(String commentText) async {
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
          'professorId': widget.professor.id,
          'professorName': widget.professor.fullName,
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'comment': commentText,
          'timestamp': DateTime.now().toString(),
        };
        Map<String, String> commentMap = commentData.cast<String, String>();

        final professorDoc = FirebaseFirestore.instance
            .collection('professors')
            .doc(widget.professor.id);
        final professorSnapshot = await professorDoc.get();

        if (professorSnapshot.exists) {
          final professorData =
          professorSnapshot.data() as Map<String, dynamic>;
          final List<dynamic> comments = professorData['comments'] ?? [];
          comments.add(commentText);
          await professorDoc.update({'comments': comments});
        }

        await FirebaseFirestore.instance
            .collection('professorsComments')
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
            .collection('professorsComments')
            .where('professorId', isEqualTo: widget.professor.id)
            .get();

        if (commentQuerySnapshot.docs.isNotEmpty) {
          final commentDocId = commentQuerySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('professorsComments')
              .doc(commentDocId)
              .delete();

          final professorDoc = FirebaseFirestore.instance
              .collection('professors')
              .doc(widget.professor.id);
          final professorSnapshot = await professorDoc.get();

          if (professorSnapshot.exists) {
            final professorData =
            professorSnapshot.data() as Map<String, dynamic>;
            final List<dynamic> comments = professorData['comments'] ?? [];
            comments.removeWhere((comment) => comment == userComment);
            await professorDoc.update({'comments': comments});

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

  void _showDialogForAddingComments(BuildContext context, ProfessorDetailScreen widget,
      List<Map<String, dynamic>> allComments) async {
    TextEditingController _commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.professor.fullName),
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
                  _submitComment(newComment);
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


  void _getAllRatings() async {
    try {
      final professorDoc = FirebaseFirestore.instance
          .collection('professors')
          .doc(widget.professor.id);
      final professorSnapshot = await professorDoc.get();

      if (professorSnapshot.exists) {
        final professorData = professorSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> ratings = professorData['ratings'] ?? [];

        setState(() {
          allRatings = List<int>.from(ratings);
          _calculateAverageRating();
        });
      }
    } catch (error) {
      print('_getAllRatings(): Error retrieving ratings: $error');
    }
  }

  void _calculateAverageRating() {
    if (allRatings.isNotEmpty) {
      final totalRating =
      allRatings.reduce((value, element) => value + element);
      setState(() {
        averageRating = totalRating / allRatings.length;
      });
    } else {
      setState(() {
        averageRating = 0.0;
      });
    }
  }

  void _updateRating(int rating) {
    setState(() {
      userRating = rating;
    });
  }

  void _submitRating() async {
    if (userRating > 0 && !alreadyRated) {
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

          allRatings.add(userRating);
          _calculateAverageRating();

          await FirebaseFirestore.instance.collection('professorsRatings').add({
            'professorName': widget.professor.fullName,
            'professorId': widget.professor.id,
            'userEmail': userEmail,
            'userId': userId,
            'userName': userName,
            'rating': userRating,
            'timestamp': DateTime.now(),
          });

          final professorDoc = FirebaseFirestore.instance
              .collection('professors')
              .doc(widget.professor.id);
          final professorSnapshot = await professorDoc.get();

          if (professorSnapshot.exists) {
            final professorData =
            professorSnapshot.data() as Map<String, dynamic>;
            final List<dynamic> ratings = professorData['ratings'] ?? [];
            ratings.add(userRating);
            await professorDoc.update({'ratings': ratings});
          }

          Notifications.showPopUpMessage(
              context, 'Rating submitted successfully!');

          setState(() {
            alreadyRated = true;
          });
        } else {
          print('User not logged in');
        }
      } catch (error) {
        print('Error submitting rating: $error');
      }
    } else {
      print(
          '_submitRating(): User rating is below 0 or user already rated this professor.');
    }
  }

  void _removeRating() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final ratingQuerySnapshot = await FirebaseFirestore.instance
            .collection('professorsRatings')
            .where('professorId', isEqualTo: widget.professor.id)
            .where('userId', isEqualTo: userId)
            .get();

        if (ratingQuerySnapshot.docs.isNotEmpty) {
          final ratingDocId = ratingQuerySnapshot.docs.first.id;

          setState(() {
            allRatings.remove(userRating);
            alreadyRated = false;
          });

          await FirebaseFirestore.instance
              .collection('professorsRatings')
              .doc(ratingDocId)
              .delete();

          //get the list from the professor model and remove the
          //rating form there
          final professorDoc = FirebaseFirestore.instance
              .collection('professors')
              .doc(widget.professor.id);
          final professorSnapshot = await professorDoc.get();

          if (professorSnapshot.exists) {
            final professorData =
            professorSnapshot.data() as Map<String, dynamic>;
            final List<dynamic> ratings = professorData['ratings'] ?? [];
            ratings.remove(userRating);
            await professorDoc.update({'ratings': ratings});
            setState(() {
              userRating = 0;
              _calculateAverageRating();
            });

            Notifications.showPopUpMessage(
                context, 'Rating removed successfully!');
          }
        }
      } else {
        print('_removeRating(): User not logged in');
      }
    } catch (error) {
      print('_removeRating(): Error removing rating: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.professor.fullName),
        backgroundColor: Colors.cyan.shade200,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Add Rating',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(
                    widget.professor.photoUrl.toString(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (index) =>
                      IconButton(
                        icon: Icon(
                          index < userRating ? Icons.star : Icons.star_border,
                          color: index < userRating ? Colors.yellow : Colors
                              .grey,
                          size: 32,
                        ),
                        onPressed: () {
                          if (!alreadyRated) {
                            _updateRating(index + 1);
                          }
                        },
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Average Rating: ${averageRating.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (alreadyRated)
                ElevatedButton(
                  onPressed: () {
                    _removeRating();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red,
                  ),
                  child: const Text('Remove Rating'),
                ),
              if (!alreadyRated)
                ElevatedButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      _submitRating();
                    } else {
                      Navigator.of(context).pushNamed('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue, backgroundColor: Colors.white,
                  ),
                  child: const Text('Submit Rating'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _showDialogForAddingComments(context, widget, allComments);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, backgroundColor: Colors.white,
                ),
                child: const Text('Add Comment'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allComments.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> comment = allComments[index];
                    String userName =
                        comment['userName']! + ' - ' + comment['userEmail']!;
                    String userComment = comment['comment'] ?? '';
                    bool currentUserIsCommenter =
                        comment['userId'] == FirebaseAuth.instance.currentUser?.uid;
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        title: Text(userName),
                        subtitle: Text(userComment),
                        trailing: (currentUserIsCommenter || currentUserIsAdmin)
                            ? IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _removeComment(
                              comment['timestamp'],
                              userComment,
                              setState,
                            );
                          },
                        )
                            : null,
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}