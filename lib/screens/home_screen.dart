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
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // sign user out
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
    );
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
}
