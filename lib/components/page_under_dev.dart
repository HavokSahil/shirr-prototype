import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';

class PageUnderDevScreen extends StatelessWidget {

  final String pageName;

  const PageUnderDevScreen({super.key, required this.pageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        child: Center(
          child: Text(
            "Page `$pageName` is currently under development.",
            style: TextStyle(
              fontFamily: Constants.fontFamilyTitle,
              fontSize: Constants.fontSizeSubHead
            ),
            textAlign: TextAlign.center,),
        ),
      ),
    );
  }
}