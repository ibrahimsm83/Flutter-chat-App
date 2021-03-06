import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Screens/homepage/homepage.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Screens/calling_screen/audio_call.dart';
import 'package:fiberchat/Screens/calling_screen/video_call.dart';
import 'package:fiberchat/widgets/Common/cached_image.dart';
import 'package:fiberchat/Utils/open_settings.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:fiberchat/Models/call.dart';
import 'package:fiberchat/Models/call_methods.dart';
import 'package:fiberchat/Utils/permissions.dart';

// ignore: must_be_immutable
class PickupScreen extends StatelessWidget {
  final Call call;
  final String currentuseruid;
  final CallMethods callMethods = CallMethods();

  PickupScreen({
    @required this.call,
    @required this.currentuseruid,
  });
  ClientRole _role = ClientRole.Broadcaster;
  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: fiberchatgreen,
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: w > h ? 60 : 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              w > h
                  ? SizedBox(
                      height: 0,
                    )
                  : Icon(
                      call.isvideocall == true
                          ? Icons.videocam_outlined
                          : Icons.mic,
                      size: 80,
                      color: Colors.white30,
                    ),
              w > h
                  ? SizedBox(
                      height: 0,
                    )
                  : SizedBox(
                      height: 20,
                    ),
              Text(
                call.isvideocall == true
                    ? getTranslated(context, 'incomingvideo')
                    : getTranslated(context, 'incomingaudio'),
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.white54,
                ),
              ),
              SizedBox(height: w > h ? 16 : 50),
              CachedImage(
                call.callerPic,
                isRound: true,
                height: w > h ? 60 : 110,
                width: w > h ? 60 : 110,
                radius: w > h ? 70 : 138,
              ),
              SizedBox(height: 15),
              Text(
                call.callerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: w > h ? 30 : 75),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RawMaterialButton(
                    onPressed: () async {
                      flutterLocalNotificationsPlugin.cancelAll();
                      await callMethods.endCall(call: call);
                      usersCollection
                          .doc(call.callerId)
                          .collection(CALL_HISTORY_COLLECTION)
                          .doc(call.timeepoch.toString())
                          .set({
                        'STATUS': 'rejected',
                        'ENDED': DateTime.now(),
                      }, SetOptions(merge: true));
                      usersCollection
                          .doc(call.receiverId)
                          .collection(CALL_HISTORY_COLLECTION)
                          .doc(call.timeepoch.toString())
                          .set({
                        'STATUS': 'rejected',
                        'ENDED': DateTime.now(),
                      }, SetOptions(merge: true));
                      //----------
                      await usersCollection
                          .doc(call.receiverId)
                          .collection('recent')
                          .doc('callended')
                          .set(
                        {
                          'id': call.receiverId,
                          'ENDED': DateTime.now().millisecondsSinceEpoch
                        },
                      );
                    },
                    child: Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 35.0,
                    ),
                    shape: CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.redAccent,
                    padding: const EdgeInsets.all(15.0),
                  ),
                  SizedBox(width: 45),
                  RawMaterialButton(
                    onPressed: () async {
                      flutterLocalNotificationsPlugin.cancelAll();
                      await Permissions.cameraAndMicrophonePermissionsGranted()
                          .then((isgranted) async {
                        if (isgranted == true) {
                          print('call okhey h');
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => call.isvideocall == true
                                  ? VideoCall(
                                      currentuseruid: currentuseruid,
                                      call: call,
                                      channelName: call.channelId,
                                      role: _role,
                                    )
                                  : AudioCall(
                                      currentuseruid: currentuseruid,
                                      call: call,
                                      channelName: call.channelId,
                                      role: _role,
                                    ),
                            ),
                          );
                        } else {
                          Fiberchat.showRationale(
                              getTranslated(context, 'pmc'));
                          Navigator.push(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => OpenSettings()));
                        }
                      }).catchError((onError) {
                        Fiberchat.showRationale(getTranslated(context, 'pmc'));
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => OpenSettings()));
                      });
                    },
                    child: Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 35.0,
                    ),
                    shape: CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.green,
                    //fillColor: ,
                    padding: const EdgeInsets.all(15.0),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  //  Future<void> onJoin() async {
  //   // update input validation
  //   setState(() {
  //     _channelController.text.isEmpty
  //         ? _validateError = true
  //         : _validateError = false;
  //   });
  //   if (_channelController.text.isNotEmpty) {
  //     await _handleCameraAndMic(PermissionGroup.camera);
  //     await _handleCameraAndMic(PermissionGroup.microphone);
  //     await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => VideoCall(
  //           channelName: _channelController.text,
  //           role: _role,
  //         ),
  //       ),
  //     );
  //   }
  // }

  // Future<void> _handleCameraAndMic(PermissionGroup permission) async {
  //   final status = await permission.value;
  //   print(status);
  // }
}
