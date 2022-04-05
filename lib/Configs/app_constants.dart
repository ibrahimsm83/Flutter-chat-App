import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

//*--App Colors : Replace with your own colours---
final fiberchatBlack = new Color(0xFF1E1E1E);
final fiberchatBlue = new Color(0xFF25D366);
//final fiberchatDeepGreen = new Color(0xFF075E54);
//HexColor("#ed1c22")
final fiberchatDeepGreen=new HexColor("#ed1c22");
//final fiberchatLightGreen = new Color(0xFF23c86e);
final fiberchatLightGreen = new HexColor("#ed1c22");
// final fiberchatgreen = new Color(0xFF128C7E);
// final fiberchatteagreen = new Color(0xFFDCF8C6);
final fiberchatgreen = new HexColor("#ed1c22");
final fiberchatteagreen = new HexColor("#ed1c22");

final fiberchatWhite = Colors.white;
final fiberchatGrey = Colors.grey;

//*--Admob Configurations---

const IsBannerAdShow =
    false; // Set this to 'true' if you want to show Banner ads throughout the app
const Admob_BannerAdUnitID_Android = 'ca-app-pub-3940256099942544/6300978111';
const Admob_BannerAdUnitID_Ios = 'ca-app-pub-3940256099942544/2934735716';
const IsInterstitialAdShow =
    false; // Set this to 'true' if you want to show Interstitial ads throughout the app
const Admob_InterstitialAdUnitID_Android =
    'ca-app-pub-3940256099942544/1033173712';
const Admob_InterstitialAdUnitID_Ios = 'ca-app-pub-3940256099942544/4411468910';
const IsVideoAdShow =
    false; // Set this to 'false' if you want to show Video ads throughout the app
const Admob_RewardedAdUnitID_Android = 'ca-app-pub-3940256099942544/5224354917';
const Admob_RewardedAdUnitID_Ios = 'ca-app-pub-3940256099942544/1712485313';

//*--Agora Configurations---
const Agora_APP_IDD = 'dfe8935d654b48719db0a6c34ec2e889';
    //'dfe8935d654b48719db0a6c34ec2e889';
const Agora_TOKEN ='006dfe8935d654b48719db0a6c34ec2e889IAB0mZ8j7JcI3fhL1z1Hf7JX2B6KbB5943YZHIrblwcmOKkXu64AAAAAEADIUmqkP7u7YAEAAQA/u7tg';
   // 'f40316fd2eaa4bb4b8315652c0761f2d'; // not required generally until you have planned to setup high level of authentication of users in Agora.

//*--Giphy Configurations---
const GiphyAPIKey = 'your_giphy_key';

//*--App Configurations---
//FC-RONIN
// const Appname = 'Fiberchat';
const Appname = 'FC RONIN';
const AppLogoPath = 'assets/images/applogo.png';
const IsSplashOnlySolidColor = false;
const SplashPath = 'assets/images/splash.jpeg';
//HexColor("#ed1c22")
const SplashBackgroundSolidColor = Color(0xFFF1F1F1);
//final SplashBackgroundSolidColor = HexColor("#ed1c22");
const FeedbackEmail = 'your_contact_email';
const RateAppUrlAndroid = 'rate_app_android';
const RateAppUrlIOS = 'rate_app_url';
const TERMS_CONDITION_URL = 'your_terms_url';
const PRIVACY_POLICY_URL = 'your_privacy_policy_url';

//*--------- PLEASE DONT EDIT THE BELOWLINES UNLESS YOU ARE A DEVELOPER -------
final CollectionReference callCollection =
    FirebaseFirestore.instance.collection(CALL_COLLECTION);
final CollectionReference usersCollection =
    FirebaseFirestore.instance.collection(USERS);
const CALL_COLLECTION = "call";
const CALL_HISTORY_COLLECTION = "callhistory";

const TIMESTAMP_FIELD = "timestamp";
const IS_TOKEN_GENERATED = 'isTokenGenerated';
const NOTIFICATION_TOKENS = 'notificationTokens';
const PHOTO_URL = 'photoUrl';
const USERS = 'users';
const DEFAULT_COUNTTRYCODE_ISO = 'IN';
const DEFAULT_COUNTTRYCODE_NUMBER = '+91';
const MESSAGES = 'messages';
const ANSWER_TRIES = 'answerTries';
const PASSCODE_TRIES = 'passcodeTries';
const ABOUT_ME = 'aboutMe';
const NICKNAME = 'nickname';
const TYPE = 'type';
const FROM = 'from';
const TO = 'to';
const CONTENT = 'content';
const CHATS_WITH = 'chatsWith';
const CHAT_STATUS = 'chatStatus';
const LAST_SEEN = 'lastSeen';
const PHONE = 'phone';
const PHONERAW = 'phone_raw';
const IS_SECURITY_SETUP_DONE = 'isd';
const ID = 'id';
const ANSWER = 'answer';
const QUESTION = 'question';
const PASSCODE = 'passcode';
const HIDDEN = 'hidden';
const LOCKED = 'locked';
const DELETE_UPTO = 'deleteUpto';
const TIMESTAMP = 'timestamp';
const LAST_ANSWERED = 'lastAnswered';
const LAST_ATTEMPT = 'lastAttempt';
const AUTHENTICATION_TYPE = 'authenticationType';
const CACHED_CONTACTS = 'cachedContacts';
const SAVED = 'saved';
const ALIAS_NAME = 'aliasName';
const ALIAS_AVATAR = 'aliasAvatar';
const PUBLIC_KEY = 'publicKey';
const STATUS='status';
const PRIVATE_KEY = 'privateKey';
const COUNTRY_CODE = 'countryCode';
const WALLPAPER = 'wallpaper';
const CRC_SEPARATOR = '&';
const TRIES_THRESHOLD = 3;
const TIME_BASE = 2;

// ignore: non_constant_identifier_names
final FiberchatTheme = ThemeData(
  primaryColor: fiberchatgreen,
  primaryColorLight: fiberchatgreen,
);

enum ChatStatus { blocked, waiting, requested, accepted }
enum MessageType { text, image, video, doc, location, contact, audio }
enum AuthenticationType { passcode, biometric }
void unawaited(Future<void> future) {}

const CountryCode_TrunkCode = [
  ["93", "0"],
  ["355", "0"],
  ["213", "0"],
  ["1", "1"],
  ["376", "-"],
  ["244", "-"],
  ["1", "1"],
  ["1", "1"],
  ["54", "0"],
  ["374", "0"],
  ["297", "-"],
  ["247", "-"],
  ["61", "0"],
  ["43", "0"],
  ["994", "0"],
  ["1", "1"],
  ["973", "-"],
  ["880", "0"],
  ["1", "1"],
  ["375", "80"],
  ["32", "0"],
  ["501", "-"],
  ["229", "-"],
  ["1", "1"],
  ["975", "-"],
  ["591", "0"],
  ["387", "0"],
  ["267", "-"],
  ["55", "0"],
  ["1", "1"],
  ["673", "-"],
  ["359", "0"],
  ["226", "-"],
  ["257", "-"],
  ["855", "0"],
  ["237", "-"],
  ["1", "1"],
  ["238", "-"],
  ["1", "1"],
  ["236", "-"],
  ["235", "-"],
  ["56", "-"],
  ["86", "0"],
  ["57", "0"],
  ["269", "-"],
  ["242", "-"],
  ["682", "-"],
  ["506", "-"],
  ["385", "0"],
  ["53", "0"],
  ["599", "0"],
  ["357", "-"],
  ["420", "-"],
  ["243", "0"],
  ["45", "-"],
  ["246", "-"],
  ["253", "-"],
  ["1", "1"],
  ["1", "1"],
  ["670", "-"],
  ["593", "0"],
  ["20", "0"],
  ["503", "-"],
  ["240", "-"],
  ["291", "0"],
  ["372", "-"],
  ["251", "0"],
  ["500", "-"],
  ["298", "-"],
  ["679", "-"],
  ["358", "0"],
  ["33", "0"],
  ["594", "0"],
  ["689", "-"],
  ["241", "-"],
  ["220", "-"],
  ["995", "0"],
  ["49", "0"],
  ["233", "0"],
  ["350", "-"],
  ["30", "-"],
  ["299", "-"],
  ["1", "1"],
  ["590", "0"],
  ["1", "1"],
  ["502", "-"],
  ["224", "-"],
  ["245", "-"],
  ["592", "-"],
  ["509", "-"],
  ["504", "-"],
  ["852", "-"],
  ["36", "06"],
  ["354", "-"],
  ["91", "0"],
  ["62", "0"],
  ["870", "-"],
  ["98", "0"],
  ["964", "-"],
  ["353", "0"],
  ["8816", "-"],
  ["8817", "-"],
  ["972", "0"],
  ["39", "-"],
  ["225", "-"],
  ["1", "1"],
  ["81", "0"],
  ["962", "0"],
  ["7", "8"],
  ["254", "0"],
  ["686", "-"],
  ["965", "-"],
  ["996", "0"],
  ["856", "0"],
  ["371", "-"],
  ["961", "0"],
  ["266", "-"],
  ["231", "-"],
  ["218", "0"],
  ["423", "-"],
  ["370", "8"],
  ["352", "-"],
  ["853", "-"],
  ["389", "0"],
  ["261", "0"],
  ["265", "-"],
  ["60", "0"],
  ["960", "-"],
  ["223", "-"],
  ["356", "-"],
  ["692", "1"],
  ["596", "0"],
  ["222", "-"],
  ["230", "-"],
  ["262", "0"],
  ["52", "01|044|045"],
  ["691", "1"],
  ["373", "0"],
  ["377", "-"],
  ["976", "0"],
  ["382", "0"],
  ["1", "1"],
  ["212", "0"],
  ["258", "-"],
  ["95", "0"],
  ["264", "0"],
  ["674", "-"],
  ["977", "0"],
  ["31", "0"],
  ["599", "0"],
  ["687", "-"],
  ["64", "0"],
  ["505", "-"],
  ["227", "-"],
  ["234", "0"],
  ["683", "-"],
  ["6723", "-"],
  ["850", "-"],
  ["1", "1"],
  ["47", "-"],
  ["968", "-"],
  ["92", "0"],
  ["680", "-"],
  ["970", "0"],
  ["507", "-"],
  ["675", "-"],
  ["595", "0"],
  ["51", "0"],
  ["63", "0"],
  ["48", "-"],
  ["351", "-"],
  ["1", "1"],
  ["974", "-"],
  ["262", "0"],
  ["40", "0"],
  ["7", "8"],
  ["250", "-"],
  ["290", "-"],
  ["1", "1"],
  ["1", "1"],
  ["590", "0"],
  ["590", "0"],
  ["508", "-"],
  ["1", "1"],
  ["685", "-"],
  ["378", "-"],
  ["239", "-"],
  ["966", "0"],
  ["221", "-"],
  ["381", "0"],
  ["248", "-"],
  ["232", "0"],
  ["65", "-"],
  ["1", "1"],
  ["421", "0"],
  ["386", "0"],
  ["677", "-"],
  ["252", "-"],
  ["27", "0"],
  ["82", "0"],
  ["211", "-"],
  ["34", "-"],
  ["94", "0"],
  ["249", "0"],
  ["597", "0"],
  ["268", "-"],
  ["46", "0"],
  ["41", "0"],
  ["963", "0"],
  ["886", "0"],
  ["992", "8"],
  ["255", "0"],
  ["66", "0"],
  ["882 16", "-"],
  ["228", "-"],
  ["690", "-"],
  ["676", "-"],
  ["1", "1"],
  ["216", "-"],
  ["90", "0"],
  ["993", "8"],
  ["1", "1"],
  ["688", "-"],
  ["256", "0"],
  ["380", "0"],
  ["971", "0"],
  ["44", "0"],
  ["1", "1"],
  ["1", "1"],
  ["598", "0"],
  ["998", "0"],
  ["678", "-"],
  ["379", "-"],
  ["39", "-"],
  ["58", "0"],
  ["84", "0"],
  ["681", "-"],
  ["967", "0"],
  ["260", "0"],
  ["263", "0"]
];

const CountryCodes = [
  "93",
  "358",
  "355",
  "213",
  "1684",
  "376",
  "244",
  "1264",
  "672",
  "1268",
  "54",
  "374",
  "297",
  "61",
  "43",
  "994",
  "1242",
  "973",
  "880",
  "1246",
  "375",
  "32",
  "501",
  "229",
  "1441",
  "975",
  "591",
  "387",
  "267",
  "47",
  "55",
  "246",
  "673",
  "359",
  "226",
  "257",
  "855",
  "237",
  "1",
  "238",
  "345",
  "236",
  "235",
  "56",
  "86",
  "61",
  "61",
  "57",
  "269",
  "242",
  "243",
  "682",
  "506",
  "225",
  "385",
  "53",
  "357",
  "420",
  "45",
  "253",
  "1767",
  "1849",
  "593",
  "20",
  "503",
  "240",
  "291",
  "372",
  "251",
  "500",
  "298",
  "679",
  "358",
  "33",
  "594",
  "689",
  "262",
  "241",
  "220",
  "995",
  "49",
  "233",
  "350",
  "30",
  "299",
  "1473",
  "590",
  "1671",
  "502",
  "44",
  "224",
  "245",
  "592",
  "509",
  "672",
  "379",
  "504",
  "852",
  "36",
  "354",
  "91",
  "62",
  "98",
  "964",
  "353",
  "44",
  "972",
  "39",
  "1876",
  "81",
  "44",
  "962",
  "7",
  "254",
  "686",
  "850",
  "82",
  "383",
  "965",
  "996",
  "856",
  "371",
  "961",
  "266",
  "231",
  "218",
  "423",
  "370",
  "352",
  "853",
  "389",
  "261",
  "265",
  "60",
  "960",
  "223",
  "356",
  "692",
  "596",
  "222",
  "230",
  "262",
  "52",
  "691",
  "373",
  "377",
  "976",
  "382",
  "1664",
  "212",
  "258",
  "95",
  "264",
  "674",
  "977",
  "31",
  "599",
  "687",
  "64",
  "505",
  "227",
  "234",
  "683",
  "672",
  "1670",
  "47",
  "968",
  "92",
  "680",
  "970",
  "507",
  "675",
  "595",
  "51",
  "63",
  "64",
  "48",
  "351",
  "1939",
  "974",
  "40",
  "7",
  "250",
  "262",
  "590",
  "290",
  "1869",
  "1758",
  "590",
  "508",
  "1784",
  "685",
  "378",
  "239",
  "966",
  "221",
  "381",
  "248",
  "232",
  "65",
  "421",
  "386",
  "677",
  "252",
  "27",
  "211",
  "500",
  "34",
  "94",
  "249",
  "597",
  "47",
  "268",
  "46",
  "41",
  "963",
  "886",
  "992",
  "255",
  "66",
  "670",
  "228",
  "690",
  "676",
  "1868",
  "216",
  "90",
  "993",
  "1649",
  "688",
  "256",
  "380",
  "971",
  "44",
  "1",
  "598",
  "998",
  "678",
  "58",
  "84",
  "1284",
  "1340",
  "681",
  "967",
  "260",
  "263",
];
