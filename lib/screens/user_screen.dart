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
          Expanded(
            child: _buildUserPostsList(context),
          ),
        ],
      ),
    );
  }

  Widget UserProfileWidget({
    required BuildContext context,
    required String userEmail,
    required String profilePictureUrl,
    required String bio,
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

  Widget _buildUserPostsList(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<DocumentSnapshot> allPosts = snapshot.data!.docs;
          List<DocumentSnapshot> userPosts = [];

          // Filter posts to include only the user's own uploads
          for (var post in allPosts) {
            Map<String, dynamic>? postData =
                post.data() as Map<String, dynamic>?;

            if (postData != null && postData['userId'] == receiverUserID) {
              userPosts.add(post);
            }
          }

          if (userPosts.isEmpty) {
            return Center(
              child: Text('No posts yet.'),
            );
          }

          return ListView.builder(
            itemCount: userPosts.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> postData =
                  userPosts[index].data() as Map<String, dynamic>;

              return _buildUserPostItem(context, postData);
            },
          );
        } else {
          return Text('Error loading image.');
        }
      },
    );
  }

  Widget _buildUserPostItem(
      BuildContext context, Map<String, dynamic> postData) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the image
          postData.containsKey('imageUrl') && postData['imageUrl'] != null
              ? Image.network(
                  postData['imageUrl'],
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                )
              : SizedBox(), // If imageUrl is null or not available, display nothing
          SizedBox(height: 8),
          // Display the description
          Text(
            postData['description'] ?? '',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          // Display the timestamp (if needed)
          Text(
            '${postData['timestamp']}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Divider(), // Add a divider between posts
        ],
      ),
    );
  }
}
