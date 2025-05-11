import 'dart:math';

import 'package:fftea/impl.dart';
import 'package:flutter/material.dart';

class MfccHeatMapCard extends StatefulWidget {
  final int sampleRate;
  final Stream<List<double>> pcmBuffer;
  final int maxFrames;

  const MfccHeatMapCard({
    super.key,
    required this.sampleRate,
    required this.pcmBuffer,
    this.maxFrames = 64,
  });

  @override
  State<MfccHeatMapCard> createState() => _MfccHeatMapCardState();
}

class _MfccHeatMapCardState extends State<MfccHeatMapCard> {
  late final MFCCcalc _mfccCalc;

  @override
  void initState() {
    super.initState();
    _mfccCalc = MFCCcalc(sampleRate: widget.sampleRate);
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              "MFCC Heatmap",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: StreamBuilder<List<double>>(
                    stream: widget.pcmBuffer,
                    builder: (context, snapshot) {
                      final buffer = snapshot.data ?? [];
                      final mfccFrames = _mfccCalc.extractMFCCs(buffer);

                      return CustomPaint(
                        painter: MfccHeatMapPainter(
                          mfccFrames: mfccFrames,
                          isDark: isDark,
                          padding: 4.0,
                          borderRadius: 10.0,
                        ),
                        child: SizedBox.expand(),
                      );
                    },
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}


class MfccHeatMapPainter extends CustomPainter {
  final List<List<double>> mfccFrames;
  final bool isDark;
  final double padding;
  final double borderRadius;

  MfccHeatMapPainter({
    required this.mfccFrames,
    required this.isDark,
    this.padding = 4.0,
    this.borderRadius = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final nFrames = mfccFrames.length;
    final nCoeffs = mfccFrames.isNotEmpty ? mfccFrames[0].length : 0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    canvas.clipRRect(rrect); // Clip to rounded corners

    final double width = size.width - 2 * padding;
    final double height = size.height - 2 * padding;

    final cellWidth = width / (nFrames == 0 ? 1 : nFrames);
    final cellHeight = height / (nCoeffs == 0 ? 1 : nCoeffs);

    final minVal = 0.0;
    final maxVal = 1.0;

    for (int x = 0; x < nFrames; x++) {
      for (int y = 0; y < nCoeffs; y++) {
        final value = mfccFrames[x][y];
        final norm = (value - minVal) / (maxVal - minVal + 1e-8);
        paint.color = isDark? Color.lerp(Color(0xFFF0F0F0), Color(0xFF1E1E1E), norm)! : Color.lerp(Color(0xFF1E1E1E), Color(0xFFF0F0F0), norm)!;

        canvas.drawRect(
          Rect.fromLTWH(
            padding + x * cellWidth,
            padding + y * cellHeight,
            cellWidth,
            cellHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MfccHeatMapPainter oldDelegate) =>
      oldDelegate.mfccFrames != mfccFrames;
}


class MFCCcalc {
  final double _preImphasisFactors = 0.3;
  final List<double> _buffer = List<double>.filled(6400, 0.0);
  final int overlap = 2; // Samples
  final int frameDivisionFactor = 8;
  final int numFilters = 12;

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
