import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shirr/components/disk_dialogue.dart';
import 'package:shirr/core/constants.dart';
import 'package:shirr/screens/audio_analyzer/bottom_menu_bar.dart';
import 'package:shirr/screens/audio_analyzer/circular_icon_button.dart';
import 'package:shirr/screens/audio_analyzer/dialogues.dart';
import 'package:shirr/screens/audio_analyzer/plot_page_view.dart';
import 'package:shirr/screens/audio_analyzer/theme_colors.dart';
import 'package:shirr/screens/audio_analyzer/top_menu_bar.dart';
import 'package:shirr/services/mic_controller.dart';

GlobalKey repaintKey = GlobalKey();

enum StreamSource{ mic, file }

class AudioAnalyzerScreen extends StatefulWidget {
  const AudioAnalyzerScreen({super.key});

  @override
  State<AudioAnalyzerScreen> createState() => AudioAnalyzerScreenState();
}

class AudioAnalyzerScreenState extends State<AudioAnalyzerScreen> with SingleTickerProviderStateMixin {

  double sliderValue = 0.5;

  late Widget iconDisk;
  late Widget iconMic;
  late Widget iconOptions;
  late Widget iconReset;
  late Widget iconHelp;
  late Widget iconSave;
  late Widget iconPlay;
  late Widget iconFocus;

  late PageController _pageController;
  late final AnimationController _animationController;
  // late final WavController _wavController;
  late final MicController _micController;

  // UI Constants
  final factorFlanksHeight = 0.4;
  final factorFlanksWidth = 0.08;
  final factorMenuBranch = 0.6;
  final menuBranchHeight = 72.0;
  final factorPlotWidth = 0.8;
  final factorPlotHeight = 0.7;

  // UI Contexts
  bool isSwipeLocked = false;
  bool isListening = false;
  bool isInteractive = false;

  @override
  void initState() {
    super.initState();
    _micController = MicController();
    _pageController = PageController(viewportFraction: 0.95);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 8),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && isListening) {
        _animationController.repeat();
      }
    });

    iconPlay = SvgPicture.asset(Constants.pathIconPlayLight, height: 64, width: 64);
    iconFocus = SvgPicture.asset(Constants.pathIconBtnFocus, height: 64, width: 64);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void lockSwipe() {
    setState(() {
      isSwipeLocked = !isSwipeLocked;
    });
  }

  void toggleListening() async {
    if (isListening) {
      _micController.stop().then(
        (_) {
          setState(() {
            isListening = false;
            _animationController.stop();
          });
        } 
      );
    } else {
      _micController.listening().then(
        (_) {
          setState(() {
            isListening = true;
            _animationController.repeat();
          });
        }
      );
    } 
  }

  void toggleInteractive() {
    setState(() {
      isInteractive = !isInteractive;
    });
  }

  PageRouteBuilder handleClickDisk() {
    return PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => const DiskDialogue(message: "This feature is under development")
    );
  } 

  void handleClickMic() {
    setState(() {
      // Stop the playback on change of source
      if (isListening) toggleListening();
    });
  }


  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: CircularIconButton(icon: iconFocus, tooltip: "Focus", onPressed: lockSwipe, isGlowing: isSwipeLocked, color: colors.textColor)
                    ),
                  ),
                  // Top Menu Bar
                  TopMenuBar(
                    panelPrimary: colors.panelPrimary,
                    panelSecondary: colors.panelSecondary,
                    size: size,
                    isInteractive: isInteractive,
                    callbackChoosePlots: () => showPlotSelectorDialog(context, _pageController),
                    callbackHelp: () => onPressHelp(context),
                    callbackInteract: () => toggleInteractive(),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Central Plot Area
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: 360,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: size.width * factorFlanksWidth,
                        height: size.height * factorFlanksHeight,
                        decoration: BoxDecoration(
                          color: colors.flanks,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          border: Border(
                            top: BorderSide(color: colors.panelSecondary, width: 5),
                            right: BorderSide(color: colors.panelSecondary, width: 5),
                            bottom: BorderSide(color: colors.panelSecondary, width: 5),
                          ),
                        ),
                      ),

                      Container(
                        width: size.width * factorPlotWidth,
                        height: size.height * factorPlotHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        child: PlotPageView(
                          isSwipeLocked: isSwipeLocked,
                          repaintKey: repaintKey,
                          pcmBuffer: _micController.audioDataStream, // Only Microphone stream for now
                          isInteractive: isInteractive, 
                          pageController: _pageController,
                          sampleRate: _micController.sampleRate,
                        ),
                      ),

                      Container(
                        width: size.width * factorFlanksWidth,
                        height: size.height * factorFlanksHeight,
                        decoration: BoxDecoration(
                          color: colors.flanks,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                          border: Border(
                            top: BorderSide(color: colors.panelSecondary, width: 5),
                            left: BorderSide(color: colors.panelSecondary, width: 5),
                            bottom: BorderSide(color: colors.panelSecondary, width: 5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Slider
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbColor: colors.sliderDot,
                    activeTrackColor: colors.sliderDot,
                    inactiveTrackColor: colors.sliderTrack,
                    overlayColor: Colors.white.withAlpha(200),
                  ),
                  child: Slider(
                    value: sliderValue,
                    onChanged: (val) {
                      setState(() {
                        sliderValue = val;
                      });
                    },
                    min: 0,
                    max: 5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Menu Bar with Glowing Play Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  // Bottom left menu
                  BottomMenuBar(
                    panelPrimary: colors.panelPrimary,
                    panelSecondary: colors.panelSecondary,
                    size: size, 
                    callBackSave: () => onSavePress(context, repaintKey), 
                    callbackMic: () => handleClickMic(),
                    callbackDisk: () => Navigator.push(context, handleClickDisk()),
                  ),
                  // Play Button
                  Expanded(
                    child: 
                      Align(
                        alignment: Alignment.center,
                        child: RotationTransition(
                          turns: _animationController,
                          child: CircularIconButton(icon: iconPlay, tooltip: "Play", onPressed: toggleListening, isGlowing: isListening, color: colors.textColor),
                        ),
                    )
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
