import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.purpleAccent,
    selectionHandleColor: Colors.purpleAccent,
  ),
  dividerColor: Color(0xFF9685D9),
  hintColor: Colors.grey,
  primaryColorDark: Color(0xFF18122B),
  primaryColorLight: Color(0xFF635985),
  primaryColor: Colors.white,
  focusColor: Color(0xFF864879),
  unselectedWidgetColor: Colors.grey,
  shadowColor: Colors.black,
  highlightColor: Color(0xFF18122B),
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
      color: Colors.grey, fontSize: 15.0, fontWeight: FontWeight.bold,
      // fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(color: Colors.black, fontSize: 17),
  ),
  cardColor: Colors.white,
  iconTheme: IconThemeData(color: Colors.white),
  colorScheme: ColorScheme.fromSwatch(
    accentColor: Color(0xFF635985),
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
    fillColor: MaterialStateProperty.all<Color>(Color(0xFF635985)),
    checkColor: MaterialStateProperty.all<Color>(Colors.white),
    side: BorderSide.none,
  ),
  switchTheme: SwitchThemeData(
    trackOutlineColor: MaterialStateProperty.all<Color>(Colors.transparent),
    trackColor: MaterialStateProperty.all<Color>(Color(0xFF6B5432)),
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: Color(0xFF9685D9),
    linearTrackColor: Colors.grey.shade300,
    linearMinHeight: 10.0,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Color(0xFF635985))),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return Color(0xFF38363b);
          }
          return Color(0xFF635985);
        },
      ),
    ),
  ),
  datePickerTheme: DatePickerThemeData(
    yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Color(0xFF9685D9);
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
    todayBackgroundColor:
        MaterialStateProperty.all<Color>(Color(0xFF9685D9).withOpacity(0.5)),
    headerBackgroundColor: Color(0xFF635985),
    dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Color(0xFF9685D9);
      }
      return Colors.white;
    }),
    dayForegroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return Colors.grey;
      }
      return Colors.black;
    }),
    dayStyle: TextStyle(color: Colors.white),
  ),
);

final ThemeData darkTheme = ThemeData.dark().copyWith(
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.purpleAccent,
    selectionHandleColor: Colors.purpleAccent,
  ),
  dividerColor: Color(0xFF42385E),
  hintColor: Colors.grey,
  primaryColorDark: Colors.black,
  primaryColorLight: Color(0xFF42385E),
  primaryColor: Color(0xFF18122B),
  focusColor: Color(0xFF864879),
  // shadowColor: Colors.white,
  unselectedWidgetColor: Colors.grey,
  highlightColor: Color(0xFF9685D9),
  cardColor: Color(0xFF38305B),
  // Color(0xFF282344)
  iconTheme: IconThemeData(color: Colors.white),
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
      color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold,
      // fontWeight: FontWeight.bold,
    ),
    // bodyMedium: TextStyle(
    //   color: Color(0xFF635985),
    //   fontSize: 18.0,
    //   fontWeight: FontWeight.bold,
    // ),
    headlineSmall: TextStyle(
      color: Colors.white,
      fontSize: 17,
    ),
  ),
  colorScheme: ColorScheme.fromSwatch(
    brightness: Brightness.dark,
    accentColor: Color(0xFF18122B),
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
    fillColor: MaterialStateProperty.all<Color>(Color(0xFF9685D9)),
    checkColor: MaterialStateProperty.all<Color>(Colors.black),
    side: BorderSide.none,
  ),
  switchTheme: SwitchThemeData(
    trackOutlineColor: MaterialStateProperty.all<Color>(Colors.transparent),
    trackColor: MaterialStateProperty.all<Color>(Colors.black),
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: Color(0xFF635985),
    linearTrackColor: Color(0xFF18122B),
    linearMinHeight: 10.0,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Color(0xFF9685D9))),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return Color(0xFF38363b);
          }
          return Color(0xFF635985);
        },
      ),
      // textStyle: MaterialStateProperty.resolveWith<TextStyle>(
      //   (Set<MaterialState> states) {
      //     if (states.contains(MaterialState.disabled)) {
      //       return TextStyle(
      //         color: Colors.grey,
      //         fontSize: 18.0,
      //         fontWeight: FontWeight.bold,
      //       );
      //     }
      //     return TextStyle(
      //       color: Color(0xFF9685D9),
      //       fontSize: 18.0,
      //       fontWeight: FontWeight.bold,
      //     );
      //   },
      // ),
    ),
  ),

  datePickerTheme: DatePickerThemeData(
    // dayOverlayColor: MaterialStateProperty.all<Color>(Colors.white),
    // headerHeadlineStyle: TextStyle(color: Colors.white),
    // headerForegroundColor: Colors.white,
    // headerHelpStyle: TextStyle(color: Colors.white),
    // rangePickerHeaderBackgroundColor: Colors.white,
    // rangeSelectionBackgroundColor: Colors.white,
    // rangePickerBackgroundColor: Colors.white,
    // rangePickerHeaderForegroundColor: Colors.white,
    // rangePickerHeaderHeadlineStyle: TextStyle(color: Colors.white),
    // rangePickerHeaderHelpStyle: TextStyle(color: Colors.white),
    // surfaceTintColor: Colors.white,
    // rangePickerShadowColor: Colors.white,
    // rangePickerSurfaceTintColor: Colors.white,
    // rangeSelectionOverlayColor: MaterialStateProperty.all<Color>(Colors.white),
    // shadowColor: Colors.white,
    // yearStyle: TextStyle(color: Colors.white),

    backgroundColor: Color(0xFF18122B),
    weekdayStyle: TextStyle(color: Colors.white),
    yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Color(0xFF9685D9);
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
    todayBackgroundColor:
        MaterialStateProperty.all<Color>(Color(0xFF635985).withOpacity(0.5)),
    headerBackgroundColor: Color(0xFF635985),
    dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Color(0xFF635985);
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
    dayStyle: TextStyle(color: Colors.white),
  ),
);

ThemeData toggleTheme(ThemeData currentTheme) {
  return currentTheme == lightTheme ? darkTheme : lightTheme;
}
