import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finkiaid/model/Subject.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/FavoriteSubject.dart';
import '../notifications/Notifications.dart';
import 'SubjectDetailScreen.dart';

class FavoriteSubjectsScreen extends StatefulWidget {
  const FavoriteSubjectsScreen({super.key});

  @override
  State<FavoriteSubjectsScreen> createState() => _FavoriteSubjectsScreenState();
}

class _FavoriteSubjectsScreenState extends State<FavoriteSubjectsScreen> {
  List<FavoriteSubject> favoriteSubjects = [];

  @override
  void initState() {
    super.initState();
    _fetchFavoriteSubjects();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchFavoriteSubjects();
  }




  void _fetchFavoriteSubjects() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('favoriteSubjects')
          .where('userId', isEqualTo: user?.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<FavoriteSubject> tempSubjects = [];

        snapshot.docs.forEach((doc) {
          var subjectId = doc['subjectId'];
          var subjectName = doc['subjectName'];
          var userId = doc['userId'];
          var userName = doc['userName'];
          var userEmail = doc['userEmail'];

          FavoriteSubject subject = FavoriteSubject(
            subjectId: subjectId,
            subjectName: subjectName,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
          );
          tempSubjects.add(subject);
        });

        setState(() {
          favoriteSubjects = tempSubjects;
        });
      } else {
        setState(() {
          favoriteSubjects = [];
        });
      }

    } catch (error) {
      print('_fetchFavoriteSubjects(): Error: $error');
    }
  }

  void _removeFavoriteSubject(Subject subject) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteRef = FirebaseFirestore.instance
            .collection('favoriteSubjects')
            .where('userId', isEqualTo: user.uid)
            .where('subjectId', isEqualTo: subject.id);

        final existingFavorite = await favoriteRef.get();

        if (existingFavorite.docs.isNotEmpty) {
          await existingFavorite.docs.first.reference.delete();
          setState(() {
            // favoriteSubjects.remove(
            //     subject);
            favoriteSubjects.removeWhere((element) => element.subjectId == subject.id);
          });
          Notifications.showPopUpMessage(
            context,
            '${subject.name}',
          );
        }
      }
    } catch (error) {
      print('Error removing favorite subject: $error');
    }
  }

  Future<Map<dynamic, List<dynamic>>> _getAllImages(FavoriteSubject subject) async {
    final user = FirebaseAuth.instance.currentUser;
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('subjects')
        .where('id', isEqualTo: subject.subjectId)
        .where('name', isEqualTo: subject.subjectName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final subjectData = snapshot.docs.first.data() as Map<String, dynamic>;
      if (subjectData != null && subjectData['images'] is Map<String, dynamic>) {
        final imagesMap = subjectData['images'] as Map<String, dynamic>;

        // Convert Map<String, dynamic> to Map<dynamic, List<dynamic>>
        final images = imagesMap.map((key, value) => MapEntry<dynamic, List<dynamic>>(key, value as List<dynamic>));

        if (images != null) {
          return images;
        }
      }
    }
    return {};
  }


  Future<List<String>> _getAllComments(FavoriteSubject subject) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('id', isEqualTo: subject.subjectId)
          .where('name', isEqualTo: subject.subjectName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final subjectData = snapshot.docs.first.data() as Map<String, dynamic>;
        if (subjectData != null) {
          final List<dynamic> dynamicComments = subjectData['comments'] ?? [];
          final List<String> comments = dynamicComments.map((comment) => comment.toString()).toList();
          return comments;
        }
      }
      return [];
    } catch (error) {
      print('_getAllComments(): Error: $error');
      return [];
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Subjects'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.cyan.shade200, Colors.blue.shade500],
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: favoriteSubjects.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<Map<dynamic, List<dynamic>>>(
                    future: _getAllImages(favoriteSubjects[index]),
                    builder: (context, imageSnapshot) {
                      if (imageSnapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // or some loading indicator
                      } else if (imageSnapshot.hasError) {
                        return Text('Error: ${imageSnapshot.error}');
                      } else {
                        final allImages = imageSnapshot.data ?? {};

                        return FutureBuilder<List<String>>(
                          future: _getAllComments(favoriteSubjects[index]),
                          builder: (context, commentSnapshot) {
                            if (commentSnapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator(); // or some loading indicator
                            } else if (commentSnapshot.hasError) {
                              return Text('Error: ${commentSnapshot.error}');
                            } else {
                              final allComments = commentSnapshot.data ?? [];
                              final subject = Subject(
                                id: favoriteSubjects[index].subjectId,
                                name: favoriteSubjects[index].subjectName,
                                images: allImages,
                                comments: allComments,
                              );

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubjectDetailScreen(
                                        subject: subject,
                                        callerIsFavoriteSubjects: true,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: ListTile(
                                    leading: Icon(Icons.subject),
                                    title: Text(
                                      subject.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // subtitle: Text(
                                    //   'User: ${favoriteSubjects[index].userName}',
                                    //   style: TextStyle(
                                    //     fontSize: 14,
                                    //   ),
                                    // ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete_outline_rounded),
                                      onPressed: () {
                                        _removeFavoriteSubject(subject);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }
                    },
                  );
                },
                separatorBuilder: (context, index) {
                  return SizedBox(height: 8);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

}
