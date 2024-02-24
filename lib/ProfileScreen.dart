import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'FullScreenImageView.dart';
import 'notifications/Notifications.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool isLoggedIn = false;
  var loggedInUserData = {};

  PlatformFile? pickedFile;
  firebase_storage.Reference? ref;
  String lastUploadedImageWithDownloadableURL = "";
  final picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _updateAuthState();
    _fetchLoggedInUserInfo();
    _fetchExistingImage();
  }

  void _fetchExistingImage() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        // Get user data from Firestore
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          final userData = userSnapshot.docs.first;
          setState(() {
            lastUploadedImageWithDownloadableURL =
              userData["userImage"];
          });
        }
      }
    } catch (error) {
      print('Error fetching existing image: $error');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchExistingImage();
  }

  void _updateAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        isLoggedIn = user != null;
      });
    });
  }

  void _fetchLoggedInUserInfo() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: userId)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first;

        final user = {
          "userId": userData["id"],
          "userName": userData["name"],
          "userSurname": userData["surname"],
          "userEmail": userData["email"],
          "userRole": userData["role"]
        };

        setState(() {
          loggedInUserData = user;
        });
      }
    } catch (error) {
      print("_fetchLoggedInUserInfo(): $error");
    }
  }

  void showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Card(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 4,
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            child: const Column(
                              children: [
                                Icon(Icons.image, size: 40.0),
                                SizedBox(height: 8.0),
                                Text(
                                  "Gallery",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                )
                              ],
                            ),
                            onTap: () {
                              _imgFromGallery();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            child: const SizedBox(
                              child: Column(
                                children: [
                                  Icon(Icons.camera_alt, size: 40.0),
                                  SizedBox(height: 8.0),
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
                              _imgFromCamera();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (lastUploadedImageWithDownloadableURL != "")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: InkWell(
                              child: const Column(
                                children: [
                                  Icon(Icons.remove_circle, size: 40.0),
                                  SizedBox(height: 8.0),
                                  Text(
                                    "Remove Image",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  )
                                ],
                              ),
                              onTap: () {
                                _removeProfileImage();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              child: const SizedBox(
                                child: Column(
                                  children: [
                                    Icon(Icons.fullscreen, size: 40.0),
                                    SizedBox(height: 8.0),
                                    Text(
                                      "View Full Image",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    )
                                  ],
                                ),
                              ),
                              onTap: () {
                                _viewFullImage(context);
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

  }

  void _removeProfileImage() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var docId = userSnapshot.docs.first.id;
          Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;

          userData['userImage'] = "";

          final userDoc = FirebaseFirestore.instance.collection('users').doc(docId);

          await userDoc.update(userData);

          String folderName = 'profile_images/$userId'; // Set the folder name to include the user's ID

          firebase_storage.Reference folderRef =
          firebase_storage.FirebaseStorage.instance.ref().child(folderName);

          try {
            var items = await folderRef.listAll();
            for (var item in items.items) {
              await item.delete();
            }
          } catch (error) {
            print('Error checking/deleting existing image: $error');
          }

          setState(() {
            lastUploadedImageWithDownloadableURL = "";
          });

          Notifications.showPopUpMessage(context, 'Successfully removed image');
        } else {
          print('User document not found');
        }
      } else {
        print('addImage(): User not logged in');
      }
    } catch (error) {
      print('Error removing user image: $error');
    }
  }

  void _viewFullImage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageUrl: lastUploadedImageWithDownloadableURL!),
      ),
    );
  }


  void _imgFromGallery2() async {
    await picker
        .pickImage(
      source: ImageSource.gallery,
      imageQuality: 5,
    )
        .then((value) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
  }

  _imgFromGallery() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    setState(() {
      pickedFile = result.files.first;
    });

    if(pickedFile != null) {
      _cropImage(File(pickedFile!.path!));
    }
  }


  void _imgFromCamera() async {
    await picker
        .pickImage(
      source: ImageSource.camera,
      imageQuality: 5,
    )
        .then((value) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
  }

  void _cropImage(File imgFile) async { //PlatformFile
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imgFile!.path!,
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
      _uploadImage(File(croppedFile.path));
    }
  }

  void _uploadImage(File imageFile) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      String folderName = 'profile_images/$userId';

      firebase_storage.Reference folderRef =
      firebase_storage.FirebaseStorage.instance.ref().child(folderName);

      try {
        var items = await folderRef.listAll();
        for (var item in items.items) {
          await item.delete();
        }
      } catch (error) {
        print('Error checking/deleting existing image: $error');
      }

      firebase_storage.Reference imageRef =
      folderRef.child(Path.basename(imageFile.path));

      try {
        await imageRef.putFile(imageFile);

        String downloadURL = await imageRef.getDownloadURL();

        setState(() {
          lastUploadedImageWithDownloadableURL = downloadURL;
          _addImage(imageFile);
        });
      } catch (error) {
        print('Error uploading image: $error');
      }
    } else {
      print('User not logged in');
    }
  }

  void _addImage(File image) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var docId = userSnapshot.docs.first.id;
          // Get all data of the user document
          Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;

          userData['userImage'] = lastUploadedImageWithDownloadableURL;

          final userDoc = FirebaseFirestore.instance.collection('users').doc(docId);

          await userDoc.update(userData);

          setState(() {
          });

          Notifications.showPopUpMessage(context, 'Successfully uploaded image');
        } else {
          print('User document not found');
        }

      } else {
        print('addImage(): User not logged in');
      }
    } catch (error) {
      print('Error updating user image: $error');
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan.shade200,
        title: const Text('User profile'),
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  _firebaseAuth.signOut();
                  setState(() {
                    isLoggedIn = false;
                  });
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.person_rounded),
              ),
              const SizedBox(width: 16),
              if (isLoggedIn)
                ElevatedButton(
                  onPressed: () {
                    _firebaseAuth.signOut();
                    setState(() {
                      isLoggedIn = false;
                    });
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    backgroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Logout',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
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
              },
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: lastUploadedImageWithDownloadableURL != ""
                      ? Image.network(
                    lastUploadedImageWithDownloadableURL!,
                    height: 160, // Double the radius to cover the full circle
                    width: 160, // Double the radius to cover the full circle
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    "assets/add_photo_png_2.webp",
                    height: 160, // Double the radius to cover the full circle
                    width: 160, // Double the radius to cover the full circle
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 2500,
              child: Text(
                'Id: ${loggedInUserData["userId"]}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 250,
              child: Text(
                'Name: ${loggedInUserData["userName"]}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 250,
              child: Text(
                'Surname: ${loggedInUserData["userSurname"]}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 2500,
              child: Text(
                'Role: ${loggedInUserData["userRole"]}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 2500,
              child: Text(
                'Email: ${loggedInUserData["userEmail"]}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Your other content goes here
          ],
        ),
      ),
    );
  }
}