import 'package:mad_artfolio_app/screens/home_screen.dart';
import 'package:mad_artfolio_app/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //user IS logged in
          if (snapshot.hasData) {
            return HomeScreen();
          }
          //user is NOT logged in
          else {
            return SignInScreen();
          }
        },
      ),
    );
  }
}
