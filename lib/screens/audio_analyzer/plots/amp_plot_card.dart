import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';

class AmpPlotCard extends StatefulWidget {
  final bool isInteractive;
  final Stream<List<double>> pcmBuffer;

  const AmpPlotCard({
    super.key,
    required this.isInteractive,
    required this.pcmBuffer
  });

  @override
  State<AmpPlotCard> createState() => _AmpPlotCardState();
}

class _AmpPlotCardState extends State<AmpPlotCard> {
  double _yScale = 100.0;
  // X zoom & pan state
  double _minX = 0.0;
  double _maxX = 6400.0;

  final double _dragSensitivity = 1.0;

  List<FlSpot> _toFlSpots(List<double> buffer) {
    const double scale = 100.0;
    return List.generate(
      buffer.length,
      (i) => FlSpot(i.toDouble(), buffer[i] * scale),
    );
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
            final spots = _toFlSpots(buffer);

            // Reset X range on new data
            if (_maxX > buffer.length.toDouble()) {
              _minX = 0.0;
              _maxX = buffer.length.toDouble();
            }

            return Column(
              children: [
                 Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8),
                  child: Text(
                    "Amplitude Waveform",
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
                    // Handle Y-scale
                    if (widget.isInteractive) {
                      setState(() {
                        _yScale /= details.verticalScale.clamp(0.97, 1.03);
                        _yScale = _yScale.clamp(1.0, 100.0);
                        // X-Axis Zoom (adjust frequency window)
                        double centerX = (_minX + _maxX) / 2;
                        double halfWidth = (_maxX - _minX) / 2;
                        double newHalfWidth = halfWidth / details.horizontalScale.clamp(0.95, 1.05);
                        double newMinX = (centerX - newHalfWidth).clamp(0.0, buffer.length.toDouble());
                        double newMaxX = (centerX + newHalfWidth).clamp(newMinX + 10.0, buffer.length.toDouble());
                        _minX = newMinX;
                        _maxX = newMaxX;
                      });
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (widget.isInteractive) {
                      setState(() {
                        final dragDelta = details.primaryDelta??0;
                        final shift = dragDelta * (_maxX - _minX) / context.size!.width * _dragSensitivity;
                        final newMinX = (_minX - shift).clamp(0.0, buffer.length.toDouble());
                        final newMaxX = (_maxX - shift).clamp(newMinX + 10.0, buffer.length.toDouble());
                        _minX = newMinX;
                        _maxX = newMaxX;
                      });
                    }     
                  },
                  onDoubleTap: () {
                    if (widget.isInteractive) {
                      setState(() {
                        _minX = 0.0;
                        _maxX = buffer.length.toDouble();
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
                      minX: _minX,
                      maxX: _maxX,
                      minY: -_yScale,
                      maxY: _yScale,
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
                            "Amplitude",
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
                              "Index",
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
