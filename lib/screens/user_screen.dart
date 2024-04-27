import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPage extends StatelessWidget {
  final String receiverUserEmail;
  final String receiverUserID;

  const UserPage({
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(receiverUserID)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                Map<String, dynamic> userData =
                    snapshot.data!.data() as Map<String, dynamic>;
                String profilePictureUrl = userData['profilePicture'] ?? '';

                return UserProfileWidget(
                  context: context,
                  userEmail: receiverUserEmail,
                  profilePictureUrl: profilePictureUrl,
                  bio: userData['bio'] ?? '',
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
          ),
        ],
      ),
    );
  }

  Widget UserProfileWidget({
    required String userEmail,
    required String profilePictureUrl,
    required String bio, // Add bio parameter
    required BuildContext context,
  }) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[300],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey,
                        backgroundImage: profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl)
                            : null,
                        child: profilePictureUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 20),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final updatedBio = await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Edit Bio'),
                          content: TextFormField(
                            maxLength: 100,
                            initialValue:
                                bio, // Display current bio in the dialog
                            decoration: InputDecoration(
                              hintText: 'Enter your bio (max 100 characters)',
                            ),
                            onChanged: (value) {
                              bio = value;
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, bio);
                              },
                              child: Text('Save'),
                            ),
                          ],
                        );
                      },
                    );

                    if (updatedBio != null) {
                      // Update Firestore with the edited bio
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(receiverUserID)
                          .update({'bio': updatedBio});
                    }
                  },
                  child: Text('Edit Bio'),
                ),
                SizedBox(height: 20),
                Text(
                  'Bio: $bio', // Display user's bio
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
