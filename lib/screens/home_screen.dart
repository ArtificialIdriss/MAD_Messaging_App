import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mad_artfolio_app/auth/auth_page.dart';
import 'package:mad_artfolio_app/screens/user_screen.dart';

// Define _auth as an instance of FirebaseAuth
final FirebaseAuth _auth = FirebaseAuth.instance;

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

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add New Item"),
          content: Text("Are you sure you want to add a new item?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Closes the dialog
              },
            ),
            TextButton(
              child: Text("Confirm"),
              onPressed: () {
                // Perform actions to add new item
                Navigator.of(context).pop(); // Closes the dialog
              },
            ),
          ],
        );
      },
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
