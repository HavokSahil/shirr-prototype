import 'dart:collection';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';

class DecibelLoudnessCard extends StatefulWidget {
  final bool isInteractive;
  final Stream<List<double>> pcmBuffer;

  const DecibelLoudnessCard({
    super.key,
    required this.isInteractive,
    required this.pcmBuffer,
  });

  @override
  State<DecibelLoudnessCard> createState() => _DecibelLoudnessCardState();
}

class _DecibelLoudnessCardState extends State<DecibelLoudnessCard> {
  static const int maxRmsFrames = 200;
  static const double epsilon = 1e-10;
  static const double dBMin = -80.0;
  final Queue<double> _rmsQueue = ListQueue<double>.from(
    List.filled(maxRmsFrames, dBMin),
  );

  double _yScale = 100.0;
  double _minX = 0.0;
  double _maxX = maxRmsFrames.toDouble();
  final double _dragSensitivity = 1.0;

  void _updateRms(List<double> buffer) {
    // Calculate RMS
    final double rms = sqrt(buffer.map((x) => x * x).reduce((a, b) => a + b) / buffer.length);
    final double db = 20 * log(rms.clamp(epsilon, 1.0)) / ln10;

    // Update RMS queue
    if (_rmsQueue.length >= maxRmsFrames) {
      _rmsQueue.removeFirst();
    }
    _rmsQueue.add(db.clamp(dBMin, 0.0));
  }

  List<FlSpot> get _rmsSpots {
    final List<double> values = _rmsQueue.toList();
    return List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
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
            final buffer = snapshot.data;
            if (buffer != null && buffer.isNotEmpty) {
              _updateRms(buffer);
            }

            final spots = _rmsSpots;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8),
                  child: Text(
                    "RMS Loudness (dB)",
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
                          _yScale /= details.verticalScale.clamp(0.97, 1.03);
                          _yScale = _yScale.clamp(1.0, 100.0);

                          double centerX = (_minX + _maxX) / 2;
                          double halfWidth = (_maxX - _minX) / 2;
                          double newHalfWidth = halfWidth / details.horizontalScale.clamp(0.95, 1.05);
                          double newMinX = (centerX - newHalfWidth).clamp(0.0, maxRmsFrames.toDouble());
                          double newMaxX = (centerX + newHalfWidth).clamp(newMinX + 10.0, maxRmsFrames.toDouble());
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
                          final newMinX = (_minX - shift).clamp(0.0, maxRmsFrames.toDouble());
                          final newMaxX = (_maxX - shift).clamp(newMinX + 10.0, maxRmsFrames.toDouble());
                          _minX = newMinX;
                          _maxX = newMaxX;
                        });
                      }
                    },
                    onDoubleTap: () {
                      if (widget.isInteractive) {
                        setState(() {
                          _minX = 0.0;
                          _maxX = maxRmsFrames.toDouble();
                          _yScale = 100.0;
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
                                  "(${spot.x.toStringAsFixed(0)}, ${spot.y.toStringAsFixed(1)} dB)",
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
                        minY: -_yScale,
                        maxY: 0.0,
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
                              "dB (RMS)",
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
                                  "${value.toStringAsFixed(0)} dB",
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
              ],
            );
          },
        ),
      ),
    );
  }
}
