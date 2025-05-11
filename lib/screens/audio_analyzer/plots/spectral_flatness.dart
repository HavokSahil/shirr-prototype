import 'dart:collection';
import 'dart:math';
import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';
// import 'package:shirr/services/mic_controller.dart';

class SpectralFlatness extends StatefulWidget {
  final bool isInteractive;
  final Stream<List<double>> pcmBuffer;
  final int sampleRate;

  const SpectralFlatness({
    super.key,
    required this.isInteractive,
    required this.pcmBuffer,
    required this.sampleRate
  });

  @override
  State<SpectralFlatness> createState() => _SpectralFlatnessState();
}

class _SpectralFlatnessState extends State<SpectralFlatness> {
  static const int listSize = 1024;
  double _maxY = 1;
  double _minX = 0.0;
  double _maxX = listSize.toDouble();
  final double _dragSensitivity = 1.0;

  final Queue<double> specQueue = ListQueue<double>.from(
    List.filled(listSize, 0.0)
  );

double calcSpectralFlatness(List<double> buffer) {
    final N = buffer.length;

    // Hamming window
    final windowed = List<double>.generate(N, (i) {
      final w = 0.54 - 0.46 * cos((2 * pi * i) / (N - 1));
      return buffer[i] * w;
    });

    final fft = FFT(N);
    final fftFreq = fft.realFft(windowed);
    final nyquist = fftFreq.length;

    final magnitudes = List<double>.generate(nyquist, (i) {
      final real = fftFreq[i].x;
      final imag = fftFreq[i].y;
      return sqrt(real * real + imag * imag) + 1e-12; // Avoid log(0)
    });

    // Geometric mean
    final logSum = magnitudes.fold(0.0, (sum, mag) => sum + log(mag));
    final geoMean = exp(logSum / magnitudes.length);

    // Arithmetic mean
    final arithMean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;

    return geoMean / arithMean;
  }

  void _calcUpdateQueue(List<double> buffer) {
    final centroid = calcSpectralFlatness(buffer);
    if (specQueue.length > listSize) {
      specQueue.removeFirst();
    }
    specQueue.add(centroid);
  }

  List<FlSpot> get _getSpot {
    List<double> specList = specQueue.toList();
    return List.generate(specList.length, (i) => FlSpot(i.toDouble(), specList[i]));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 6,
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<List<double>>(
          stream: widget.pcmBuffer,
          builder: (context, snapshot) {

            final buffer = snapshot.data ?? List.filled(6400, 0.0);
            _calcUpdateQueue(buffer);

            final spots = _getSpot;

            return Column(
              children: [
                 Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8),
                  child: Text(
                    "Spectral Flatness",
                    style: TextStyle(
                      fontFamily: Constants.fontFamilyBody,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onScaleUpdate: (details) {
                      if (widget.isInteractive) {
                        setState(() {
                          double centerX = (_minX + _maxX) / 2;
                          double halfWidth = (_maxX - _minX) / 2;
                          double newHalfWidth = halfWidth / details.horizontalScale.clamp(0.95, 1.05);
                          double newMinX = (centerX - newHalfWidth).clamp(0.0, listSize.toDouble());
                          double newMaxX = (centerX + newHalfWidth).clamp(newMinX + 10.0, listSize.toDouble());
                          _minX = newMinX;
                          _maxX = newMaxX;
                        });
                      }
                    },
                    onHorizontalDragUpdate: (details) {
                      if (widget.isInteractive) {
                        setState(() {
                          final dragDelta = details.primaryDelta ?? 0;
                          final shift = dragDelta * (_maxX - _minX) / context.size!.width * _dragSensitivity;
                          final newMinX = (_minX - shift).clamp(0.0, listSize.toDouble());
                          final newMaxX = (_maxX - shift).clamp(newMinX + 10.0, listSize.toDouble());
                          _minX = newMinX;
                          _maxX = newMaxX;
                        });
                      }
                    },
                    onDoubleTap: () {
                      if (widget.isInteractive) {
                        setState(() {
                          _minX = 0.0;
                          _maxX = listSize.toDouble();
                        });
                      }
                    },
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          enabled: !widget.isInteractive,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  "(${spot.x.toStringAsFixed(0)}, ${spot.y.toStringAsFixed(1)})",
                                  const TextStyle(fontSize: 10),
                                );
                              }).toList();
                            },
                            getTooltipColor: (_) => isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF0F0F0),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        clipData: FlClipData.all(),
                        minX: _minX,
                        maxX: _maxX,
                        minY: 0,
                        maxY: _maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.25,
                            color: isDark
                                ? const Color(0xFFD5D5D5)
                                : const Color(0xFF1A1A1A),
                            barWidth: 0.8,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            axisNameWidget: Text(
                              "Flatness",
                              style: TextStyle(fontFamily: Constants.fontFamilyBody, fontSize: 10),
                            ),
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  (value >= 1000)? (value/1000.0).toStringAsFixed(2): value.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 8),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            axisNameWidget: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Frame",
                                style: TextStyle(fontFamily: Constants.fontFamilyBody, fontSize: 10),
                              ),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final displayValue = value >= 1000
                                    ? "${(value / 1000).toStringAsFixed(1)}k"
                                    : value.toStringAsFixed(0);
                                return Text(
                                  displayValue,
                                  style: const TextStyle(fontSize: 8),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            );
          },
        ),
      ),
    );
  }
}
