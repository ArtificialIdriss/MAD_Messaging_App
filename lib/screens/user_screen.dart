import 'package:flutter/material.dart';

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Email: $receiverUserEmail',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'UID: $receiverUserID',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
