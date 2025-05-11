import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();

}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {


  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 4500), () {
      Navigator.pushReplacementNamed(context, '/mainmenu');
    });
  }

  @override
  Widget build(BuildContext context) {

    final currentTheme = Theme.of(context);
    final currentBrightness = currentTheme.brightness;

    return Scaffold(
      body: Center(
        child: Image.asset((currentBrightness == Brightness.light)? Constants.pathAnimIntroLight: Constants.pathAnimIntroDark),
        )
    );
  }

}