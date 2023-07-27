import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../Screens/home_page.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/sign_in_up';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF18122B),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).viewPadding.top,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                      color: Color(0xFF636995),
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  margin: EdgeInsets.all(5.0),
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "✔️ Log in",
                    style: TextStyle(
                        fontSize: 50,
                        color: Color(0xFF18122B),
                        fontWeight: FontWeight.bold),
                  ),
                  // child: Image.asset(
                  //     'assets/logo.png'), // Replace with your logo image path
                ),
                SizedBox(height: 20),
                SignInSignUpForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignInSignUpForm extends StatefulWidget {
  @override
  _SignInSignUpFormState createState() => _SignInSignUpFormState();
}

class _SignInSignUpFormState extends State<SignInSignUpForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Email',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ButtonStyle(
                padding: MaterialStateProperty.all<EdgeInsets>(
                    EdgeInsets.fromLTRB(50, 20, 50, 20)),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF636995))),
            onPressed: () async {
              String email = _emailController.text.trim();
              String password = _passwordController.text.trim();

              try {
                // Use Firebase Auth to sign in or sign up
                UserCredential result = await _auth.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                Navigator.of(context).pushReplacementNamed(HomePage.routeName);
              } catch (e) {
                // Handle sign-in errors here
                print('Error: $e');
              }
            },
            child: Text(
              'Sign In',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
