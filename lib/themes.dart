import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
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
      color: Colors.grey,
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
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all<Color>(Colors.blue),
    trackColor: MaterialStateProperty.all<Color>(Colors.black),
  ),
);

final ThemeData darkTheme = ThemeData.dark().copyWith(
  dividerColor: Color(0xFF42385E),
  hintColor: Colors.grey,
  primaryColorDark: Colors.black,
  primaryColorLight: Color(0xFF42385E),
  primaryColor: Color(0xFF18122B),
  focusColor: Color(0xFF864879),
  shadowColor: Colors.white,
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
      color: Colors.grey,
      // fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(color: Colors.white, fontSize: 17),
  ),
  colorScheme: ColorScheme.fromSwatch(
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
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all<Color>(Colors.orange),
    trackColor: MaterialStateProperty.all<Color>(Colors.white),
  ),
);

ThemeData toggleTheme(ThemeData currentTheme) {
  return currentTheme == lightTheme ? darkTheme : lightTheme;
}
