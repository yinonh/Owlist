import 'package:flutter/material.dart';

import '../main.dart';

final ThemeData lightTheme = ThemeData(
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.purpleAccent,
    selectionHandleColor: Colors.purpleAccent,
  ),
  dividerColor: const Color(0xFF9685D9),
  hintColor: Colors.grey,
  canvasColor: Colors.black,
  primaryColorDark: const Color(0xFF18122B),
  primaryColorLight: const Color(0xFF635985),
  primaryColor: Colors.white,
  focusColor: const Color(0xFF864879),
  unselectedWidgetColor: Colors.grey,
  shadowColor: Colors.black,
  highlightColor: const Color(0xFF9685D9), //Color(0xFF18122B),
  textTheme: const TextTheme(
    bodySmall: TextStyle(color: Colors.black),
    titleSmall: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: Color(0xFF635985),
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: Colors.black, fontSize: 15.0, fontWeight: FontWeight.bold,
      // fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(color: Colors.black, fontSize: 17),
  ),
  cardColor: Colors.white,
  iconTheme: const IconThemeData(color: Colors.white),
  colorScheme: ColorScheme.fromSwatch(
    accentColor: const Color(0xFF635985),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        10.0,
      ),
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.all<Color>(const Color(0xFF635985)),
    checkColor: MaterialStateProperty.all<Color>(Colors.white),
    side: BorderSide.none,
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: const Color(0xFF635985),
    linearTrackColor: Colors.grey.shade300,
    linearMinHeight: 10.0,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
        foregroundColor:
            MaterialStateProperty.all<Color>(const Color(0xFF635985))),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return const Color(0xFF38363b);
          }
          return const Color(0xFF635985);
        },
      ),
    ),
  ),
  datePickerTheme: DatePickerThemeData(
    headerForegroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF9685D9);
      }
      if (states.contains(MaterialState.disabled)) {
        return Colors.grey.shade300;
      }
      return Colors.white;
    }),
    yearForegroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.white;
      }
      return Colors.black;
    }),
    todayForegroundColor: MaterialStateProperty.all<Color>(Colors.black),
    todayBackgroundColor: MaterialStateProperty.all<Color>(
        const Color(0xFF9685D9).withOpacity(0.5)),
    headerBackgroundColor: const Color(0xFF635985),
    dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF9685D9);
      }
      return Colors.white;
    }),
    dayForegroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return Colors.grey;
      }
      return Colors.black;
    }),
    dayStyle: const TextStyle(color: Colors.white),
  ),
);

final ThemeData darkTheme = ThemeData.dark().copyWith(
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.purpleAccent,
    selectionHandleColor: Colors.purpleAccent,
  ),
  dividerColor: const Color(0xFF42385E),
  hintColor: Colors.grey,
  canvasColor: Colors.white,
  primaryColorDark: Colors.black,
  primaryColorLight: const Color(0xFF42385E),
  primaryColor: const Color(0xFF18122B),
  focusColor: const Color(0xFF864879),
  // shadowColor: Colors.white,
  unselectedWidgetColor: Colors.grey,
  highlightColor: const Color(0xFF9685D9),
  cardColor: const Color(0xFF38305B),
  // Color(0xFF282344)
  iconTheme: const IconThemeData(color: Colors.white),
  textTheme: const TextTheme(
    bodySmall: TextStyle(color: Colors.white),
    titleSmall: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: Color(0xFF9685D9),
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: Colors.grey,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: Colors.white,
      fontSize: 17,
    ),
  ),
  colorScheme: ColorScheme.fromSwatch(
    brightness: Brightness.dark,
    accentColor: const Color(0xFF18122B),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        10.0,
      ),
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.all<Color>(const Color(0xFF9685D9)),
    checkColor: MaterialStateProperty.all<Color>(Colors.black),
    side: BorderSide.none,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF635985),
    linearTrackColor: Color(0xFF18122B),
    linearMinHeight: 10.0,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
        foregroundColor:
            MaterialStateProperty.all<Color>(const Color(0xFF9685D9))),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return const Color(0xFF38363b);
          }
          return const Color(0xFF635985);
        },
      ),
    ),
  ),

  datePickerTheme: DatePickerThemeData(
    backgroundColor: const Color(0xFF18122B),
    weekdayStyle: const TextStyle(color: Colors.white),
    yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF9685D9);
      }
      if (states.contains(MaterialState.disabled)) {
        return Colors.grey.shade700;
      }
      return Colors.transparent;
    }),
    yearForegroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.black;
      }
      return Colors.white;
    }),
    todayForegroundColor: MaterialStateProperty.all<Color>(Colors.white),
    todayBackgroundColor: MaterialStateProperty.all<Color>(
        const Color(0xFF635985).withOpacity(0.5)),
    headerBackgroundColor: const Color(0xFF635985),
    dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF635985);
      }
      return Colors.transparent;
    }),
    yearOverlayColor: MaterialStateProperty.all<Color>(Colors.white),
    dayForegroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return Colors.grey.shade700;
      }
      return Colors.white;
    }),
    dayStyle: const TextStyle(color: Colors.white),
  ),
);

ThemeData? getThemeData(ThemeMode currentTheme) {
  switch (currentTheme) {
    case ThemeMode.light:
      return lightTheme;
    case ThemeMode.dark:
      return darkTheme;
    default:
      if (ThemeMode.system == ThemeMode.dark) {
        return darkTheme;
      }
      return lightTheme;
  }
}
