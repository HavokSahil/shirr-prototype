

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shirr/components/menu_item.dart';
import 'package:shirr/core/constants.dart';

class MainMenuScreen extends StatefulWidget{

  const MainMenuScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {

  final TextStyle textStyleTitle = TextStyle(
    fontFamily: Constants.fontFamilyTitle,
    fontSize: Constants.fontSizeTitle,
    fontWeight: FontWeight.bold);
  final TextStyle textStyleSubHead = TextStyle(
    fontFamily: Constants.fontFamilySubHead,
    fontSize: Constants.fontSizeSubHead,
    fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return Scaffold(
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Name Title Text
                  Text(Constants.appName,
                    style: textStyleTitle,
                  ),

                  Text("Main Menu",
                    style: textStyleSubHead
                  ),
                  SizedBox(height: 20,),
                  MenuItemDisk(key: ValueKey("menu_aa"), menuType: MenuType.audioAnalyzer,),
                  SizedBox(height: 16,),
                  MenuItemDisk(key: ValueKey("menu_ag"), menuType: MenuType.audioGeneration,),
                  SizedBox(height: 16,),
                  MenuItemDisk(key: ValueKey("menu_av"), menuType: MenuType.audioVisualization,),
                ],
              ),
            ),
            SizedBox(height: 20,),
            Container(
              padding: EdgeInsets.all(2.0),
              alignment: Alignment.bottomCenter,
              child: Text("v${Constants.version} ${Constants.copyrightText}"),
            )
          ],
      ),
    );
  }
  
}

