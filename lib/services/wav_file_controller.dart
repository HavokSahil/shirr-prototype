import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:wav/wav.dart';
import 'dart:async';

Future<List<double>> decodeWavFile(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();

  final wav = Wav.read(bytes);
  final data = wav.toMono();

  // Normalize to [-1.0, 1.0] float PCM
  List<double> floatPcm = [];

  for (var i = 0; i < data.length; i++) {
    final sample = data[i];
    final normSample = sample / (1 << (wav.format.bitsPerSample - 1));
    floatPcm.add(normSample);
  }

  debugPrint("Decoded ${floatPcm.length} samples at ${wav.samplesPerSecond} Hz, ${wav.channels} channels.");
  return floatPcm;
}

class WavController {
  final int sampleRate;
  final int chunkSize;
  List<double> _pcmSamples = [];
  late Timer _playbackTimer;

  final StreamController<List<double>> _streamController = StreamController.broadcast();

  int _currentIndex = 0;
  bool _isPlaying = false;

  WavController({required this.sampleRate, this.chunkSize = 512});

  void loadPcm(List<double> pcm) {
    if (_isPlaying) stop();
    _pcmSamples = pcm;
    _currentIndex = 0;
  }

  void play() {
    if (_isPlaying || _pcmSamples.isEmpty) return;
    _isPlaying = true;

    final interval = Duration(microseconds: (1e6 * chunkSize / sampleRate).round());

    _playbackTimer = Timer.periodic(interval, (_) {
      debugPrint("Yeah, Time is ticking");
      if (_currentIndex >= _pcmSamples.length) {
        stop();
        return;
      }

      final end = (_currentIndex + chunkSize).clamp(0, _pcmSamples.length);
      final chunk = _pcmSamples.sublist(_currentIndex, end);
      _streamController.add(chunk);
      _currentIndex = end;
      debugPrint("At the end baby: wohooo: $end/${_pcmSamples.length} in total ${(100.0*end/_pcmSamples.length).toStringAsFixed(2)}%");
    });
  }

  void pause() {
    _isPlaying = false;
    _playbackTimer.cancel();
  }

  void stop() {
    _isPlaying = false;
    _playbackTimer.cancel();
    _currentIndex = 0;
  }

  bool isPlaying() => _isPlaying;

  Stream<List<double>> get audioDataStream => _streamController.stream;

  void dispose() {
    _streamController.close();
    if (_playbackTimer.isActive) _playbackTimer.cancel();
  }
}
