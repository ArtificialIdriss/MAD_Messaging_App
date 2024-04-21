import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:messaging_app/auth/auth_page.dart';
import 'package:messaging_app/auth/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(messagingApp());
}

class messagingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      //start at auth page for auto sign in
      home: AuthPage(),
    );
  }
}
