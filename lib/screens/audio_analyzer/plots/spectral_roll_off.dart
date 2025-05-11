import 'dart:math';

import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';
// import 'package:shirr/services/mic_controller.dart';

class SpectralRollOffCard extends StatefulWidget {
  final bool isInteractive;
  final Stream<List<double>> pcmBuffer;
  final int sampleRate;

  const SpectralRollOffCard({
    super.key,
    required this.isInteractive,
    required this.pcmBuffer,
    required this.sampleRate,
  });

  @override
  State<SpectralRollOffCard> createState() => _SpectralRollOffCardState();
}

class _SpectralRollOffCardState extends State<SpectralRollOffCard> {
  List<double> calcSpectralRolloffCurve(List<double> buffer, int sampleRate) {
    final int N = buffer.length;

    // Apply Hamming window
    final windowed = List<double>.generate(N, (i) {
      final w = 0.54 - 0.46 * cos((2 * pi * i) / (N - 1));
      return buffer[i] * w;
    });

    final fft = FFT(N);
    final fftFreq = fft.realFft(windowed);
    final int nyquist = fftFreq.length~/2;

    // Compute magnitude spectrum
    final magnitudes = List<double>.generate(nyquist, (i) {
      final real = fftFreq[i].x;
      final imag = fftFreq[i].y;
      return sqrt(real * real + imag * imag);
    });

    final totalEnergy = magnitudes.reduce((a, b) => a + b);

    // Compute cumulative sum of energy
    final cumulative = List<double>.filled(nyquist, 0.0);
    double sum = 0.0;
    for (int i = 0; i < nyquist; i++) {
      sum += magnitudes[i];
      cumulative[i] = sum;
    }

    // Generate rolloff frequencies for 1% to 100%
    final rolloffFreqs = List<double>.filled(100, 0.0);
    for (int p = 1; p <= 100; p++) {
      final target = totalEnergy * (p / 100.0);
      for (int i = 0; i < nyquist; i++) {
        if (cumulative[i] >= target) {
          rolloffFreqs[p - 1] = sampleRate * i / N;
          break;
        }
      }
    }

    return rolloffFreqs; // [f_1%, f_2%, ..., f_100%]
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
            List<double> rolloffFreqs = calcSpectralRolloffCurve(buffer, widget.sampleRate);
            final maxY = rolloffFreqs.reduce((a, b) => (a>b)?a:b);
            final spots = List.generate(
              rolloffFreqs.length,
              (i) => FlSpot(i.toDouble(), rolloffFreqs[i]),
            );

            return Column(
              children: [
                 Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8),
                  child: Text(
                    "Spectral Roll-off Frequencies",
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
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        enabled: !widget.isInteractive,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              final x = touchedSpot.x;
                              final y = touchedSpot.y;
                
                              return LineTooltipItem(
                                "(${x.toStringAsFixed(0)}, ${y.toStringAsFixed(3)})",
                                TextStyle(fontSize: 10)
                              );
                            }).toList();
                          },
                          getTooltipColor: (_) {
                            return isDark?const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0);
                          }
                        )
                      ),
                      borderData: FlBorderData(show: false),
                      clipData: FlClipData.all(),
                      minX: 0,
                      maxX: 100,
                      minY: 0,
                      maxY: maxY,
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
                            "Frequency",
                            style: TextStyle(fontFamily: Constants.fontFamilyBody ,fontSize: 10),
                          ),
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 8),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              "Percentage",
                              style: TextStyle(fontFamily: Constants.fontFamilyBody ,fontSize: 10),
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
