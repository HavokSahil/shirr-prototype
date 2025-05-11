import 'dart:math';

import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';
// import 'package:shirr/services/mic_controller.dart';

class BeatTrackerCard extends StatefulWidget {
  final bool isInteractive;
  final Stream<List<double>> pcmBuffer;

  const BeatTrackerCard({
    super.key,
    required this.isInteractive,
    required this.pcmBuffer
  });

  @override
  State<BeatTrackerCard> createState() => _BeatTrackerCardState();
}

class _BeatTrackerCardState extends State<BeatTrackerCard> {
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


class MFCCcalc {
  final double _preImphasisFactors = 0.3;
  final List<double> _buffer = List<double>.filled(6400, 0.0);
  final int overlap = 20; // Samples
  final int frameDivisionFactor = 20;
  final int numFilters = 20;

  final int sampleRate;
  MFCCcalc({
    required this.sampleRate,
  });

  static double hzToMel(double hz) => 2595 * log(1 + hz / 700) / ln10;
  static double melToHz(double mel) => 700 * (pow(10, mel / 2595) - 1);

  List<double> prepareBuff(List<double> buff) {
    if (buff.length < _buffer.length) {
      // Extend the buffer to the length
      int rem = _buffer.length - buff.length;
      buff = [...List.filled(rem, 0),...buff];
      return buff;
    } else if (buff.length > _buffer.length) {
      int rem = buff.length - _buffer.length;
      return buff.sublist(rem, buff.length);
    }
    return buff;
  }

  void preImphasis(List<double> buff) {
    assert(buff.length == _buffer.length);
    for (int i = buff.length - 1; i >= 1; i--) {
      buff[i] = buff[i] - _preImphasisFactors * buff[i - 1];
    }
    buff[0] = buff[0]; // Or multiply by a constant
  }

  List<List<double>> divideIntoFrames(List<double> buff) {
    int width = (buff.length / frameDivisionFactor).floor();
    int stride = width - overlap;
    if (stride <= 0) throw Exception('Invalid width computed: $width');
    
    List<List<double>> frames = [];

    for (int i = 0; i + width <= buff.length; i += stride) {
      frames.add(buff.sublist(i, i + width));
    }
    return frames;
  }

  void hammingWindowing(List<List<double>> frames) {
    // returns windowed frames
    for (int i = 0; i<frames.length; i++) {
      int N = frames[i].length;
      for (int j = 0; j<frames[i].length; j++) {
        frames[i][j]*= (0.54 - 0.46*cos(2*pi*j/(N-1)));
      }
    }
  }

  List<List<double>> powerSpectrumFFT(List<List<double>> frames) {
    final int N = frames[0].length;
    final fft = FFT(N); // assuming all frames have same length
    List<List<double>> powerSpec = [];

    for (var frame in frames) {
      final freqDomain = fft.realFft(frame);
      final half = freqDomain.length ~/ 2;

      List<double> power = List.generate(half, (j) {
        final re = freqDomain[j].x;
        final im = freqDomain[j].y;
        return (re * re + im * im) / N;
      });

      powerSpec.add(power);
    }

    return powerSpec;
  }

  (double, double) melScale(List<double> frame) {
    final nyquist = sampleRate / 2;
    final mMin = 0.0;
    final mMax = 2595 * log(1 + nyquist / 700) / ln10;
    return (mMin, mMax);
  }
  
  List<List<double>> buildFilterBank(int fftSize, int sampleRate) {
    final nyquist = sampleRate/2;
    final melMin = hzToMel(0.0);
    final melMax = hzToMel(nyquist);
    final melPoints = List.generate(numFilters+2, (i) => 
      melMin + i * (melMax - melMin)/(numFilters + 1)
    );
    // Convert mel points back to hertz
    final hzPoints = melPoints.map(melToHz).toList();
    // Convert hertz points to FFT bin index
    final binPoints = hzPoints.map((hz) => 
      (hz * fftSize / sampleRate).floor()
    ).toList();

    List<List<double>> filterBank = [];

    for (int i = 0; i<numFilters; i++) {
      final filter = List<double>.filled(fftSize, 0.0);
      int left = binPoints[i];
      int center = binPoints[i+1];
      int right = binPoints[i+2];

      for (int j = left; j<center; j++) {
        if (j > 0 && j < fftSize) {
          filter[j] = (j - left) / (center - left);
        }
      }
      for (int j = center; j < right; j++) {
        if (j > 0 && j < fftSize) {
          filter[j] = (right - j) / (right - center);
        }
      }
      filterBank.add(filter);
    }
    return filterBank;
  }

  List<List<double>> applyFilterBank(List<List<double>> powerSpecs) {
    final filters = buildFilterBank(powerSpecs[0].length, sampleRate);
    List<List<double>> melEnergiesPerFrame = [];

    for (var powerSpec in powerSpecs) {
      List<double> energies = filters.map((filter) {
        double energy = 0.0;
        for (int i = 0; i < filter.length; i++) {
          energy += filter[i] * powerSpec[i];
        }
        return energy;
      }).toList();
      melEnergiesPerFrame.add(energies);
    }

    return melEnergiesPerFrame;
  }


  List<double> logEnergy(List<double> melEnergies) {
    const double epsilon = 1e-10;
    return melEnergies.map((power) => 
      log(power + epsilon)
    ).toList();
  }

  List<double> dct(List<double> logE, int numCoeffs) {
    int M = logE.length;
    List<double> mfccs = List<double>.filled(numCoeffs, 0.0);

    for  (int k = 0; k < numCoeffs; k++) {
      double sum =  0.0;
      for (int m = 0; m < M; m++) {
        sum += logE[m] * cos(pi * k * (m + 0.5)/M);
      }
      mfccs[k] = sum;
    }
    return mfccs;
  }

  List<List<double>> extractMFCCs(List<double> input, {int numCoeffs = 13}) {
    final buff = prepareBuff(input);
    preImphasis(buff);
    final frames = divideIntoFrames(buff);
    hammingWindowing(frames);
    final powerSpecs = powerSpectrumFFT(frames);
    final melEnergies = applyFilterBank(powerSpecs);

    List<List<double>> mfccsPerFrame = [];

    for (var mel in melEnergies) {
      final logMel = logEnergy(mel);
      final mfcc = dct(logMel, numCoeffs);
      mfccsPerFrame.add(mfcc);
    }

    return mfccsPerFrame;
  }
}
