import 'package:fiberchat/Configs/app_constants.dart';
import 'package:flutter/material.dart';

class Splashscreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IsSplashOnlySolidColor == true
        ? Scaffold(
            backgroundColor: SplashBackgroundSolidColor,
            body: Center(
              child: CircularProgressIndicator(
                  valueColor:
                      //AlwaysStoppedAnimation<Color>(fiberchatLightGreen)),
                AlwaysStoppedAnimation<Color>(fiberchatLightGreen)),

    ))
        : Scaffold(
            backgroundColor: SplashBackgroundSolidColor,
            body: Center(
                child: Image.asset(
              '$SplashPath',
              fit: BoxFit.cover,
            )),
          );
  }
}
