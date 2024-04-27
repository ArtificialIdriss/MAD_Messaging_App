import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mad_artfolio_app/auth/auth_page.dart';
import 'package:mad_artfolio_app/screens/user_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'dart:html' as html;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<String> uploadImage(XFile image) async {
  FirebaseStorage storage = FirebaseStorage.instance;
  String filePath =
      'uploads/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
  Reference ref = storage.ref().child(filePath);

  UploadTask uploadTask = ref.putData(
      await image.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
  TaskSnapshot taskSnapshot = await uploadTask;
  String imageUrl = await taskSnapshot.ref.getDownloadURL();
  return imageUrl;
}

Future<void> createPost(String imageUrl, String description) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var userId = FirebaseAuth.instance.currentUser?.uid;

  await firestore.collection('posts').add({
    'userId': userId,
    'imageUrl': imageUrl,
    'description': description,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

// Define _auth as an instance of FirebaseAuth
final FirebaseAuth _auth = FirebaseAuth.instance;

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUserPost(
      String userId, String imageUrl, String description) async {
    var postCollection =
        _db.collection('users').doc(userId).collection('posts');
    var timestamp = FieldValue.serverTimestamp(); // Get server-side timestamp

    await postCollection.add({
      'imageUrl': imageUrl,
      'description': description,
      'timestamp': timestamp,
    });
  }
}

void _showAddDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) => ImageUploadDialog(),
  );
}

class ImageUploadDialog extends StatefulWidget {
  @override
  _ImageUploadDialogState createState() => _ImageUploadDialogState();
}

class _ImageUploadDialogState extends State<ImageUploadDialog> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  Image? _previewImage;
  TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final buffer = bytes.buffer;
        String img64 = base64.encode(Uint8List.view(buffer));
        String imgUrl = 'data:image/png;base64,$img64';

        setState(() {
          _imageFile = pickedFile;
          _previewImage = Image.network(imgUrl, fit: BoxFit.cover);
        });
      } else {
        print('No file selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Upload Photo"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text("Choose a photo to upload from your Photo Library"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            if (_previewImage != null) ...[
              SizedBox(height: 20),
              Container(
                width: 300,
                height: 300,
                child: _previewImage,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ]
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text("Confirm"),
          onPressed: () async {
            if (_imageFile != null) {
              try {
                String imageUrl = await uploadImage(_imageFile!);
                await createPost(imageUrl, _descriptionController.text);
                Navigator.of(context).pop(); // Closes the dialog
              } catch (e) {
                print('Error during upload or post creation: $e');
                // Show a detailed error message
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            } else {
              print('No image file selected.');
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('No image selected. Please pick an image first.')));
            }
          },
        ),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HomeScreen'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthPage()),
              );
            },
          ),
        ],
      ),
      body: _buildUserList(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundImage:
                  NetworkImage('https://example.com/user_image.png'),
              radius: 15,
            ),
            label: 'Profile',
          ),
        ],
        onTap: (int index) {
          switch (index) {
            case 0:
              // Navigate to home page
              MaterialPageRoute(builder: (context) => AuthPage());
              break;
            case 1:
              // Show a dialog pop-up
              _showAddDialog(context);
              break;
            case 2:
              _navigateToCurrentUserProfile(context);
              break;
          }
        },
      ),
    );
  }

  void _navigateToCurrentUserProfile(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .then((userDoc) {
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data()!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserPage(
                receiverUserEmail: userData['email'],
                receiverUserID: currentUser.uid,
              ),
            ),
          );
        }
      });
    }
  }
}

// build a list of users except for the current log
Widget _buildUserList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('users').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text('error');
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text('loading...');
      }
      return ListView(
          children: snapshot.data!.docs
              .map<Widget>(
                (doc) => _buildUserListItem(context, doc),
              )
              .toList());
    },
  );
}

//build individual user list items
Widget _buildUserListItem(BuildContext context, DocumentSnapshot document) {
  Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

  //display all users except current users
  if (_auth.currentUser!.email != data['email']) {
    return ListTile(
      title: Text(data['email']),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserPage(
                receiverUserEmail: data['email'],
                receiverUserID: data['uid'],
              ),
            ));
      },
    );
  } else {
    return Container();
  }
}

// Navigation function to user page
void _navigateToUserPage(BuildContext context, Map<String, dynamic> userData) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => UserPage(
        receiverUserEmail: userData['email'],
        receiverUserID: userData['uid'],
      ),
    ),
  );
}
