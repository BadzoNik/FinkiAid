import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finkiaid/model/Subject.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as Path;

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
  MidTermTypeImage? selectedMidTermType;
  bool isLoggedIn = false;
  bool currentUserIsAdmin = false;
  CollectionReference? imgRef;
  firebase_storage.Reference? ref;
  String? lastUploadedImageWithDownloadableURL;

  @override
  void dispose() {
    FirebaseAuth.instance.authStateChanges().listen(null);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updateAuthState();
    _checkUserIsAdmin();
    _getAllImages();
    // _getAllImages2();
    imgRef = FirebaseFirestore.instance.collection('imageURLs');
  }

  void _checkUserIsAdmin() async {
    bool isAdmin = await UserFinki.checkCurrentUserIsAdmin();

    setState(() {
      currentUserIsAdmin = isAdmin;
    });
  }

  void _updateAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user)  {
      bool loggedIn = user != null;

      setState(() {
        isLoggedIn = loggedIn;
      });
    });
  }


  void _getAllImages2() async {
    String folderName = '';
    if (selectedMidTermType == MidTermTypeImage.first) {
      folderName = 'MidTerm-first';
    } else if (selectedMidTermType == MidTermTypeImage.second) {
      folderName = 'MidTerm-second';
    } else {
      return;
    }

    firebase_storage.Reference folderRef =
    firebase_storage.FirebaseStorage
        .instance.ref().child('images/$folderName');

    try {
      firebase_storage.ListResult result = await folderRef.listAll();
      List<Map<String, String>> images = [];

      for (firebase_storage.Reference ref in result.items) {
        String downloadURL = await ref.getDownloadURL();

        Map<String, String> imageMap = {

          'imageUrl': downloadURL,
          'imageType': folderName,
        };

        images.add(imageMap);
      }

      setState(() {
        allImages = images;
      });
    } catch (error) {
      // Handle any errors that occur during the retrieval process
      print('Error retrieving images: $error');
    }
  }



  void _getAllImages() async {
    try {
      final List<String> midTermTypes = [
        for (var type in widget.subject.images.keys)
          if (type.toString().contains("MidTerm")) type
      ];

      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('subjectImages')
          .where("subjectName", isEqualTo: widget.subject.name)
          .where("imageType", whereIn: midTermTypes)
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
        final String imageTypeKey = _getImageTypeKey(selectedMidTermType);


        Map<String, dynamic> midTermImageData = {
          'subjectId': widget.subject.id,
          'subjectName': widget.subject.name,
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'imageUrl': lastUploadedImageWithDownloadableURL,
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
            images[imageTypeKey]!.add(lastUploadedImageWithDownloadableURL);
          } else {
            images[imageTypeKey] = [lastUploadedImageWithDownloadableURL];
          }

          await subjectDoc.update({'images': images});
        }

        await FirebaseFirestore.instance
            .collection('subjectImages')
            .add(imageMap);

        // Map<dynamic, List<String>> newImages =
        //     Subject.convertToImagesMap(midTermImageData);
        _fetchImagesFromFirebase();
        setState(() {
          allImages.add(imageMap);
          // widget.subject.setImages(newImages);
        });
        Notifications.showPopUpMessage(context, 'Successfully uploaded image');
      } else {
        print('addImage(): User not logged in');
      }
    } catch (error) {
      print('Error submitting image: $error');
    }
  }


  void _fetchImagesFromFirebase() async {
    try {
      // Query the subjects collection for the document with the specified subject ID
      final DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subject.id)
          .get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        // Extract the images field from the document
        Map<String, List<dynamic>> images =
        Map.from(documentSnapshot.get('images'));

        // Update the state with the fetched images
        setState(() {
          widget.subject.setImages(images);
        });
      } else {
        print('Document does not exist for subject ID: ${widget.subject.id}');
      }
    } catch (error) {
      print('Error fetching images from Firebase: $error');
    }
  }

  String _getImageTypeKey(dynamic type) {
    if (type is MidTermTypeImage) {
      return type == MidTermTypeImage.first
          ? 'MidTerm-first'
          : 'MidTerm-second';
    } else if (type is ExamSessionTypeImage) {
      switch (type) {
        case ExamSessionTypeImage.january:
          return 'ExamSession-January';
        case ExamSessionTypeImage.june:
          return 'ExamSession-June';
        case ExamSessionTypeImage.august:
          return 'ExamSession-August';
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
          deleteImageFromFirebaseStorage(imageType, userImage);


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

  Future<void> deleteImageFromFirebaseStorage(String imageType, String userImage) async {
    String cleanedImageType = imageType.replaceAll(' - ', '-');

    Uri uri = Uri.parse(userImage);
    String imageUri = uri.pathSegments.last;
    String imageName = imageUri.split("/")[2];
    firebase_storage.Reference folderRef =
    firebase_storage.FirebaseStorage.instance.ref().child('images/$cleanedImageType');

    try {
      firebase_storage.ListResult result = await folderRef.listAll();
      for (firebase_storage.Reference ref in result.items) {
        print('Item name: ${ref.name}');

        if (ref.name == imageName) {
          await ref.delete();
          print('Image ${ref.name} deleted successfully.');
        }
      }
    } catch (error) {
      print('Error retrieving data: $error');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan.shade200,
        title: Text('Mid-term: ${widget.subject.name}'),
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
          children: [
            if (pickedFile != null)
              Card(
                color: Colors.white, // Set the background color to white
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2.0), // Set border properties
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Image.file(
                    File(pickedFile!.path!),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                shrinkWrap: true, // Set shrinkWrap to true
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white, // Set the background color to white
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.0), // Set border properties
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Image.network(
                              allImages[index]['imageUrl'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  );
                                }
                              },
                              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                return Text('Error loading image');
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: allImages[index]['userId'] == FirebaseAuth.instance.currentUser?.uid ||
                                currentUserIsAdmin
                                ? IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.blue.shade500,
                              onPressed: () async {
                                String userImage = allImages[index]['imageUrl'];
                                String imageType = allImages[index]['imageType'];
                                String imageTimestamp = allImages[index]['timestamp'];

                                _removeImage(imageTimestamp, userImage, imageType, setState);
                              },
                            )
                                : SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
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
                      value: selectedMidTermType,
                      hint: const Text('Select which Mid Term'),
                      onChanged: (MidTermTypeImage? newValue) {
                        setState(() {
                          selectedMidTermType = newValue;
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
                              if (selectedMidTermType != null) {
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
                              if (selectedMidTermType != null) {
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

  PlatformFile? pickedFile;
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
    // final result = await FilePicker.platform.pickFiles();
    // if(result == null) return;
    // setState(() {
    //   pickedFile = result.files.first;
    // });
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

  // PlatformFile fileToPlatformFile(File file) {
  //   String path = file.path;
  //   String name = file.path.split('/').last; // Extract the file name from the path
  //   int size = file.lengthSync();
  //   ByteData byteData = file.readAsBytesSync().buffer.asByteData(); // Read file as bytes
  //   List<int> bytes = byteData.buffer.asUint8List(); // Convert ByteData to Uint8List
  //
  //   return PlatformFile(
  //     name: name,
  //     path: path,
  //     size: size,
  //     bytes: bytes,
  //   );
  // }

  _cropImage(File imgFile) async { //PlatformFile
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
    String folderName = '';
    if (selectedMidTermType == MidTermTypeImage.first) {
      folderName = 'MidTerm-first';
    } else if (selectedMidTermType == MidTermTypeImage.second) {
      folderName = 'MidTerm-second';
    } else {
      return;
    }

    ref = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('images/$folderName/${Path.basename(imageFile.path)}');

    try {
      // Upload image to Firebase Storage
      await ref?.putFile(imageFile);

      String downloadURL = await ref!.getDownloadURL();

      // Add image URL to Firestore (unnecessary)
      // await imgRef?.add({'url': downloadURL});

      setState(() {
        lastUploadedImageWithDownloadableURL = downloadURL;
        //it must be here in order to have the `downloadURL` in `lastUploadedImageWithDownloadableURL`
        //for adding the `lastUploadedImageWithDownloadableURL` inside firebase firestore
        _addImage(imageFile);
      });
    } catch (error) {
      print('Error uploading image: $error');
    }
  }

}
