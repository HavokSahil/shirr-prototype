import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shirr/core/constants.dart';


class MenuItemDisk extends StatefulWidget {

  final MenuType menuType;

  const MenuItemDisk({super.key, required this.menuType});

  @override
  State<MenuItemDisk> createState() => _MenuItemDiskState();

}

class _MenuItemDiskState extends State<MenuItemDisk> with SingleTickerProviderStateMixin{

  late final String menuIconPath;
  late final String menuName;
  late final TextStyle textStyle;

  late final Widget circleDarkBottom;
  late final Widget circleDarkMid;
  late final Widget circleDarkTop;
  late final Widget circleLightBottom;
  late final Widget circleLightMid;
  late final Widget circleLightTop;

  final double centerMid = (Constants.widthCircleBottom - Constants.widthCircleMid)/2;
  final double centerTop = (Constants.widthCircleBottom - Constants.widthCircleTop)/2;

  final double maxOffsetCenterMid = 5;
  final double maxOffsetCenterTop = 10;

  Offset offsetCenterMid = Offset.zero;
  Offset offsetCenterTop = Offset.zero;

  late AnimationController _controller;
  late Animation<Offset> _midReturn;
  late Animation<Offset> _topReturn;

  late final String routeString;

  late final AudioPlayer _audioPlayer;
  late final String assetSoundPath;

  @override
  void initState() {

    super.initState();

    // Preload the Font when the State is initialised
    textStyle = TextStyle(
      fontFamily: Constants.fontFamilyBody,
      fontSize: Constants.fontSizeBody,
      fontWeight: FontWeight.bold);

    // Preload the SVG's when the State is initialised
    circleDarkBottom = SvgPicture.asset(Constants.pathCircleDarkBottom,
      height: Constants.widthCircleBottom,
      width: Constants.widthCircleBottom);
    circleDarkMid = SvgPicture.asset(Constants.pathCircleDarkMid,
      height: Constants.widthCircleMid,
      width: Constants.widthCircleMid);
    circleDarkTop = SvgPicture.asset(Constants.pathCircleDarkTop,
      height: Constants.widthCircleTop,
      width: Constants.widthCircleTop);

    // Preload the SVG's when the State is initialised
    circleLightBottom = SvgPicture.asset(Constants.pathCircleLightBottom,
      height: Constants.widthCircleBottom,
      width: Constants.widthCircleBottom);
    circleLightMid = SvgPicture.asset(Constants.pathCircleLightMid,
      height: Constants.widthCircleMid,
      width: Constants.widthCircleMid);
    circleLightTop = SvgPicture.asset(Constants.pathCircleLightTop,
      height: Constants.widthCircleTop,
      width: Constants.widthCircleTop);

    // Get the Path of the Menu Icon
    switch(widget.menuType) {
      case MenuType.audioAnalyzer: {
        menuIconPath = Constants.pathIconMenuAA;
        menuName = "Audio Analysis";
        routeString = Constants.routeAudioAnalyzer;
        assetSoundPath = Constants.pathSoundChord1;
      } break;
      case MenuType.audioGeneration: {
        menuIconPath = Constants.pathIconMenuAG;
        menuName = "Music Generation";
        routeString = Constants.routeAudioGenerator;
        assetSoundPath = Constants.pathSoundChord2;
      } break;
      case MenuType.audioVisualization: {
        menuIconPath = Constants.pathIconMenuAV;
        menuName = "Visualize";
        routeString = Constants.routeAudioVisualizer;
        assetSoundPath = Constants.pathSoundChord3;
      } break;
    }

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _controller.addListener(() {
      offsetCenterMid = _midReturn.value;
      offsetCenterTop = _topReturn.value;
    });

    _audioPlayer = AudioPlayer();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      offsetCenterMid += details.delta / 2;
      offsetCenterTop += details.delta;

      // Clamp the offsets of Mid Circle
      offsetCenterMid = Offset(
        offsetCenterMid.dx.clamp(-maxOffsetCenterMid, maxOffsetCenterMid),
        offsetCenterMid.dy.clamp(-maxOffsetCenterMid, maxOffsetCenterMid));

      // Clamp the offsets of the Top Circle
      offsetCenterTop = Offset(
        offsetCenterTop.dx.clamp(-maxOffsetCenterTop, maxOffsetCenterTop),
        offsetCenterTop.dy.clamp(-maxOffsetCenterTop, maxOffsetCenterTop));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _midReturn = Tween<Offset>(begin: offsetCenterMid, end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _topReturn = Tween<Offset>(begin: offsetCenterTop, end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  void _playSound() async {
    await _audioPlayer.play(AssetSource(assetSoundPath));
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final currentTheme = Theme.of(context);
    final brightness = currentTheme.brightness;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: () {
        _playSound();
        Navigator.pushNamed(context, routeString);
      },
      child: SizedBox(
        height: 150,
        width: 150,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: (brightness == Brightness.light)? circleLightBottom: circleDarkBottom,
            ),
            Positioned(
              top: centerMid + offsetCenterMid.dy,
              left: centerMid + offsetCenterMid.dx,
              child: (brightness == Brightness.light)? circleLightMid: circleDarkMid,
              ),
            Positioned(
              top: centerTop + offsetCenterTop.dy,
              left: centerTop + offsetCenterTop.dx,
              child:  (brightness == Brightness.light)? circleLightTop: circleDarkTop,
            ),
            Center(
              child: SvgPicture.asset(menuIconPath,),
            ),
            Positioned(
              bottom: 0,
              width: 150,
              child: Text(menuName, style: textStyle, textAlign: TextAlign.center,),
            )
          ],
        ),
      ),
    );
  }
}