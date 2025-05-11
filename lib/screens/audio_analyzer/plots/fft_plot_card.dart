import 'dart:math';
import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';

class FrequencySpectrumChart extends StatefulWidget {
  final Stream<List<double>> pcmBuffer;
  final bool isInteractive;
  final int sampleRate;

  const FrequencySpectrumChart({
    super.key,
    required this.pcmBuffer,
    required this.isInteractive,
    required this.sampleRate
  });

  @override
  State<FrequencySpectrumChart> createState() => _FrequencySpectrumChartState();
}

class _FrequencySpectrumChartState extends State<FrequencySpectrumChart> {
  double _yScale = 100.0;
  double _minX = 0.0;
  double _maxX = 3e+4;
  final double _dragSensitivity = 1.0;

  @override
  void initState() {
    super.initState();
  }

  List<FlSpot> _computeSpectrum(List<double> samples) {
    final fft = FFT(samples.length);
    final freqDomain = fft.realFft(samples);

    final half = freqDomain.length ~/ 2;
    final spots = <FlSpot>[];

    final N = samples.length;

    for (int i = 0; i < half; i++) {
      final complex = freqDomain[i];
      final re = complex.x;
      final im = complex.y;
      final magnitude = sqrt(re * re + im * im);

      final frequency = i * widget.sampleRate / N;
      spots.add(FlSpot(frequency, magnitude));
    }

    return spots;
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
            final buffer = snapshot.data ?? List.filled(256, 0.0);
            final spots = _computeSpectrum(buffer);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8),
                  child: Text(
                    "FFT Waveform",
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
                          _yScale /= details.verticalScale.clamp(0.95, 1.05);
                          _yScale = _yScale.clamp(1.0, 1000.0);
                          // X-Axis Zoom (adjust frequency window)
                          double centerX = (_minX + _maxX) / 2;
                          double halfWidth = (_maxX - _minX) / 2;
                          double newHalfWidth = halfWidth / details.horizontalScale.clamp(0.95, 1.05);
                          double newMinX = (centerX - newHalfWidth).clamp(0.0, double.infinity);
                          double newMaxX = (centerX + newHalfWidth).clamp(newMinX + 10.0, double.infinity);

                          _minX = newMinX;
                          _maxX = newMaxX;
                        });
                      }
                    },
                    onHorizontalDragUpdate: (details) {
                      if (widget.isInteractive) {
                        setState(() {
                          final dragDelta = details.primaryDelta ?? 0.0;
                          final shift = dragDelta * (_maxX - _minX) / context.size!.width * _dragSensitivity;

                          final newMinX = (_minX - shift).clamp(0.0, double.infinity);
                          final newMaxX = (_maxX - shift).clamp(newMinX + 10.0, double.infinity);

                          _minX = newMinX;
                          _maxX = newMaxX;
                        });
                      }
                    },
                    // Restore the Graph to its original state
                    onDoubleTap: () {
                      if (widget.isInteractive) {
                        setState(() {
                          _yScale = 100.0;
                          _minX = 0;
                          _maxX = widget.sampleRate / 2; // Nyquist Rate Limit
                        });
                      }
                    },
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
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.25,
                            color: isDark ? const Color(0xFFD5D5D5) : const Color(0xFF1A1A1A),
                            barWidth: 0.8,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        minX: _minX,
                        maxX: _maxX,
                        minY: 0,
                        maxY: _yScale,
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            axisNameWidget: Text("Amplitude", style: TextStyle(fontFamily: Constants.fontFamilyBody, fontSize: 10),),
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  (value).toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 6),
                                );
                              }
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final displayValue = value >= 1000
                                    ? "${(value / 1000).toStringAsFixed(1)}k"
                                    : value.toStringAsFixed(0);
                                return Text(
                                  displayValue,
                                  style: const TextStyle(fontSize: 6),
                                );
                              },
                              ),
                            axisNameWidget: Text(
                              "Frequency Bin",
                              style: TextStyle(fontFamily: Constants.fontFamilyBody, fontSize: 10)),
                            ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
