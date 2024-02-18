import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finkiaid/model/Subject.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/UserFinki.dart';
import '../notifications/Notifications.dart';

class SubjectMidTerms extends StatefulWidget {
  final Subject subject;

  const SubjectMidTerms(this.subject, {Key? key}) : super(key: key);

  @override
  State<SubjectMidTerms> createState() => _SubjectMidTermsState();
}

class _SubjectMidTermsState extends State<SubjectMidTerms> {
  List<Map<String, dynamic>> allImages = [];
  MidTermTypeImage? selectedType;
  bool isLoggedIn = false;
  bool currentUserIsAdmin = false;

  @override
  void initState() {
    super.initState();
    _updateAuthState();
    _getAllImages();
  }

  void _updateAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() async {
        isLoggedIn = user != null;
        currentUserIsAdmin = await UserFinki.checkCurrentUserIsAdmin();
      });
    });
  }

  void _getAllImages() async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('subjectImages')
          .where("subjectName", isEqualTo: widget.subject.name)
          .get();
      List<Map<String, String>> images = [];

      querySnapshot.docs.forEach((doc) {
        print("");
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        dynamic timestampData = data['timestamp'];
        Timestamp timestamp;
        if (timestampData is Timestamp) {
          timestamp = timestampData;
        } else {
          timestamp = Timestamp.fromDate(DateTime.parse(timestampData));
        }
        String formattedTimestamp = timestamp.toDate().toString();
        Map<String, String> imageMap = {
          'subjectId': data['subjectId'],
          'subjectName': data['subjectName'],
          'userId': data['userId'],
          'userName': data['userName'],
          'userEmail': data['userEmail'],
          'imageUrl': data['imageUrl'],
          'timestamp': formattedTimestamp,
          'imageType': data['imageType']
        };

        images.add(imageMap);
      });

      setState(() {
        allImages = images;
      });

      // // final subjectSnapshot = await subjectDoc.get();
      // final subjectSnapshot = null;
      //
      // if (subjectSnapshot.exists) {
      //   final subjectData = subjectSnapshot.data() as Map<String, dynamic>;
      //   final Map<String, dynamic> images = subjectData['images'] ?? [];
      //
      //   List<File> loadedImages = [];
      //
      //   for (var imageList in images.values) {
      //     if (imageList is List<dynamic>) {
      //       for (var imageUrl in imageList) {
      //         if (imageUrl is String) {
      //           loadedImages.add(File(imageUrl));
      //         }
      //       }
      //     }
      //   }
      //   setState(() {
      //     allImages = loadedImages;
      //   });
      // }
    } catch (error) {
      print('_getAllImages(): Error retrieving images: $error');
    }
  }

  void _addImage(File image) async {
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
          userName = '${userData["name"] + userData["surname"]}';
        }

        final String imageUrl = image.path;
        final String imageTypeKey = _getImageTypeKey(selectedType);

        Map<String, dynamic> midTermImageData = {
          'subjectId': widget.subject.id,
          'subjectName': widget.subject.name,
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'imageUrl': imageUrl,
          'imageType': imageTypeKey,
          'timestamp': DateTime.now().toString(),
        };

        Map<String, String> imageMap = midTermImageData.cast<String, String>();

        final subjectDoc = FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subject.id);
        final subjectSnapshot = await subjectDoc.get();

        if (subjectSnapshot.exists) {
          final subjectData = subjectSnapshot.data() as Map<String, dynamic>;
          Map<String, dynamic> images = subjectData["images"] ?? {};

          if (images.containsKey(imageTypeKey)) {
            images[imageTypeKey]!.add(imageUrl);
          } else {
            images[imageTypeKey] = [imageUrl];
          }

          await subjectDoc.update({'images': images});
        }

        await FirebaseFirestore.instance
            .collection('subjectImages')
            .add(imageMap);

        setState(() {
          allImages.add(imageMap);
        });
      } else {
        print('addImage(): User not logged in');
      }
    } catch (error) {
      print('Error submitting image: $error');
    }
  }

  String _getImageTypeKey(dynamic type) {
    if (type is MidTermTypeImage) {
      return type == MidTermTypeImage.first
          ? 'MidTerm - first'
          : 'MidTerm - second';
    } else if (type is ExamSessionTypeImage) {
      switch (type) {
        case ExamSessionTypeImage.january:
          return 'ExamSession - january';
        case ExamSessionTypeImage.june:
          return 'ExamSession - june';
        case ExamSessionTypeImage.august:
          return 'ExamSession - august';
      }
    }
    throw Exception('Invalid image type');
  }

  void _removeImage(String imageTimestamp, String userImage, String imageType,
      StateSetter setState) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final imageQuerySnapshot = await FirebaseFirestore.instance
            .collection('subjectImages')
            .where('subjectId', isEqualTo: widget.subject.id)
            .where('timestamp', isEqualTo: imageTimestamp)
            .get();

        if (imageQuerySnapshot.docs.isNotEmpty) {
          final imageDocId = imageQuerySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('subjectImages')
              .doc(imageDocId)
              .delete();

          final subjectDoc = FirebaseFirestore.instance
              .collection('subjects')
              .doc(widget.subject.id);
          final subjectSnapshot = await subjectDoc.get();

          if (subjectSnapshot.exists) {
            final subjectData = subjectSnapshot.data() as Map<String, dynamic>;
            final Map<String, dynamic> images = subjectData['images'] ?? {};

            if (images.containsKey(imageType)) {
              final List<String> imageList =
                  List<String>.from(images[imageType]);
              imageList.removeWhere((image) => image == userImage);
              images[imageType] = imageList;

              await subjectDoc.update({'images': images});

              // Notify user of successful image removal
              Notifications.showPopUpMessage(
                  context, 'Image removed successfully!');
            }
          }

          setState(() {
            allImages.removeWhere((image) =>
                image['timestamp'] == imageTimestamp &&
                image['imageUrl'] == userImage &&
                image['imageType'] == imageType);
          });
        }
      } else {
        print('_removeComment(): User not logged in');
      }
    } catch (error) {
      print('_removeComment(): Error removing comment: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mid-term: ${widget.subject.name}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(
                            File(allImages[index]['imageUrl']),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: allImages[index]['userId'] == FirebaseAuth.instance.currentUser?.uid ||
                            currentUserIsAdmin
                            ? IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () async {
                            String userImage = allImages[index]['imageUrl'];
                            String imageType = allImages[index]['imageType'];
                            String imageTimestamp = allImages[index]['timestamp'];

                            _removeImage(imageTimestamp, userImage, imageType, setState);
                          },
                        )
                            : SizedBox()
                      ),
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (isLoggedIn) {
            Map<Permission, PermissionStatus> statuses = await [
              Permission.storage,
              Permission.camera,
            ].request();
            if (statuses[Permission.storage]!.isGranted &&
                statuses[Permission.camera]!.isGranted) {
              showImagePicker(context);
            } else {
              print('no permission provided');
            }
          } else {
            Navigator.of(context).pushNamed('/login');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  final picker = ImagePicker();

  void showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Wrap with StatefulBuilder
            return Card(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 4,
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButton<MidTermTypeImage>(
                      value: selectedType,
                      hint: const Text('Select which Mid Term'),
                      onChanged: (MidTermTypeImage? newValue) {
                        setState(() {
                          selectedType = newValue;
                        });
                      },
                      items:
                          MidTermTypeImage.values.map((MidTermTypeImage type) {
                        return DropdownMenuItem<MidTermTypeImage>(
                          value: type,
                          child: Text(type.toString().split('.')[1]),
                        );
                      }).toList(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            child: const Column(
                              children: [
                                Icon(Icons.image, size: 60.0),
                                SizedBox(height: 12.0),
                                Text(
                                  "Gallery",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                )
                              ],
                            ),
                            onTap: () {
                              if (selectedType != null) {
                                _imgFromGallery();
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            child: const SizedBox(
                              child: Column(
                                children: [
                                  Icon(Icons.camera_alt, size: 60.0),
                                  SizedBox(height: 12.0),
                                  Text(
                                    "Camera",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  )
                                ],
                              ),
                            ),
                            onTap: () {
                              if (selectedType != null) {
                                _imgFromCamera();
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    // Text('Selected mid-term: ${selectedType == MidTermTypeImage.first ? "First" : "Second"}')
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  _imgFromGallery() async {
    await picker
        .pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    )
        .then((value) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
  }

  _imgFromCamera() async {
    await picker
        .pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    )
        .then((value) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
  }

  _cropImage(File imgFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imgFile.path,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "Image Cropper",
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: "Image Cropper",
        ),
      ],
    );
    if (croppedFile != null) {
      _addImage(File(croppedFile.path));
      Notifications.showPopUpMessage(context, 'Successfully uploaded image');
    }
  }
}
