import 'package:flutter/material.dart';
import 'package:shirr/components/wave_form_painter.dart';
import 'package:shirr/services/mic_controller.dart';

class MicPlayerWidget extends StatefulWidget {
  const MicPlayerWidget({super.key});

  @override
  State<MicPlayerWidget> createState() => _MicPlayerWidgetState();
}

class _MicPlayerWidgetState extends State<MicPlayerWidget> with WidgetsBindingObserver {
  final MicController micController = MicController();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    micController.stop().then((_) => debugPrint("Stopped MicController"));
    micController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      micController.stop().then((_) => debugPrint("Stopped due to app pause"));
    }
  }

  void toggleStream() async {
    if (_isListening) {
      await micController.stop();
    } else {
      await micController.listening();
    }

    setState(() {
      _isListening = micController.isListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: toggleStream,
            child: Text(_isListening ? "Stop" : "Listen"),
          ),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(border: Border.all()),
            child: StreamBuilder<List<double>>(
              stream: micController.audioDataStream,
              builder: (context, snapshot) {
                final buffer = snapshot.data ?? List.filled(128, 0.0);
                return CustomPaint(
                  painter: WaveFormPainter(buffer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
