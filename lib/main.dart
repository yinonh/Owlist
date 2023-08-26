import 'dart:async';
import 'dart:isolate';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:workmanager/workmanager.dart';

import './Models/to_do_list.dart';
import './Screens/home_page.dart';
import './Screens/single_list_screen.dart';
import './Screens/auth_screen.dart';
import './Providers/lists_provider.dart';
import './Providers/item_provider.dart';

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) {
//     if (inputData != null && inputData.containsKey('notificationDate')) {
//       final isoFormattedDate = inputData['notificationDate'];
//       final notificationDate = DateTime.parse(isoFormattedDate);
//
//       AwesomeNotifications().createNotification(
//         content: NotificationContent(
//           id: 1,
//           channelKey: 'task_deadline_channel',
//           title: 'hello',
//           body: 'Task deadline is about to end',
//           color: Color(0xFF635985),
//         ),
//         schedule: NotificationCalendar.fromDate(
//           date: notificationDate,
//         ),
//       );
//       return Future.value(true);
//     }
//     return Future.value(false);
//   });
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon',
    [
      NotificationChannel(
        channelKey: 'task_deadline_channel',
        channelName: 'Deadline notifications ',
        channelDescription:
            'Notifications that the task deadline is about to end',
        importance: NotificationImportance.High,
        playSound: true,
        defaultColor: Colors.deepPurple,
        ledColor: Colors.deepPurple,
        channelShowBadge: true,
      ),
    ],
  );
  // Workmanager().initialize(callbackDispatcher);
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
    initialScreen = AuthScreen();
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
        AuthScreen.routeName: (context) => AuthScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == SingleListScreen.routeName) {
          ToDoList arg = settings.arguments as ToDoList;
          return MaterialPageRoute(builder: (context) {
            return SingleListScreen(
              list: arg,
            );
          });
        }
      },
      home: initialScreen,
    );
  }
}
