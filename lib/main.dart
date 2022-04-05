import 'dart:core';
import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Screens/splash_screen/splash_screen.dart';
import 'package:fiberchat/Services/Providers/currentchat_peer.dart';
import 'package:fiberchat/Services/localization/demo_localization.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Screens/homepage/homepage.dart';
import 'package:fiberchat/Services/Providers/DownloadInfoProvider.dart';
import 'package:fiberchat/Services/Providers/call_history_provider.dart';
import 'package:fiberchat/Services/Providers/user_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splashscreen/splashscreen.dart';

void main() async {
  if (Platform.isIOS) {
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandlerIos);
  }

  WidgetsFlutterBinding.ensureInitialized();

  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  if (IsBannerAdShow == true ||
      IsInterstitialAdShow == true ||
      IsVideoAdShow == true) Admob.initialize();
  if (Platform.isIOS == true &&
      (IsBannerAdShow == true ||
          IsInterstitialAdShow == true ||
          IsVideoAdShow == true)) await Admob.requestTrackingAuthorization();

  binding.renderView.automaticSystemUiAdjustment = false;
   await Firebase.initializeApp();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    bool inDebug = false;
    assert(() {
      inDebug = true;
      return true;
    }());
    // In debug mode, use the normal error widget which shows
    // the error message:
    if (inDebug) return ErrorWidget(details.exception);
    // In release builds, show a yellow-on-blue message instead:
    return Container(
      alignment: Alignment.center,
      child: Text(
        'Error! ${details.exception}',
        style: TextStyle(color: Colors.yellow),
        textDirection: TextDirection.ltr,
      ),
    );
  };
  // Here we would normally runApp() the root widget, but to demonstrate
  // the error handling we artificially fail:
  runApp(OverlaySupport(child: FiberchatWrapper()));
}

class FiberchatWrapper extends StatefulWidget {
  const FiberchatWrapper({Key key}) : super(key: key);
  static void setLocale(BuildContext context, Locale newLocale) {
    _FiberchatWrapperState state =
        context.findAncestorStateOfType<_FiberchatWrapperState>();
    state.setLocale(newLocale);
  }

  @override
  _FiberchatWrapperState createState() => _FiberchatWrapperState();
}

class _FiberchatWrapperState extends State<FiberchatWrapper> {
  Locale _locale;
  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        this._locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (this._locale == null) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800])),
        ),
      );
    } else {
      return FutureBuilder(
          future: _initialization,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('ERROR');
            }
            if (snapshot.connectionState == ConnectionState.done) {
              return FutureBuilder(
                  future: SharedPreferences.getInstance(),
                  builder:
                      (context, AsyncSnapshot<SharedPreferences> snapshot) {
                    if (snapshot.hasData) {
                      return MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                              create: (_) => DownloadInfoprovider()),
                          ChangeNotifierProvider(create: (_) => UserProvider()),
                          ChangeNotifierProvider(
                              create: (_) =>
                                  FirestoreDataProviderCALLHISTORY()),
                          ChangeNotifierProvider(
                              create: (_) => CurrentChatPeer()),
                        ],
                        child: MaterialApp(
                          title: Appname,
                          debugShowCheckedModeBanner: false,
                          home:  SplashScreen(
                              seconds: 2,
                              navigateAfterSeconds: new Homepage(
                                currentUserNo: snapshot.data.getString(PHONE),
                                isSecuritySetupDone: snapshot.data.getString(
                                            IS_SECURITY_SETUP_DONE) ==
                                        null
                                    ? false
                                    : ((snapshot.data.getString(PHONE) == null)
                                        ? false
                                        : (snapshot.data.getString(
                                                    IS_SECURITY_SETUP_DONE) ==
                                                snapshot.data.getString(PHONE))
                                            ? true
                                            : false),
                              ),
                              // title: new Text('Welcome In SplashScreen'),
                              // image: new Image.asset('$SplashPath'),
                              backgroundColor: SplashBackgroundSolidColor,
                              imageBackground: AssetImage(
                                '$SplashPath',
                              ),
                              styleTextUnderTheLoader: new TextStyle(),
                              photoSize: 100.0,
                              loaderColor: Colors.transparent),

                          locale: _locale,
                          supportedLocales: supportedlocale,
                          localizationsDelegates: [
                            DemoLocalization.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                          ],
                          localeResolutionCallback: (locale, supportedLocales) {
                            for (var supportedLocale in supportedLocales) {
                              if (supportedLocale.languageCode ==
                                      locale.languageCode &&
                                  supportedLocale.countryCode ==
                                      locale.countryCode) {
                                return supportedLocale;
                              }
                            }
                            return supportedLocales.first;
                          },
                          //--- All localizations settings ended here----
                        ),
                      );
                    }
                    return MultiProvider(
                      providers: [
                        ChangeNotifierProvider(create: (_) => UserProvider()),
                      ],
                      child: MaterialApp(
                          theme: ThemeData(
                            primaryColor: fiberchatgreen,
                            primaryColorLight: fiberchatgreen,
                          ),
                          debugShowCheckedModeBanner: false,
                          home: Splashscreen()),
                    );
                  });
            }
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Splashscreen(),
            );
          });
    }
  }
}
