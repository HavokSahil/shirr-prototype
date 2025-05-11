import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shirr/core/constants.dart';

class BottomMenuBar extends StatelessWidget {
  BottomMenuBar({
    required this.panelPrimary,
    required this.panelSecondary,
    required this.size,
    required this.callBackSave,
    required this.callbackMic,
    required this.callbackDisk,
    super.key
  });

  final Color panelPrimary, panelSecondary;
  final Size size;

  final Function callBackSave;
  final Function callbackMic;
  final Function callbackDisk;

  final iconDisk = SvgPicture.asset(Constants.pathIconBtnDisk, height: 48, width: 48);
  final iconMic = SvgPicture.asset(Constants.pathIconBtnMic, height: 48, width: 48);
  final iconSave = SvgPicture.asset(Constants.pathIconBtnSave, height: 48, width: 48);

  final factorMenuBranch = 0.6;
  final menuBranchHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: menuBranchHeight,
      width: size.width * factorMenuBranch,
      decoration: BoxDecoration(
        color: panelPrimary,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
        border: Border(
          top: BorderSide(color: panelSecondary, width: 5),
          right: BorderSide(color: panelSecondary, width: 5),
          bottom: BorderSide(color: panelSecondary, width: 5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(onPressed: () => callBackSave(), icon: iconSave, tooltip: "Export"),
          IconButton(onPressed: () => callbackMic(), icon: iconMic, tooltip: "Mic"),
          IconButton(onPressed: () => callbackDisk(), icon: iconDisk, tooltip: "Choose Audio"),
        ],
      ),
    );
  }
}