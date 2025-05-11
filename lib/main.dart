

import 'package:flutter/material.dart';
import 'package:shirr/screens/main_menu/main_menu_screen.dart';
import 'package:shirr/screens/audio_analyzer/audio_analyzer_screen.dart';
import 'package:shirr/screens/audio_generator/audio_generator_screen.dart';
import 'package:shirr/screens/audio_visualizer/audio_visualizer_screen.dart';
import './core/constants.dart';
import './core/theme.dart';
import 'screens/intro/intro_screen.dart';

void main() {
  return runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.appName,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      routes: {
        Constants.routeLoadingAnim: (context) => SplashScreen(),
        Constants.routeMainMenu: (context) => MainMenuScreen(),
        Constants.routeAudioAnalyzer: (context) => AudioAnalyzerScreen(),
        Constants.routeAudioGenerator: (context) => AudioGeneratorScreen(),
        Constants.routeAudioVisualizer: (context) => AudioVisualizerScreen(),
      },
    );
  }
}