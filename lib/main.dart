import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:to_do/Providers/notification_provider.dart';

import 'themes.dart';
import 'l10n/app_localizations.dart';
import './Utils/shared_preferences_helper.dart';
import './Screens/home_page.dart';
import './Screens/single_list_screen.dart';
import './Screens/statistics_screen.dart';
import './Screens/content_screen.dart';
import './Providers/lists_provider.dart';
import './Providers/item_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesHelper.instance.initialise();

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
      child: const OwlistApp(),
    ),
  );
}

class OwlistApp extends StatefulWidget {
  const OwlistApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _OwlistAppState state =
        context.findAncestorStateOfType<_OwlistAppState>()!;
    state.setLocale(newLocale);
  }

  static void setTheme(BuildContext context, String? mode) {
    final _OwlistAppState state =
        context.findAncestorStateOfType<_OwlistAppState>()!;
    switch (mode) {
      case "dark":
        state.setTheme(ThemeMode.dark);
        break;
      case "light":
        state.setTheme(ThemeMode.light);
        break;
      default:
        state.setTheme(ThemeMode.system);
    }
  }

  static int themeMode(BuildContext context) {
    final _OwlistAppState state =
        context.findAncestorStateOfType<_OwlistAppState>()!;
    if (state.currentThemeMode != null) {
      if (state.currentThemeMode == ThemeMode.dark) {
        return 0;
      } else if (state.currentThemeMode == ThemeMode.light) {
        return 2;
      }
    }
    return 1;
  }

  @override
  State<OwlistApp> createState() => _OwlistAppState();
}

class _OwlistAppState extends State<OwlistApp> {
  Locale? _locale;
  ThemeMode? currentThemeMode;
  late Widget initialScreen;

  Future<void> setPreferences(BuildContext context) async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    String? language = SharedPreferencesHelper.instance.selectedLanguage;
    String? themePref = SharedPreferencesHelper.instance.selectedTheme;

    // Set locale
    switch (language) {
      case 'en':
        _locale = const Locale('en', 'IL');
        break;
      case 'he':
        _locale = const Locale('he', 'US');
        break;
      default:
        _locale = null;
    }

    // Set theme
    switch (themePref) {
      case 'dark':
        currentThemeMode = ThemeMode.dark;
        break;
      case 'light':
        currentThemeMode = ThemeMode.light;
        break;
      default:
        currentThemeMode = ThemeMode.system;
    }
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  void setTheme(ThemeMode newTheme) {
    setState(() {
      currentThemeMode = newTheme;
    });
  }

  @override
  void didChangeDependencies() {
    setPreferences(context);
    super.didChangeDependencies();
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
        themeMode: currentThemeMode,
        theme: lightTheme,
        darkTheme: darkTheme,
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
        home: HomePage(),
      ),
    );
  }
}
