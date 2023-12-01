import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:to_do/Providers/notification_provider.dart';
// import 'package:workmanager/workmanager.dart';

import 'themes.dart';
import 'l10n/app_localizations.dart';
import './Models/to_do_list.dart';
import './Screens/home_page.dart';
import './Screens/single_list_screen.dart';
import './Screens/statistics_screen.dart';
import './Screens/content_screen.dart';
import './Providers/lists_provider.dart';
import './Providers/item_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  MobileAds.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => ListsProvider()),
        ChangeNotifierProvider(create: (context) => ItemProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  static void setTheme(BuildContext context) {
    final _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setTheme(toggleTheme(state.currentTheme));
  }

  static bool isDark(BuildContext context) {
    final _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    return state.currentTheme == darkTheme;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');
  late ThemeData currentTheme = lightTheme;
  late Widget initialScreen;

  Future<void> setPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? language = prefs.getString('selectedLanguage');

    Locale newLocale;
    switch (language) {
      case 'en':
        newLocale = const Locale('en', '');
        break;
      case 'he':
        newLocale = const Locale('he', '');
        break;
      default:
        newLocale = const Locale('en', '');
    }
    setLocale(newLocale);

    String? themePref = prefs.getString('selectedTheme');
    ThemeData newTheme;
    switch (themePref) {
      case 'dark':
        newTheme = darkTheme;
        break;
      case 'light':
        newTheme = lightTheme;
        break;
      default:
        newTheme = MediaQuery.of(context).platformBrightness == Brightness.dark
            ? darkTheme
            : lightTheme;
    }
    setTheme(newTheme);
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  void setTheme(ThemeData newTheme) {
    setState(() {
      currentTheme = newTheme;
    });
  }

  @override
  void initState() {
    super.initState();
    initialScreen = HomePage();
    setPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotificationProvider(),
      child: MaterialApp(
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('he', 'IL'),
        ],
        theme: currentTheme,
        routes: {
          HomePage.routeName: (context) => HomePage(),
          StatisticsScreen.routeName: (context) => StatisticsScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case SingleListScreen.routeName:
              {
                return MaterialPageRoute(builder: (context) {
                  return SingleListScreen(
                    listId: settings.arguments as String,
                  );
                });
              }
            case ContentScreen.routeName:
              {
                // Extract the arguments map from settings
                final Map<String, dynamic> args =
                    settings.arguments as Map<String, dynamic>;

                return MaterialPageRoute(builder: (context) {
                  return ContentScreen(
                    id: args['id'] as String,
                    updateSingleListScreen:
                        args['updateSingleListScreen'] as Function,
                  );
                });
              }
          }
        },
        home: initialScreen,
      ),
    );
  }
}
