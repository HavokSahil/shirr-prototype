import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shirr/components/page_under_dev.dart';



class AudioVisualizerScreen extends StatelessWidget{
  const AudioVisualizerScreen({super.key});

  static const platform = MethodChannel("com.example.shirr/essentia");

  Future<String> getEssentiaVersion() async {
    try {
      final String version = await platform.invokeMethod('getEssentiaVersion');
      return version;
    } on PlatformException catch (e) {
      return "Failed to get Essentia version: '${e.message}'.";
    }
  }

  @override
  Widget build(BuildContext context) {
    getEssentiaVersion().then((value) {
      debugPrint("Essentia Version: $value");
    });
    return PageUnderDevScreen(pageName: "Audio Visualizer");
  }
}