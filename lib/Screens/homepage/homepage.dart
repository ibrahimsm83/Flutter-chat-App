import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Screens/StatusScreen.dart';
import 'package:fiberchat/Screens/news_screens/NewsScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as local;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Screens/auth_screens/login.dart';
import 'package:fiberchat/Services/Providers/currentchat_peer.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Screens/settings_screen/settings.dart';
import 'package:fiberchat/main.dart';
import 'package:fiberchat/Screens/recent_chats/RecentsChats.dart';
import 'package:fiberchat/Screens/search_chats/SearchChat.dart';
import 'package:fiberchat/Screens/call_history/callhistory.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Services/Providers/user_provider.dart';
import 'package:fiberchat/Screens/calling_screen/pickup_layout.dart';
import 'package:fiberchat/Utils/chat_controller.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Homepage extends StatefulWidget {
  Homepage(
      {@required this.currentUserNo, @required this.isSecuritySetupDone, key})
      : super(key: key);
  final String currentUserNo;
  final bool isSecuritySetupDone;
  @override
  State createState() => new HomepageState(currentUserNo: this.currentUserNo);
}

class HomepageState extends State<Homepage>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin,
        SingleTickerProviderStateMixin {
  HomepageState({Key key, this.currentUserNo}) {
    _filter.addListener(() {
      _userQuery.add(_filter.text.isEmpty ? '' : _filter.text);
    });
  }
  TabController controller;
  @override
  bool get wantKeepAlive => true;

  SharedPreferences prefs;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      setIsActive();
    else
      setLastSeen();
  }

  void setIsActive() async {
    if (currentUserNo != null)
      await FirebaseFirestore.instance
          .collection(USERS)
          .doc(currentUserNo)
          .set({LAST_SEEN: true}, SetOptions(merge: true));
  }

  void setLastSeen() async {
    if (currentUserNo != null)
      await FirebaseFirestore.instance.collection(USERS).doc(currentUserNo).set(
          {LAST_SEEN: DateTime.now().millisecondsSinceEpoch},
          SetOptions(merge: true));
  }

  final TextEditingController _filter = new TextEditingController();
  bool isAuthenticating = false;

  StreamSubscription spokenSubscription;
  List<StreamSubscription> unreadSubscriptions = List<StreamSubscription>();

  List<StreamController> controllers = new List<StreamController>();

  @override
  void initState() {
    super.initState();
    registerNotification();
    controller = TabController(length: 4, vsync: this);
    controller.index = 1;

    Fiberchat.internetLookUp();
    WidgetsBinding.instance.addObserver(this);

    listenToNotification();

    LocalAuthentication().canCheckBiometrics.then((res) {
      if (res) biometricEnabled = true;
    });
    getModel();
    getSignedInUserOrRedirect();
  }

  void registerNotification() async {
    // 1. Initialize the Firebase app
    // await Firebase.initializeApp();

    // 2. On iOS, this helps to take the user permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
  }

  getuid(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    userProvider.getUserDetails(currentUserNo);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    controllers.forEach((controller) {
      controller.close();
    });
    _filter.dispose();
    spokenSubscription?.cancel();
    _userQuery.close();
    cancelUnreadSubscriptions();
    setLastSeen();
  }

  void cancelUnreadSubscriptions() {
    unreadSubscriptions.forEach((subscription) {
      subscription?.cancel();
    });
  }

  void listenToNotification() async {
    //FOR ANDROID  background notification is handled here whereas for iOS it is handled at the very top of main.dart ------
    if (Platform.isAndroid) {
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandlerAndroid);
    }
    //ANDROID & iOS  OnMessage callback
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('onmessagecallback');
      if (message.data != null) {
        if (message.data['title'] == 'Call Ended') {
          flutterLocalNotificationsPlugin..cancelAll();
        } else {
          if (message.data['title'] == 'Incoming Audio Call...' ||
              message.data['title'] == 'Incoming Video Call...') {
            if (message.data != null) {
              final data = message.data;

              final title = data['title'];
              final body = data['body'];

              await _showNotificationWithDefaultSound(title, body);
            }
          } else if (message.data['title'] == 'You have new message(s)') {
            var currentpeer =
                Provider.of<CurrentChatPeer>(this.context, listen: false);
            if (currentpeer.peerid != message.data['peerid']) {
              FlutterRingtonePlayer.playNotification();
              showOverlayNotification((context) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: SafeArea(
                    child: ListTile(
                      title: Text(message.data['title']),
                      subtitle: Text(message.data['body']),
                      trailing: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            OverlaySupportEntry.of(context).dismiss();
                          }),
                    ),
                  ),
                );
              }, duration: Duration(milliseconds: 2000));
            }
          }
        }
      }
    });
    //ANDROID & iOS  onMessageOpenedApp callback
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        if (notification.title == 'Call Ended') {
          flutterLocalNotificationsPlugin..cancelAll();
        } else {
          flutterLocalNotificationsPlugin..cancelAll();
        }
      }
    });
  }

  DataModel _cachedModel;
  bool showHidden = false, biometricEnabled = false;

  DataModel getModel() {
    _cachedModel ??= DataModel(currentUserNo);
    return _cachedModel;
  }

  getSignedInUserOrRedirect() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {});
    await FirebaseFirestore.instance
        .collection('version')
        .doc('userapp')
        .get()
        .then((doc) async {
      if (doc.exists) {
        if (!doc.data().containsKey("profile_set_done")) {
          await FirebaseFirestore.instance
              .collection(USERS)
              .get()
              .then((ds) async {
            if (ds != null) {
              ds.docs.forEach((dc) {
                if (dc.data().containsKey(PHONE) &&
                    dc.data().containsKey(COUNTRY_CODE)) {
                  dc.reference.set({
                    PHONERAW: dc[PHONE].toString().substring(
                        dc[COUNTRY_CODE].toString().length,
                        dc[PHONE].toString().length)
                  }, SetOptions(merge: true));
                }
              });
            }
          });
          await FirebaseFirestore.instance
              .collection('version')
              .doc('userapp')
              .set({
            'profile_set_done': true,
          }, SetOptions(merge: true));
        }

        final PackageInfo info = await PackageInfo.fromPlatform();
        double currentAppVersionInPhone =
            double.parse(info.version.trim().replaceAll(".", ""));
        double currentNewAppVersionInServer =
            double.parse(doc['version'].trim().replaceAll(".", ""));

        if (currentAppVersionInPhone < currentNewAppVersionInServer) {
          showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              String title = getTranslated(context, 'updateavl');
              String message = getTranslated(context, 'updateavlmsg');

              String btnLabel = getTranslated(context, 'updatnow');
              // String btnLabelCancel = "Later";
              return
                  // Platform.isIOS
                  //     ? new CupertinoAlertDialog(
                  //         title: Text(title),
                  //         content: Text(message),
                  //         actions: <Widget>[
                  //           FlatButton(
                  //             child: Text(btnLabel),
                  //             onPressed: () => launch(doc['url']),
                  //           ),
                  //           // FlatButton(
                  //           //   child: Text(btnLabelCancel),
                  //           //   onPressed: () => Navigator.pop(context),
                  //           // ),
                  //         ],
                  //       )
                  //     :
                  new WillPopScope(
                      onWillPop: () async => false,
                      child: AlertDialog(
                        title: Text(
                          title,
                          style: TextStyle(color: fiberchatDeepGreen),
                        ),
                        content: Text(message),
                        actions: <Widget>[

                          FlatButton(
                            child: Text(
                              btnLabel,
                              style: TextStyle(color: fiberchatLightGreen),
                            ),
                            onPressed: () => Platform.isAndroid
                                ? launch(doc['url'])
                                : launch(RateAppUrlIOS),
                          ),
                          // FlatButton(
                          //   child: Text(btnLabelCancel),
                          //   onPressed: () => Navigator.pop(context),
                          // ),
                        ],
                      ));
            },
          );
        } else {
          prefs = await SharedPreferences.getInstance();
          if (currentUserNo == null ||
              currentUserNo.isEmpty ||
              widget.isSecuritySetupDone == false ||
              widget.isSecuritySetupDone == null)
            unawaited(Navigator.pushReplacement(
                context,
                new MaterialPageRoute(
                    builder: (context) => new LoginScreen(
                          title: getTranslated(context, 'signin'),
                          issecutitysetupdone: widget.isSecuritySetupDone,
                        ))));
          else {
            getuid(context);
            setIsActive();
            String fcmToken = await FirebaseMessaging.instance.getToken();
            if (prefs.getBool(IS_TOKEN_GENERATED) != true) {
              await FirebaseFirestore.instance
                  .collection(USERS)
                  .doc(currentUserNo)
                  .set({
                NOTIFICATION_TOKENS: FieldValue.arrayUnion([fcmToken])
              }, SetOptions(merge: true));
              unawaited(prefs.setBool(IS_TOKEN_GENERATED, true));
            }
          }
        }
      } else {
        await FirebaseFirestore.instance
            .collection('version')
            .doc('userapp')
            .set({'version': '1.0.0', 'url': 'https://www.google.com/'},
                SetOptions(merge: true));
        Fiberchat.toast(
          getTranslated(context, 'setup'),
        );
      }
    }).catchError((err) {
      print('FETCHING ERROR: $err');
      Fiberchat.toast(
        getTranslated(context, 'loadingfailed') + err.toString(),
      );
    });
  }

  String currentUserNo;

  bool isLoading = false;

  StreamController<String> _userQuery =
      new StreamController<String>.broadcast();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PickupLayout(
        scaffold: Fiberchat.getNTPWrappedWidget(WillPopScope(
            onWillPop: () {
              if (!isAuthenticating) setLastSeen();
              return Future.value(true);
            },
            child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                    backgroundColor: fiberchatDeepGreen,
                    title: Text(
                      Appname,
                      style: TextStyle(
                        fontSize: 21.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    actions: <Widget>[

                      // IconButton(,
                      //   icon: Icon(
                      //     Icons.settings,
                      //     color: Colors.white,
                      //   ),
                      //   onPressed: () {
                      //     Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (context) => NewsScreen()));
                      //   },
                      // ),
                      Container(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => NewsScreen()));
                          },
                          child: Text('News',style: TextStyle(color: Colors.white,fontSize: 15.0, fontWeight: FontWeight.bold),),
                        ),
                      ),

                      PopupMenuButton(
                        padding: EdgeInsets.all(0),
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: Icon(Icons.more_vert_outlined,
                              color: fiberchatWhite),
                        ),
                        color: fiberchatWhite,
                        onSelected: (val) async {
                          switch (val) {
                            case 'rate':
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Theme(
                                      data: FiberchatTheme,
                                      child: SimpleDialog(children: <Widget>[
                                        ListTile(
                                            contentPadding:
                                                EdgeInsets.only(top: 20),
                                            subtitle: Padding(
                                                padding:
                                                    EdgeInsets.only(top: 10.0)),
                                            title: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    size: 40,
                                                    color: fiberchatGrey,
                                                  ),
                                                  Icon(
                                                    Icons.star,
                                                    size: 40,
                                                    color: fiberchatGrey,
                                                  ),
                                                  Icon(
                                                    Icons.star,
                                                    size: 40,
                                                    color: fiberchatGrey,
                                                  ),
                                                  Icon(
                                                    Icons.star,
                                                    size: 40,
                                                    color: fiberchatGrey,
                                                  ),
                                                  Icon(
                                                    Icons.star,
                                                    size: 40,
                                                    color: fiberchatGrey,
                                                  ),
                                                ]),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              Platform.isAndroid
                                                  ? launch(RateAppUrlAndroid)
                                                  : launch(RateAppUrlIOS);
                                            }),
                                        Divider(),
                                        Padding(
                                            child: Text(
                                              getTranslated(context, 'loved'),
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: fiberchatBlack),
                                              textAlign: TextAlign.center,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10)),
                                        Center(
                                            child: RaisedButton(
                                                elevation: 0,
                                                color: fiberchatgreen,
                                                child: Text(
                                                  getTranslated(
                                                      context, 'rate'),
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Platform.isAndroid
                                                      ? launch(
                                                          RateAppUrlAndroid)
                                                      : launch(RateAppUrlIOS);
                                                }))
                                      ]),
                                    );
                                  });
                              break;
                            case 'about':
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Theme(
                                        child: SimpleDialog(
                                          contentPadding: EdgeInsets.all(20),
                                          children: <Widget>[
                                            ListTile(
                                              title: Text(
                                                getTranslated(
                                                        context, 'swipeview') ??
                                                    '',
                                              ),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            ListTile(
                                                title: Text(
                                              getTranslated(
                                                      context, 'swipehide') ??
                                                  '',
                                            )),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            ListTile(
                                                title: Text(
                                              getTranslated(
                                                      context, 'lp_setalias') ??
                                                  '',
                                            ))
                                          ],
                                        ),
                                        data: FiberchatTheme);
                                  });
                              break;
                            case 'privacy':
                              launch(PRIVACY_POLICY_URL);
                              break;
                            case 'tnc':
                              launch(TERMS_CONDITION_URL);
                              break;
                            case 'share':
                              Fiberchat.invite(context);

                              break;
                            case 'feedback':
                              launch('mailto:$FeedbackEmail');
                              break;
                            case 'logout':
                              final FirebaseAuth firebaseAuth =
                                  FirebaseAuth.instance;

                              await firebaseAuth.signOut();

                              await prefs.setString(PHONE, null);

                              // Navigator.pop(context);

                              FlutterSecureStorage storage =
                                  new FlutterSecureStorage();
                              // ignore: await_only_futures
                              await storage.delete;
                              await FirebaseFirestore.instance
                                  .collection(USERS)
                                  .doc(widget.currentUserNo)
                                  .update({
                                NOTIFICATION_TOKENS: [],
                              });
                              prefs.setBool(IS_TOKEN_GENERATED, false);
                              Navigator.of(context).pushAndRemoveUntil(
                                // the new route
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      FiberchatWrapper(),
                                ),

                                // this function should return true when we're done removing routes
                                // but because we want to remove all other screens, we make it
                                // always return false
                                (Route route) => false,
                              );
                              // main();
                              break;
                            case 'settings':
                              ChatController.authenticate(_cachedModel,
                                  getTranslated(context, 'auth_needed') ?? '',
                                  state: Navigator.of(context),
                                  shouldPop: false,
                                  type: Fiberchat.getAuthenticationType(
                                      biometricEnabled, _cachedModel),
                                  prefs: prefs, onSuccess: () {
                                Navigator.pushReplacement(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => SettingsScreen(
                                              biometricEnabled:
                                                  biometricEnabled,
                                              type: Fiberchat
                                                  .getAuthenticationType(
                                                      biometricEnabled,
                                                      _cachedModel),
                                            )));
                              });
                              // Navigator.push(
                              //     context,
                              //     new MaterialPageRoute(
                              //         builder: (context) => SettingsScreen(
                              //               biometricEnabled: biometricEnabled,
                              //               type:
                              //                   Fiberchat.getAuthenticationType(
                              //                       biometricEnabled,
                              //                       _cachedModel),
                              //             )));

                              break;
                          }
                        },
                        itemBuilder: (context) => <PopupMenuItem<String>>[
                          PopupMenuItem<String>(
                              value: 'settings',
                              child: Text(
                                getTranslated(context, 'profile') ?? '',
                              )),
                          PopupMenuItem<String>(
                            value: 'rate',
                            child: Text(
                              getTranslated(context, 'rate') ?? '',
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'share',
                            child: Text(
                              getTranslated(context, 'share') ?? '',
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'feedback',
                            child: Text(
                              getTranslated(context, 'feedback') ?? '',
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'about',
                            child: Text(
                              getTranslated(context, 'tutorials') ?? '',
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'tnc',
                            child: Text(
                              getTranslated(context, 'tnc') ?? '',
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'privacy',
                            child: Text(
                              getTranslated(context, 'pp') ?? '',
                            ),
                          ),
                          PopupMenuItem<String>(
                              value: 'logout',
                              child: Text(
                                getTranslated(context, 'logout'),
                              )),
                        ].where((o) => o != null).toList(),
                      ),

                    ],
                    bottom: TabBar(
                      indicatorWeight: 4,
                      indicatorColor: Colors.white,
                      controller: controller,
                      tabs: <Widget>[
                        Tab(
                          icon: Icon(
                            Icons.search,
                            size: 22,
                          ),
                        ),
                        Tab(
                          child: Text(
                            getTranslated(context, 'chats'),
                            style: TextStyle(
                                fontSize: 15.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                        //status
                        Tab(
                          child: Text(
                            getTranslated(context, 'status'),
                            style: TextStyle(
                                fontSize: 15.0, fontWeight: FontWeight.bold),
                          ),
                        ),

                        Tab(
                          child: Text(
                            getTranslated(context, 'calls'),
                            style: TextStyle(
                                fontSize: 15.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )),
                body: TabBarView(
                  controller: controller,
                 // controller: 4,
                  children: <Widget>[
                    SearchChats(
                        prefs: prefs,
                        currentUserNo: widget.currentUserNo,
                        isSecuritySetupDone: widget.isSecuritySetupDone),
                    RecentChats(
                        prefs: prefs,
                        currentUserNo: widget.currentUserNo,
                        isSecuritySetupDone: widget.isSecuritySetupDone),
                    StatusScreen(),
                    // NewsScreen(),
                    CallHistory(
                      userphone: widget.currentUserNo,
                    ),
                  ],
                )))));
  }
}

Future<dynamic> myBackgroundMessageHandlerAndroid(RemoteMessage message) async {
  // await Firebase.initializeApp();
  if (message.data != null) {
    if (message.data['title'] == 'Call Ended') {
      flutterLocalNotificationsPlugin..cancelAll();
      await _showNotificationWithDefaultSound(
          'Missed Call', 'You have Missed a Call');
    } else {
      if (message.data['title'] == 'You have new message(s)') {
      } else if (message.data['title'] == 'Incoming Audio Call...' ||
          message.data['title'] == 'Incoming Video Call...') {
        if (message.data != null) {
          final data = message.data;

          final title = data['title'];
          final body = data['body'];

          await _showNotificationWithDefaultSound(title, body);
        }
      }
    }
  }

  return Future<void>.value();
}

Future<dynamic> myBackgroundMessageHandlerIos(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data != null) {
    if (message.data['title'] == 'Call Ended') {
      flutterLocalNotificationsPlugin..cancelAll();
      await _showNotificationWithDefaultSound(
          'Missed Call', 'You have Missed a Call');
    } else {
      if (message.data['title'] == 'You have new message(s)') {
        print('New message');
      } else if (message.data['title'] == 'Incoming Audio Call...' ||
          message.data['title'] == 'Incoming Video Call...') {
        if (message.data != null) {
          final title = message.data['title'];
          final body = message.data['body'];
          await _showNotificationWithDefaultSound(title, body);
        }
      }
    }
  }

  return Future<void>.value();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future _showNotificationWithDefaultSound(String title, String message) async {
  flutterLocalNotificationsPlugin.cancelAll();
  var initializationSettingsAndroid =
      new AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  flutterLocalNotificationsPlugin.initialize(initializationSettings);
  var androidPlatformChannelSpecifics =
      title == 'Missed Call' || title == 'Call Ended'
          ? local.AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              'channel_description',
              importance: local.Importance.max,
              priority: local.Priority.high,
              sound: RawResourceAndroidNotificationSound('whistle2'),
              playSound: true,
            )
          : local.AndroidNotificationDetails(
              'channel_id', 'channel_name', 'channel_description',
              sound: RawResourceAndroidNotificationSound('ringtone'),
              playSound: true,
              ongoing: true,
              importance: local.Importance.max,
              priority: local.Priority.high,
              timeoutAfter: 5000);
  var iOSPlatformChannelSpecifics = local.IOSNotificationDetails(
      presentBadge: true,
      sound:
          title == 'Missed Call' || title == 'Call Ended' ? '' : 'ringtone.caf',
      presentSound: true);
  var platformChannelSpecifics = local.NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin
      .show(
    0,
    '$title',
    '$message',
    platformChannelSpecifics,
    payload: 'payload',
  )
      .catchError((err) {
    print('ERROR: $err');
  });
}

// Future<void> onSelectNotification(String payload) async {
//   if (payload != null) {
//     debugPrint('notification payload: ' + payload);
//   }
// }
