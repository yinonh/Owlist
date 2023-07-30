import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import './Screens/home_page.dart';
import './Screens/single_list_screen.dart';
import './Screens/sign_in_sign_up_screen.dart';
import './Providers/lists_provider.dart';
import './Providers/item_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ListsProvider()),
        ChangeNotifierProvider(create: (context) => ItemProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Widget initialScreen;

  @override
  void initState() {
    super.initState();
    User? currentUser = FirebaseAuth.instance.currentUser;
    initialScreen = LoginScreen();
    if (currentUser != null) {
      initialScreen = HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor:
            Colors.white, // Color for app bar and other primary elements
        scaffoldBackgroundColor: Colors.transparent,

        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: Color(0xFF636995),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.white),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Colors.white,
          unselectedItemColor: Color(0xFF636995),
          backgroundColor: Color(0xFF18122B),
        ),
      ),
      routes: {
        HomePage.routeName: (context) => HomePage(),
        LoginScreen.routeName: (context) => LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == SingleListScreen.routeName) {
          return MaterialPageRoute(builder: (context) {
            return SingleListScreen(
              id: settings.arguments as String,
            );
          });
        }
      },
      home: initialScreen,
      // colorScheme: ColorScheme(
      //     background: LinearGradient(
      //   begin: Alignment.topCenter,
      //   end: Alignment.bottomCenter,
      //   colors: [Color(0xFF635985), Color(0xFF18122B)],
      // )),
    );
  }
}
