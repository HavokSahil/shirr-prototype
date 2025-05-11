import 'package:flutter/material.dart';

class AppTheme {

  static final colorLightRank1 = Color.fromARGB(255, 0, 0, 0);        // #000000
  static final colorLightRank2 = Color.fromARGB(255, 174, 174, 174);  // #AEAEAE
  static final colorLightRank3 = Color.fromARGB(255, 213, 213, 213);  // #D5D5D5
  static final colorLightRank4 = Color.fromARGB(255, 252, 252, 250);  // #E9E9E9

  static final colorDarkRank1 = Color.fromARGB(255, 255, 255, 255);   // #FFFFFF
  static final colorDarkRank2 = Color.fromARGB(255, 119, 119, 119);   // #777777
  static final colorDarkRank3 = Color.fromARGB(255, 48, 48, 48);      // #303030
  static final colorDarkRank4 = Color.fromARGB(255, 0, 0, 0);         // #000000



  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.grey,
    scaffoldBackgroundColor: AppTheme.colorLightRank4,
    textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: AppTheme.colorLightRank4
        )
    )
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,
    scaffoldBackgroundColor: AppTheme.colorDarkRank4,
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: AppTheme.colorDarkRank1,
      )
    )
  );
  
}