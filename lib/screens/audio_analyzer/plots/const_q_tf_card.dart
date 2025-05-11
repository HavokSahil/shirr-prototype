import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:isolate';
import 'dart:async';

import 'package:shirr/core/constants.dart';

class QTransformCard extends StatefulWidget {
  final Stream<List<double>> pcmBuffer;
  final int sampleRate;

  const QTransformCard({
    super.key,
    required this.pcmBuffer,
    required this.sampleRate,
  });

  @override
  State<QTransformCard> createState() => _QTransformCardState();
}

class _QTransformCardState extends State<QTransformCard> {
  late QTransformIsolate _qIsolate;
  List<double> _noteData = List.filled(12, 0.0); // 12 notes

  static const int binsPerOctave = 24; // Adjustable resolution

  @override
  void initState() {
    super.initState();
    _qIsolate = QTransformIsolate();
    _startIsolateAndListen();
  }

  Future<void> _startIsolateAndListen() async {
    await _qIsolate.start();

    DateTime lastSent = DateTime.now();
    Duration minInterval = Duration(milliseconds: 100); // Tune this

    widget.pcmBuffer.listen((chunk) {
      final now = DateTime.now();
      if (now.difference(lastSent) < minInterval) return;

      final int totalOctaves = (log(4186 / 27.5) / ln2).floor(); // ~8
      final int numBins = totalOctaves * binsPerOctave;

      lastSent = now;
      _qIsolate.sendAudioData(
        chunk,
        sampleRate: widget.sampleRate,
        minFreq: 27.5,
        maxFreq: 4186,
        numBins: numBins.toDouble(),
        onResult: (List<double> result) {
          _processQTransform(result);
        },
      );
    });
  }

  void _processQTransform(List<double> qData) {
    List<double> chroma = List.filled(12, 0.0);
    for (int i = 0; i < qData.length; i++) {
      double freq = 27.5 * pow(2, i / binsPerOctave);
      if (freq <= 0) continue;

      // Convert frequency to MIDI note number, then modulo 12
      final midiNote = (12 * (log(freq / 440) / ln2) + 69).round();
      final noteIndex = midiNote % 12;
      chroma[noteIndex] += qData[i];
    }

    final maxVal = chroma.reduce(max);
    if (maxVal > 0) {
      chroma = chroma.map((e) => e / maxVal).toList();
    }


    setState(() => _noteData = chroma);
  }

  @override
  void dispose() {
    _qIsolate.dispose();
    // _micSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final noteNames = [
      "C", "C#", "D", "D#", "E", "F",
      "F#", "G", "G#", "A", "A#", "B"
    ];

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              "Note Histogram",
              style: TextStyle(
                fontFamily: Constants.fontFamilyBody,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Expanded(
              child: BarChart(
                BarChartData(
                  minY: 0,
                  alignment: BarChartAlignment.spaceEvenly,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= noteNames.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              noteNames[index],
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _noteData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final amplitude = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: amplitude,
                          color: isDark ? Colors.white : Colors.black,
                          width: min(14.0, MediaQuery.of(context).size.width / 24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class QTransformIsolate {
  late Isolate _isolate;
  late SendPort _sendPort;
  late ReceivePort _receivePort;
  bool _isRunning = false;

  Future<void> start() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_entryPoint, _receivePort.sendPort);

    _sendPort = await _receivePort.first as SendPort;
    _isRunning = true;
  }

  void dispose() {
    _receivePort.close();
    _isolate.kill(priority: Isolate.immediate);
    _isRunning = false;
  }

  void sendAudioData(List<double> buffer, {
    required int sampleRate,
    required double minFreq,
    required double maxFreq,
    required double numBins,
    required Function(List<double>) onResult,
  }) {
    if (!_isRunning) return;

    final responsePort = ReceivePort();
    _sendPort.send([
      buffer,
      sampleRate,
      minFreq,
      maxFreq,
      numBins,
      responsePort.sendPort,
    ]);

    responsePort.listen((result) {
      onResult(result as List<double>);
      responsePort.close();
    });
  }

  /// Isolate Entry Point
  static void _entryPoint(SendPort mainSendPort) {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);

    port.listen((message) {
      final buffer = message[0] as List<double>;
      final sampleRate = message[1] as int;
      final minFreq = message[2] as double;
      final maxFreq = message[3] as double;
      final numBins = message[4] as double;
      final replyPort = message[5] as SendPort;

      final transformer = CalcQTransform(
        minFreq: minFreq,
        maxFreq: maxFreq,
        sampleRate: sampleRate,
        numBins: numBins,
      );

      final power = transformer.getTransformPower(buffer);
      replyPort.send(power);
    });
  }
}



class CalcQTransform {
  final double minFreq;
  final double maxFreq;
  final int sampleRate;
  final double numBins;

  CalcQTransform({
    required this.minFreq,
    required this.maxFreq,
    required this.sampleRate,
    required this.numBins
  });

  final Map<int, List<double>> _windowCache = {};

  List<double> getWindow(int nK) {
    return _windowCache.putIfAbsent(nK, () => hammingWindow(nK));
  }

  List<double> hammingWindow(int len) {
    return List.generate(len, (n) => 0.54 - 0.46 * cos(2 * pi * n / (len - 1)));
  }

  List<double> getTransformPower(List<double> buffer) {
    final K = (numBins * log(maxFreq / minFreq)/ ln2).ceil();
    final Q = 1/(pow(2, 1/numBins) - 1);
    List<double> result = List.filled(K, 0.0);
    for (int k = 0; k<K; k++) {
      final freqK = minFreq * pow(2, k/numBins);
      final nK = (Q * sampleRate / freqK).ceil();

      final effectiveNk = min(nK, buffer.length);
      final window = getWindow(effectiveNk);

      double real = 0.0;
      double imag = 0.0;
      for (int n = 0; n<effectiveNk; n++) {
        real += buffer[n] * window[n] * cos(2 * pi * freqK * n / sampleRate);
        imag += buffer[n] * window[n] * -sin(2 * pi * freqK * n / sampleRate);
      }

      real/=nK;
      imag/=nK;

      result[k] = sqrt(real*real + imag*imag);
    }
    return result;
  }
}
