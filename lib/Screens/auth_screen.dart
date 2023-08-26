import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

import '../Screens/home_page.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/sign_in_up';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginForm = true;

  void toggleFormMode() {
    setState(() {
      _isLoginForm = !_isLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF18122B),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).viewPadding.top,
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isLoginForm
                  ? LogInForm(toggleFormMode)
                  : SignUpForm(toggleFormMode),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(_isLoginForm ? 1.0 : -1.0, 0),
                  end: Offset(0, 0),
                ).animate(animation);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  final Function toggleFormMode;
  SignUpForm(this.toggleFormMode);
  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String mapFirebaseErrorToMessage(errorCode) {
    return "error";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
              "✔️ Sign Up",
              style: TextStyle(
                  fontSize: 50,
                  color: Color(0xFF18122B),
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
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
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Password',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Confirm Password',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
          ),
          _passwordController.text != '' &&
                  _confirmPasswordController.text != ''
              ? Container(
                  child: Column(
                  children: [
                    SizedBox(height: 10),
                    _passwordController.text == _confirmPasswordController.text
                        ? Text(
                            'Passwords Match',
                            style: TextStyle(color: Colors.green),
                          )
                        : Text(
                            'Passwords Do Not Match',
                            style: TextStyle(color: Colors.red),
                          ),
                    SizedBox(height: 20),
                  ],
                ))
              : SizedBox(height: 30),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          EdgeInsets.fromLTRB(50, 20, 50, 20)),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xFF636995))),
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    try {
                      if (email == "" || password == "") {
                        throw FirebaseAuthException(
                            code: "email_or_password_empty");
                      }
                      if (password != _confirmPasswordController.text) {
                        throw FirebaseAuthException(code: "password_mismatch");
                      }

                      // Use Firebase Auth to sign up
                      UserCredential result =
                          await _auth.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // Log in the user and navigate to the home screen
                      await _auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      Navigator.of(context)
                          .pushReplacementNamed(HomePage.routeName);
                    } catch (e) {
                      String errorMessage =
                          "An error occurred. Please try again.";

                      if (e is FirebaseAuthException) {
                        errorMessage = mapFirebaseErrorToMessage(e.code);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                        ),
                      );
                    }

                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
          TextButton(
            onPressed: () {
              widget.toggleFormMode();
            },
            child: Text(
              'Switch to Log In',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class LogInForm extends StatefulWidget {
  final Function toggleFormMode;
  LogInForm(this.toggleFormMode);
  @override
  _LogInFormState createState() => _LogInFormState();
}

class _LogInFormState extends State<LogInForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  String mapFirebaseErrorToMessage(errorCode) {
    switch (errorCode) {
      case "email_or_password_empty":
        return "Email or password cannot be empty.";
      case "channel-error":
        return "There was a problem establishing a connection. Please try again later.";
      case "invalid-email":
        return "The email address you provided is not in a valid format.";
      case "user-not-found" || "wrong-password":
        return "Invalid email or password. Please check your credentials.";
      case "too-many-requests":
        return "Access to this account has been temporarily disabled due to many failed login attempts. You can immediately restore it by resetting your password or you can try again later.";
      default:
        return "An error occurred. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          ),
          SizedBox(height: 20),
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
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Password',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          EdgeInsets.fromLTRB(50, 20, 50, 20)),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xFF636995))),
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    try {
                      if (email == "" || password == "") {
                        throw FirebaseAuthException(
                            code: "email_or_password_empty");
                      }
                      // Use Firebase Auth to sign in or sign up
                      UserCredential result =
                          await _auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      Navigator.of(context)
                          .pushReplacementNamed(HomePage.routeName);
                    } catch (e) {
                      String errorMessage =
                          "An error occurred. Please try again."; // Default message

                      // Check if e is an instance of FirebaseAuthException
                      if (e is FirebaseAuthException) {
                        errorMessage = mapFirebaseErrorToMessage(e.code);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            errorMessage,
                          ),
                        ),
                      );
                    }

                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: Text(
                    'Sign In',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
          TextButton(
            onPressed: () {
              widget.toggleFormMode();
            },
            child: Text(
              'Switch to Sign Up',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
