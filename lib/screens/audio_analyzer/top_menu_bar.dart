import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shirr/core/constants.dart';

class TopMenuBar extends StatelessWidget {
  TopMenuBar({
    required this.panelPrimary,
    required this.panelSecondary,
    required this.size,
    required this.callbackChoosePlots,
    required this.callbackInteract,
    required this.callbackHelp,
    required this.isInteractive,
    super.key
  });

  final Color panelPrimary, panelSecondary;
  final Size size;

  final bool isInteractive;

  final Widget iconOptions = SvgPicture.asset(Constants.pathIconBtnOptions, height: 48, width: 48);
  final Widget iconInteract = SvgPicture.asset(Constants.pathIconBtnInteract, height: 48, width: 48);
  final Widget iconHelp = SvgPicture.asset(Constants.pathIconBtnHelp, height: 48, width: 48);

  final Function callbackChoosePlots;
  final Function callbackInteract;
  final Function callbackHelp;

  final factorMenuBranch = 0.6;
  final menuBranchHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: size.width * factorMenuBranch,
        height: menuBranchHeight,
        decoration: BoxDecoration(
          color: panelPrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(42),
            bottomLeft: Radius.circular(42),
          ),
          border: Border(
            top: BorderSide(color: panelSecondary, width: 5),
            left: BorderSide(color: panelSecondary, width: 5),
            bottom: BorderSide(color: panelSecondary, width: 5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: !isInteractive? Colors.white.withAlpha(128): panelPrimary,
                  blurRadius: !isInteractive? 16: 0,
                  spreadRadius: !isInteractive?0.5: 0, 
                )]
              ),
              child: IconButton(onPressed: () => callbackInteract(), icon: iconInteract, tooltip: "Interactive"),
            ),
            IconButton(onPressed: () => callbackChoosePlots(), icon: iconOptions, tooltip: "Choose Plots"),
            IconButton(onPressed: () => callbackHelp(), icon: iconHelp, tooltip: "Help"),
          ],
        ),
      ),
    );
  }
}
