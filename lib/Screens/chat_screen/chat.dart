import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/Providers/currentchat_peer.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Services/Admob/admob.dart';
import 'package:fiberchat/Screens/call_history/callhistory.dart';
import 'package:fiberchat/Screens/chat_screen/utils/audioPlayback.dart';
import 'package:fiberchat/Screens/chat_screen/utils/downloadMedia.dart';
import 'package:fiberchat/Screens/chat_screen/utils/message.dart';
import 'package:fiberchat/Screens/contact_screens/ContactsSelect.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Screens/chat_screen/utils/photo_view.dart';
import 'package:fiberchat/Screens/profile/profile_view.dart';
import 'package:fiberchat/Services/Providers/seen_provider.dart';
import 'package:fiberchat/Services/Providers/seen_state.dart';
import 'package:fiberchat/Screens/calling_screen/pickup_layout.dart';
import 'package:fiberchat/Utils/call_utilities.dart';
import 'package:fiberchat/Utils/permissions.dart';
import 'package:fiberchat/Utils/chat_controller.dart';
import 'package:fiberchat/Utils/crc.dart';
import 'package:fiberchat/Utils/open_settings.dart';
import 'package:fiberchat/Utils/save.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:fiberchat/widgets/AudioRecorder/Audiorecord.dart';
import 'package:fiberchat/widgets/DocumentPicker/documentPicker.dart';
import 'package:fiberchat/widgets/GiphyPicker/giphy_picker.dart';
import 'package:fiberchat/widgets/ImagePicker/image_picker.dart';
import 'package:fiberchat/widgets/VideoPicker/VideoPicker.dart';
import 'package:fiberchat/widgets/VideoPicker/VideoPreview.dart';
import 'package:fiberchat/widgets/Common/bubble.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:media_info/media_info.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fiberchat/Models/E2EE/e2ee.dart' as e2ee;

import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:simple_url_preview/simple_url_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

hidekeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}

class ChatScreen extends StatefulWidget {
  final String peerNo, currentUserNo;
  final DataModel model;
  final int unread;
  ChatScreen(
      {Key key,
      @required this.currentUserNo,
      @required this.peerNo,
      @required this.model,
      @required this.unread});

  @override
  State createState() =>
      new _ChatScreenState(currentUserNo: currentUserNo, peerNo: peerNo);
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  String peerAvatar, peerNo, currentUserNo, privateKey, sharedSecret;
  bool locked, hidden;
  Map<String, dynamic> peer, currentUser;
  int chatStatus, unread;
  GlobalKey<State> _keyLoader =
      new GlobalKey<State>(debugLabel: 'qqqeqeqsseaadqeqe');
  _ChatScreenState({@required this.peerNo, @required this.currentUserNo});

  String chatId;
  SharedPreferences prefs;

  bool typing = false;
  File thumbnailFile;
  File imageFile;
  bool isLoading;
  String imageUrl;
  SeenState seenState;
  List<Message> messages = new List<Message>();
  List<Map<String, dynamic>> _savedMessageDocs =
      new List<Map<String, dynamic>>();

  int uploadTimestamp;

  StreamSubscription seenSubscription, msgSubscription, deleteUptoSubscription;

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController realtime = new ScrollController();
  final ScrollController saved = new ScrollController();
  DataModel _cachedModel;
  AdmobReward rewardAd;
  AdmobInterstitial interstitialAd;

  Duration duration;
  Duration position;

  AudioPlayer audioPlayer;

  String localFilePath;

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  @override
  void initState() {
    super.initState();

    initAudioPlayer();
    _load();
    Fiberchat.internetLookUp();
    _cachedModel = widget.model;
    updateLocalUserData(_cachedModel);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      var currentpeer =
          Provider.of<CurrentChatPeer>(this.context, listen: false);
      currentpeer.setpeer(widget.peerNo);
    });
    seenState = new SeenState(false);
    WidgetsBinding.instance.addObserver(this);
    chatId = '';
    unread = widget.unread;
    isLoading = false;
    imageUrl = '';
    loadSavedMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 10), () {
        readLocal(this.context);
      });
    });
    // Comment below lines if you dont want to show video ads
    if (IsVideoAdShow == true) {
      rewardAd = AdmobReward(
          adUnitId: getRewardBasedVideoAdUnitId(),
          listener: (AdmobAdEvent event, Map<String, dynamic> args) {
            if (event == AdmobAdEvent.closed) {
              rewardAd.load();
            }
          });
      rewardAd.load();
      Future.delayed(const Duration(milliseconds: 4500), () {
        rewardAd.show();
      });
    }
    // Interstital Ads
    if (IsInterstitialAdShow == true) {
      print(true);
      interstitialAd = AdmobInterstitial(
        adUnitId: getInterstitialAdUnitId(),
        listener: (AdmobAdEvent event, Map<String, dynamic> args) {
          if (event == AdmobAdEvent.closed) interstitialAd.load();
          // handleEvent(event, args, 'Interstitial');
        },
      );
      interstitialAd.load();
    }
  }

  updateLocalUserData(model) {
    peer = model.userData[peerNo];
    currentUser = _cachedModel.currentUser;
    if (currentUser != null && peer != null) {
      hidden =
          currentUser[HIDDEN] != null && currentUser[HIDDEN].contains(peerNo);
      locked =
          currentUser[LOCKED] != null && currentUser[LOCKED].contains(peerNo);
      chatStatus = peer[CHAT_STATUS];
      peerAvatar = peer[PHOTO_URL];
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    setLastSeen();
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    msgSubscription?.cancel();
    seenSubscription?.cancel();
    deleteUptoSubscription?.cancel();
  }

//---- pop sound effect --
  AudioPlayer audioPlugin = new AudioPlayer();
  String mp3Uri;
  Future<Null> _load() async {
    final ByteData data = await rootBundle.load('assets/sounds/popsound.mp3');
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/popsound.mp3');
    await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    mp3Uri = tempFile.uri.toString();
    setState(() {});
    print('finished loading, uri=$mp3Uri');
  }

  void _playPopSound() {
    if (mp3Uri != null) {
      audioPlugin.play(mp3Uri, isLocal: true);
    }
  }

//-----Audio Playback section starts------
  void initAudioPlayer() {
    audioPlayer = AudioPlayer();
    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => setState(() => position = p));
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        setState(() => duration = audioPlayer.duration);
      } else if (s == AudioPlayerState.STOPPED) {
        onComplete();
        setState(() {
          position = duration;
        });
      }
    }, onError: (msg) {
      setState(() {
        playerState = PlayerState.stopped;
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });
  }

  Future play(String audiourl) async {
    await audioPlayer.play(audiourl);
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() => playerState = PlayerState.paused);
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
      position = Duration();
    });
  }

  Future mute(bool muted) async {
    await audioPlayer.mute(muted);
    setState(() {
      isMuted = muted;
    });
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  //---Audio playback section ends------

  loadvideoAd() {
    return AdmobReward(
        adUnitId: getRewardBasedVideoAdUnitId(), nonPersonalizedAds: true);
  }

  void setLastSeen() async {
    if (chatStatus != ChatStatus.blocked.index) {
      if (chatId != null) {
        await FirebaseFirestore.instance.collection(MESSAGES).doc(chatId).set(
            {'$currentUserNo': DateTime.now().millisecondsSinceEpoch},
            SetOptions(merge: true));
      }
    }
  }

  dynamic encryptWithCRC(String input) {
    try {
      String encrypted = cryptor.encrypt(input, iv: iv).base64;
      int crc = CRC32.compute(input);
      return '$encrypted$CRC_SEPARATOR$crc';
    } catch (e) {
      Fiberchat.toast(
        getTranslated(this.context, 'waitingpeer'),
      );
      return false;
    }
  }

  String decryptWithCRC(String input) {
    try {
      if (input.contains(CRC_SEPARATOR)) {
        int idx = input.lastIndexOf(CRC_SEPARATOR);
        String msgPart = input.substring(0, idx);
        String crcPart = input.substring(idx + 1);
        int crc = int.tryParse(crcPart);
        if (crc != null) {
          msgPart =
              cryptor.decrypt(encrypt.Encrypted.fromBase64(msgPart), iv: iv);
          if (CRC32.compute(msgPart) == crc) return msgPart;
        }
      }
    } on FormatException {
      Fiberchat.toast(getTranslated(this.context, 'msgnotload'));
      return '';
    }
    Fiberchat.toast(getTranslated(this.context, 'msgnotload'));
    return '';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      setIsActive();
    else
      setLastSeen();
  }

  void setIsActive() async {
    await FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .set({'$currentUserNo': true}, SetOptions(merge: true));
  }

  dynamic lastSeen;

  FlutterSecureStorage storage = new FlutterSecureStorage();
  encrypt.Encrypter cryptor;
  final iv = encrypt.IV.fromLength(8);

  readLocal(
    BuildContext context,
  ) async {
    prefs = await SharedPreferences.getInstance();
    try {
      privateKey = await storage.read(key: PRIVATE_KEY);
      sharedSecret = (await e2ee.X25519().calculateSharedSecret(
              e2ee.Key.fromBase64(privateKey, false),
              e2ee.Key.fromBase64(peer[PUBLIC_KEY], true)))
          .toBase64();
      final key = encrypt.Key.fromBase64(sharedSecret);
      cryptor = new encrypt.Encrypter(encrypt.Salsa20(key));
    } catch (e) {
      sharedSecret = null;
    }
    try {
      seenState.value = prefs.getInt(getLastSeenKey());
    } catch (e) {
      seenState.value = false;
    }
    chatId = Fiberchat.getChatId(currentUserNo, peerNo);
    textEditingController.addListener(() {
      if (textEditingController.text.isNotEmpty && typing == false) {
        lastSeen = peerNo;
        FirebaseFirestore.instance
            .collection(USERS)
            .doc(currentUserNo)
            .set({LAST_SEEN: peerNo}, SetOptions(merge: true));
        typing = true;
      }
      if (textEditingController.text.isEmpty && typing == true) {
        lastSeen = true;
        FirebaseFirestore.instance
            .collection(USERS)
            .doc(currentUserNo)
            .set({LAST_SEEN: true}, SetOptions(merge: true));
        typing = false;
      }
    });
    setIsActive();
    deleteUptoSubscription = FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .snapshots()
        .listen((doc) {
      if (doc != null && mounted) {
        deleteMessagesUpto(doc.data()[DELETE_UPTO]);
      }
    });
    seenSubscription = FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .snapshots()
        .listen((doc) {
      if (doc != null && mounted) {
        seenState.value = doc[peerNo] ?? false;
        if (seenState.value is int) {
          prefs.setInt(getLastSeenKey(), seenState.value);
        }
      }
    });
    loadMessagesAndListen(context);
  }

  String getLastSeenKey() {
    return "$peerNo-$LAST_SEEN";
  }

  int thumnailtimestamp;
  getImage(File image) {
    if (image != null) {
      setState(() {
        imageFile = image;
      });
    }
    return uploadFile(false);
  }

  getThumbnail(String url) async {
    if (url != null) {
      String path = await VideoThumbnail.thumbnailFile(
          video: url,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.PNG,
          // maxHeight: 150,
          // maxWidth:300,
          // timeMs: r.timeMs,
          quality: 30);
      setState(() {
        thumbnailFile = File(path);
      });
    }
    return uploadFile(true);
  }

  getWallpaper(File image) {
    if (image != null) {
      _cachedModel.setWallpaper(peerNo, image);
    }
    return Future.value(false);
  }

  getImageFileName(id, timestamp) {
    return "$id-$timestamp";
  }

  String videometadata;
  Future uploadFile(bool isthumbnail) async {
    uploadTimestamp = DateTime.now().millisecondsSinceEpoch;
    String fileName = getImageFileName(
        currentUserNo,
        isthumbnail == false
            ? '$uploadTimestamp'
            : '${thumnailtimestamp}Thumbnail');
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageTaskSnapshot uploading = await reference
        .putFile(isthumbnail == true ? thumbnailFile : imageFile)
        .onComplete;
    if (isthumbnail == false) {
      setState(() {
        thumnailtimestamp = uploadTimestamp;
      });
    }
    if (isthumbnail == true) {
      print(thumbnailFile.path);
      MediaInfo _mediaInfo = MediaInfo();

      await _mediaInfo.getMediaInfo(thumbnailFile.path).then((mediaInfo) {
        setState(() {
          videometadata = jsonEncode({
            "width": mediaInfo['width'],
            "height": mediaInfo['height'],
            "orientation": null,
            "duration": mediaInfo['durationMs'],
            "filesize": null,
            "author": null,
            "date": null,
            "framerate": null,
            "location": null,
            "path": null,
            "title": '',
            "mimetype": mediaInfo['mimeType'],
          }).toString();
        });
      }).catchError((onError) {
        Fiberchat.toast('Sending failed !');
        print('ERROR CP: $onError');
      });
    }

    return uploading.ref.getDownloadURL();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    Fiberchat.toast('Detecting Location...');
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void onSendMessage(BuildContext context, String content, MessageType type,
      int timestamp) async {
    if (content.trim() != '') {
      content = content.trim();
      if (chatStatus == null)
        ChatController.request(currentUserNo, peerNo, chatId);
      textEditingController.clear();
      final encrypted = encryptWithCRC(content);
      if (encrypted is String) {
        Future messaging = FirebaseFirestore.instance
            .collection(MESSAGES)
            .doc(chatId)
            .collection(chatId)
            .doc('$timestamp')
            .set({
          FROM: currentUserNo,
          TO: peerNo,
          TIMESTAMP: timestamp,
          CONTENT: encrypted,
          TYPE: type.index,
        }, SetOptions(merge: true));
        _cachedModel.addMessage(peerNo, timestamp, messaging);
        var tempDoc = {
          TIMESTAMP: timestamp,
          TO: peerNo,
          TYPE: type.index,
          CONTENT: content,
          FROM: currentUserNo,
        };
        setState(() {
          messages = List.from(messages)
            ..add(Message(
              buildTempMessage(context, type, content, timestamp, messaging),
              onTap: type == MessageType.image
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoViewWrapper(
                          tag: timestamp.toString(),
                          imageProvider: CachedNetworkImageProvider(content),
                        ),
                      ))
                  : null,
              onDismiss: null,
              onDoubleTap: () {
                save(tempDoc);
              },
              onLongPress: () {
                contextMenu(context, tempDoc);
              },
              from: currentUserNo,
              timestamp: timestamp,
            ));
        });

        unawaited(realtime.animateTo(0.0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut));
        _playPopSound();
      } else {
        Fiberchat.toast('Nothing to send');
      }
    }
  }

  delete(int ts) {
    setState(() {
      messages.removeWhere((msg) => msg.timestamp == ts);
      messages = List.from(messages);
    });
  }

  contextMenu(BuildContext context, Map<String, dynamic> doc,
      {bool saved = false}) {
    List<Widget> tiles = List<Widget>();
    if (saved == false) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.save_alt),
          title: Text(
            'Save',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            save(doc);
            Navigator.pop(context);
          }));
    }
    if (doc[FROM] == currentUserNo && saved == false) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.delete),
          title: Text(
            'Delete',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () async {
            if (doc[TYPE] == MessageType.image.index) {
              FirebaseStorage.instance
                  .ref()
                  .child(getImageFileName(doc[FROM], doc[TIMESTAMP]))
                  .delete();
            } else if (doc[TYPE] == MessageType.doc.index) {
              FirebaseStorage.instance
                  .ref()
                  .child(getImageFileName(doc[FROM], doc[TIMESTAMP]))
                  .delete();
            } else if (doc[TYPE] == MessageType.audio.index) {
              FirebaseStorage.instance
                  .ref()
                  .child(getImageFileName(doc[FROM], doc[TIMESTAMP]))
                  .delete();
            } else if (doc[TYPE] == MessageType.video.index) {
              StorageReference reference1 = FirebaseStorage.instance
                  .ref()
                  .child(getImageFileName(doc[FROM], doc[TIMESTAMP]));
              StorageReference reference2 = FirebaseStorage.instance
                  .ref()
                  .child(getImageFileName(
                      doc[FROM], '${doc[TIMESTAMP]}Thumbnail'));

              await reference1.delete();
              await reference2.delete();
            }

            delete(doc[TIMESTAMP]);
            FirebaseFirestore.instance
                .collection(MESSAGES)
                .doc(chatId)
                .collection(chatId)
                .doc('${doc[TIMESTAMP]}')
                .delete();
            Navigator.pop(context);
            Fiberchat.toast('Deleted!');
          }));
    }
    if (saved == true) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.delete),
          title: Text(
            'Delete',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            Save.deleteMessage(peerNo, doc);
            _savedMessageDocs
                .removeWhere((msg) => msg[TIMESTAMP] == doc[TIMESTAMP]);
            setState(() {
              _savedMessageDocs = List.from(_savedMessageDocs);
            });
            Navigator.pop(context);
            Fiberchat.toast('Deleted!');
          }));
    }
    if (doc[TYPE] == MessageType.text.index) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.content_copy),
          title: Text(
            'Copy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: doc[CONTENT]));
            Navigator.pop(context);
            Fiberchat.toast('Copied!');
          }));
    }
    showDialog(
        context: context,
        builder: (context) {
          return Theme(
              data: FiberchatTheme, child: SimpleDialog(children: tiles));
        });
  }

  deleteUpto(int upto) {
    FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .collection(chatId)
        .where(TIMESTAMP, isLessThanOrEqualTo: upto)
        .get()
        .then((query) {
      query.docs.forEach((msg) async {
        if (msg[TYPE] == MessageType.image.index) {
          FirebaseStorage.instance
              .ref()
              .child(getImageFileName(msg[FROM], msg[TIMESTAMP]))
              .delete();
        } else if (msg[TYPE] == MessageType.doc.index) {
          FirebaseStorage.instance
              .ref()
              .child(getImageFileName(msg[FROM], msg[TIMESTAMP]))
              .delete();
        } else if (msg[TYPE] == MessageType.audio.index) {
          FirebaseStorage.instance
              .ref()
              .child(getImageFileName(msg[FROM], msg[TIMESTAMP]))
              .delete();
        } else if (msg[TYPE] == MessageType.video.index) {
          StorageReference reference1 = FirebaseStorage.instance
              .ref()
              .child(getImageFileName(msg[FROM], msg[TIMESTAMP]));
          StorageReference reference2 = FirebaseStorage.instance
              .ref()
              .child(getImageFileName(msg[FROM], '${msg[TIMESTAMP]}Thumbnail'));

          await reference1.delete();
          await reference2.delete();
        }
        msg.reference.delete();
      });
    });

    FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .set({DELETE_UPTO: upto}, SetOptions(merge: true));
    deleteMessagesUpto(upto);
    empty = true;
  }

  deleteMessagesUpto(int upto) {
    if (upto != null) {
      int before = messages.length;
      setState(() {
        messages = List.from(messages.where((msg) => msg.timestamp > upto));
        if (messages.length < before)
          Fiberchat.toast(getTranslated(this.context, 'convended'));
      });
    }
  }

  save(Map<String, dynamic> doc) async {
    Fiberchat.toast('Saved');
    if (!_savedMessageDocs.any((_doc) => _doc[TIMESTAMP] == doc[TIMESTAMP])) {
      String content;
      if (doc[TYPE] == MessageType.image.index) {
        content = doc[CONTENT].toString().startsWith('http')
            ? await Save.getBase64FromImage(imageUrl: doc[CONTENT] as String)
            : doc[CONTENT]; // if not a url, it is a base64 from saved messages
      } else {
        // If text
        content = doc[CONTENT];
      }
      doc[CONTENT] = content;
      Save.saveMessage(peerNo, doc);
      _savedMessageDocs.add(doc);
      setState(() {
        _savedMessageDocs = List.from(_savedMessageDocs);
      });
    }
  }

  Widget selectablelinkify(String text) {
    // text: "Made by https://cretezy.com",
    // style: TextStyle(color: Colors.yellow),
    // linkStyle: TextStyle(color: Colors.red),
    return SelectableLinkify(
      onOpen: (link) async {
        if (await canLaunch(link.url)) {
          await launch(link.url);
        } else {
          throw 'Could not launch $link';
        }
      },
      text: text ?? "",
      style: TextStyle(color: Colors.black, fontSize: 16),
    );
  }

  Widget getTextMessage(bool isMe, Map<String, dynamic> doc, bool saved) {
    return selectablelinkify(
      doc[CONTENT],
      // style: TextStyle(
      //     color: isMe ? fiberchatBlack : Colors.black, fontSize: 16.0),
    );
  }

  Widget getTempTextMessage(String message) {
    return selectablelinkify(
      message,
      // style: TextStyle(
      //     color: isMe ? fiberchatBlack : Colors.black, fontSize: 16.0),
    );
  }

  Widget getLocationMessage(String message, {bool saved = false}) {
    return SimpleUrlPreview(
      descriptionLines: 1,
      titleLines: 1,
      url: '$message',
      textColor: Colors.black54,
      bgColor: Colors.white,
      isClosable: false,
      previewHeight: 150,
    );
  }

  Widget getAudiomessage(BuildContext context, String message,
      {bool saved = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      // width: 250,
      // height: 116,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(4),
            isThreeLine: false,
            leading: Container(
              decoration: BoxDecoration(
                color: Colors.yellow[800],
                borderRadius: BorderRadius.circular(7.0),
              ),
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.play_circle_filled_outlined,
                size: 25,
                color: Colors.white,
              ),
            ),
            title: Column(
              children: [
                Text(
                  'Recording_' + message.split('-BREAK-')[1] + '.mp3',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
              ],
            ),
          ),
          AudioPlayback(
              url: message.split('-BREAK-')[0],
              downloadwidget: IconButton(
                iconSize: 28.0,
                icon: Icon(Icons.file_download),
                color: Colors.black38,
                onPressed: Platform.isIOS
                    ? () {
                        launch(message.split('-BREAK-')[0]);
                      }
                    : () async {
                        await downloadFile(
                          context: _scaffold.currentContext,
                          fileName: message.split('-BREAK-')[1] + '.mp3',
                          isonlyview: false,
                          keyloader: _keyLoader,
                          uri: message.split('-BREAK-')[0],
                        );
                      },
              ))
          // _buildPlayer(context, message.split('-BREAK-')[0],
          //     message.split('-BREAK-')[1]),
        ],
      ),
    );
  }

  Widget getDocmessage(BuildContext context, String message,
      {bool saved = false}) {
    return SizedBox(
      width: 220,
      height: 116,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(4),
            isThreeLine: false,
            leading: Container(
              decoration: BoxDecoration(
                color: Colors.cyan[700],
                borderRadius: BorderRadius.circular(7.0),
              ),
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.attach_file_rounded,
                size: 25,
                color: Colors.white,
              ),
            ),
            title: Text(
              message.split('-BREAK-')[1],
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
            ),
          ),
          Divider(
            height: 3,
          ),
          FlatButton(
              onPressed: Platform.isIOS
                  ? () {
                      launch(message.split('-BREAK-')[0]);
                    }
                  : () async {
                      await downloadFile(
                        context: _scaffold.currentContext,
                        fileName: message.split('-BREAK-')[1],
                        isonlyview: false,
                        keyloader: _keyLoader,
                        uri: message.split('-BREAK-')[0],
                      );
                    },
              child: Text('DOWNLOAD',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.blue[400])))
        ],
      ),
    );
  }

  Widget getVideoMessage(BuildContext context, String message,
      {bool saved = false}) {
    Map<dynamic, dynamic> meta =
        jsonDecode((message.split('-BREAK-')[2]).toString());
    return InkWell(
      onTap: () {
        Navigator.push(
            this.context,
            new MaterialPageRoute(
                builder: (context) => new PreviewVideo(
                      isdownloadallowed: true,
                      filename: message.split('-BREAK-')[1],
                      id: null,
                      videourl: message.split('-BREAK-')[0],
                      aspectratio: meta["width"] / meta["height"],
                    )));
      },
      child: Container(
        color: Colors.blueGrey,
        height: 197,
        width: 197,
        child: Stack(
          children: [
            CachedNetworkImage(
              placeholder: (context, url) => Container(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(fiberchatBlue),
                ),
                width: 197,
                height: 197,
                padding: EdgeInsets.all(80.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.all(
                    Radius.circular(0.0),
                  ),
                ),
              ),
              errorWidget: (context, str, error) => Material(
                child: Image.asset(
                  'assets/img_not_available.jpeg',
                  width: 197,
                  height: 197,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(0.0),
                ),
                clipBehavior: Clip.hardEdge,
              ),
              imageUrl: message.split('-BREAK-')[1],
              width: 197,
              height: 197,
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black.withOpacity(0.4),
              height: 197,
              width: 197,
            ),
            Center(
              child: Icon(Icons.play_circle_fill_outlined,
                  color: Colors.white70, size: 65),
            ),
          ],
        ),
      ),
    );
  }

  Widget getContactMessage(BuildContext context, String message,
      {bool saved = false}) {
    return SizedBox(
      width: 250,
      height: 130,
      child: Column(
        children: [
          ListTile(
            isThreeLine: false,
            leading: customCircleAvatar(url: null),
            title: Text(
              message.split('-BREAK-')[0],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[400]),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                message.split('-BREAK-')[1],
                style: TextStyle(
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
            ),
          ),
          Divider(
            height: 7,
          ),
          FlatButton(
              onPressed: () async {
                String peer = message.split('-BREAK-')[1];
                String peerphone;
                bool issearching = true;
                bool issearchraw = false;
                bool isUser = false;
                String formattedphone;

                setState(() {
                  peerphone = peer.replaceAll(new RegExp(r'-'), '');
                  peerphone.trim();
                });

                formattedphone = peerphone;

                if (!peerphone.startsWith('+')) {
                  if ((peerphone.length > 11)) {
                    CountryCodes.forEach((code) {
                      if (peerphone.startsWith(code) && issearching == true) {
                        setState(() {
                          formattedphone = peerphone.substring(
                              code.length, peerphone.length);
                          issearchraw = true;
                          issearching = false;
                          print('found');
                        });
                      }
                    });
                  } else {
                    setState(() {
                      setState(() {
                        issearchraw = true;
                        formattedphone = peerphone;
                      });
                    });
                  }
                } else {
                  setState(() {
                    issearchraw = false;
                    formattedphone = peerphone;
                  });
                }
                print(formattedphone);

                // Fiberchat.toast('Please wait... Loading !');
                // FirebaseFirestore.instance
                //     .collection(USERS)
                //     .doc(message.split('-BREAK-')[1])
                //     .get()
                //     .then((user) {
                //   if (user.exists) {
                //     var peer = user;
                //     widget.model.addUser(user);
                //     Navigator.pushReplacement(
                //         context,
                //         new MaterialPageRoute(
                //             builder: (context) => new ChatScreen(
                //                 unread: 0,
                //                 currentUserNo: widget.currentUserNo,
                //                 model: widget.model,
                //                 peerNo: peer[PHONE])));
                //   } else {
                //     Fiberchat.toast(
                //         getTranslated(this.context, 'usernotjoined') +
                //             ' $Appname');
                //   }
                // });
                Query query = issearchraw == true
                    ? FirebaseFirestore.instance
                        .collection(USERS)
                        .where(PHONERAW, isEqualTo: formattedphone ?? peerphone)
                        .limit(1)
                    : FirebaseFirestore.instance
                        .collection(USERS)
                        .where(PHONE, isEqualTo: formattedphone ?? peerphone)
                        .limit(1);

                await query.get().then((user) {
                  setState(() {
                    isUser = user.docs.length == 0 ? false : true;
                  });
                  if (isUser) {
                    var peer = user.docs[0].data();
                    widget.model.addUser(user.docs[0]);
                    Navigator.pushReplacement(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new ChatScreen(
                                unread: 0,
                                currentUserNo: widget.currentUserNo,
                                model: widget.model,
                                peerNo: peer[PHONE])));
                  } else {
                    Query queryretrywithoutzero = issearchraw == true
                        ? FirebaseFirestore.instance
                            .collection(USERS)
                            .where(PHONERAW,
                                isEqualTo: formattedphone == null
                                    ? peerphone.substring(1, peerphone.length)
                                    : formattedphone.substring(
                                        1, formattedphone.length))
                            .limit(1)
                        : FirebaseFirestore.instance
                            .collection(USERS)
                            .where(PHONERAW,
                                isEqualTo: formattedphone == null
                                    ? peerphone.substring(1, peerphone.length)
                                    : formattedphone.substring(
                                        1, formattedphone.length))
                            .limit(1);
                    queryretrywithoutzero.get().then((user) {
                      setState(() {
                        isLoading = false;
                        isUser = user.docs.length == 0 ? false : true;
                      });
                      if (isUser) {
                        var peer = user.docs[0].data();
                        widget.model.addUser(user.docs[0]);
                        Navigator.pushReplacement(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new ChatScreen(
                                    unread: 0,
                                    currentUserNo: widget.currentUserNo,
                                    model: widget.model,
                                    peerNo: peer[PHONE])));
                      }
                    });
                  }
                });

                if (isUser == null || isUser == false) {
                  Fiberchat.toast(getTranslated(this.context, 'usernotjoined') +
                      ' $Appname');
                }
              },
              child: Text(getTranslated(this.context, 'msg'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.blue[400])))
        ],
      ),
    );
  }

  Widget getImageMessage(Map<String, dynamic> doc, {bool saved = false}) {
    return Container(
      child: saved
          ? Material(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: Save.getImageFromBase64(doc[CONTENT]).image,
                      fit: BoxFit.cover),
                ),
                width: 200.0,
                height: 200.0,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
              clipBehavior: Clip.hardEdge,
            )
          : CachedNetworkImage(
              placeholder: (context, url) => Container(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(fiberchatBlue),
                ),
                width: 200.0,
                height: 200.0,
                padding: EdgeInsets.all(80.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                ),
              ),
              errorWidget: (context, str, error) => Material(
                child: Image.asset(
                  'assets/img_not_available.jpeg',
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(8.0),
                ),
                clipBehavior: Clip.hardEdge,
              ),
              imageUrl: doc[CONTENT],
              width: 200.0,
              height: 200.0,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget getTempImageMessage({String url}) {
    return imageFile != null
        ? Container(
            child: Image.file(
              imageFile,
              width: 200.0,
              height: 200.0,
              fit: BoxFit.cover,
            ),
          )
        : getImageMessage({CONTENT: url});
  }

  Widget buildMessage(BuildContext context, Map<String, dynamic> doc,
      {bool saved = false, List<Message> savedMsgs}) {
    final bool isMe = doc[FROM] == currentUserNo;
    bool isContinuing;
    if (savedMsgs == null)
      isContinuing =
          messages.isNotEmpty ? messages.last.from == doc[FROM] : false;
    else {
      isContinuing =
          savedMsgs.isNotEmpty ? savedMsgs.last.from == doc[FROM] : false;
    }
    return SeenProvider(
        timestamp: doc[TIMESTAMP].toString(),
        data: seenState,
        child: Bubble(
            messagetype: doc[TYPE] == MessageType.text.index
                ? MessageType.text
                : doc[TYPE] == MessageType.contact.index
                    ? MessageType.contact
                    : doc[TYPE] == MessageType.location.index
                        ? MessageType.location
                        : doc[TYPE] == MessageType.image.index
                            ? MessageType.image
                            : doc[TYPE] == MessageType.video.index
                                ? MessageType.video
                                : doc[TYPE] == MessageType.doc.index
                                    ? MessageType.doc
                                    : doc[TYPE] == MessageType.audio.index
                                        ? MessageType.audio
                                        : MessageType.text,
            child: doc[TYPE] == MessageType.text.index
                ? getTextMessage(isMe, doc, saved)
                : doc[TYPE] == MessageType.location.index
                    ? getLocationMessage(doc[CONTENT], saved: false)
                    : doc[TYPE] == MessageType.doc.index
                        ? getDocmessage(context, doc[CONTENT], saved: false)
                        : doc[TYPE] == MessageType.audio.index
                            ? getAudiomessage(context, doc[CONTENT],
                                saved: false)
                            : doc[TYPE] == MessageType.video.index
                                ? getVideoMessage(context, doc[CONTENT],
                                    saved: false)
                                : doc[TYPE] == MessageType.contact.index
                                    ? getContactMessage(context, doc[CONTENT],
                                        saved: false)
                                    : getImageMessage(
                                        doc,
                                        saved: saved,
                                      ),
            isMe: isMe,
            timestamp: doc[TIMESTAMP],
            delivered: _cachedModel.getMessageStatus(peerNo, doc[TIMESTAMP]),
            isContinuing: isContinuing));
  }

  Widget buildTempMessage(
      BuildContext context, MessageType type, content, timestamp, delivered) {
    final bool isMe = true;
    return SeenProvider(
        timestamp: timestamp.toString(),
        data: seenState,
        child: Bubble(
          messagetype: type,
          child: type == MessageType.text
              ? getTempTextMessage(content)
              : type == MessageType.location
                  ? getLocationMessage(content, saved: false)
                  : type == MessageType.doc
                      ? getDocmessage(context, content, saved: false)
                      : type == MessageType.audio
                          ? getAudiomessage(context, content, saved: false)
                          : type == MessageType.video
                              ? getVideoMessage(context, content, saved: false)
                              : type == MessageType.contact
                                  ? getContactMessage(context, content,
                                      saved: false)
                                  : getTempImageMessage(url: content),
          isMe: isMe,
          timestamp: timestamp,
          delivered: delivered,
          isContinuing:
              messages.isNotEmpty && messages.last.from == currentUserNo,
        ));
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(fiberchatBlue)),
              ),
              color: fiberchatBlack.withOpacity(0.8),
            )
          : Container(),
    );
  }

  shareMedia(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        builder: (BuildContext context) {
          // return your layout
          return Container(
            padding: EdgeInsets.all(12),
            height: 250,
            child: Column(children: [
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HybridDocumentPicker(
                                          title: getTranslated(
                                              this.context, 'pickdoc'),
                                          callback: getImage,
                                        ))).then((url) async {
                              if (url != null) {
                                Fiberchat.toast(
                                  getTranslated(this.context, 'plswait'),
                                );

                                onSendMessage(
                                    this.context,
                                    url +
                                        '-BREAK-' +
                                        basename(imageFile.path).toString(),
                                    MessageType.doc,
                                    uploadTimestamp);
                                // Fiberchat.toast(
                                //     getTranslated(this.context, 'sent'));
                              } else {}
                            });
                          },
                          elevation: .5,
                          fillColor: Colors.indigo,
                          child: Icon(
                            Icons.file_copy,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'doc'),
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 14),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HybridVideoPicker(
                                          title: getTranslated(
                                              this.context, 'pickvideo'),
                                          callback: getImage,
                                        ))).then((url) async {
                              if (url != null) {
                                Fiberchat.toast(
                                  getTranslated(this.context, 'plswait'),
                                );
                                String thumbnailurl = await getThumbnail(url);
                                onSendMessage(
                                    context,
                                    url +
                                        '-BREAK-' +
                                        thumbnailurl +
                                        '-BREAK-' +
                                        videometadata,
                                    MessageType.video,
                                    thumnailtimestamp);
                                Fiberchat.toast(
                                    getTranslated(this.context, 'sent'));
                              } else {}
                            });
                          },
                          elevation: .5,
                          fillColor: Colors.pink[600],
                          child: Icon(
                            Icons.video_collection_sharp,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'video'),
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 14),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HybridImagePicker(
                                          title: getTranslated(
                                              this.context, 'pickimage'),
                                          callback: getImage,
                                        ))).then((url) {
                              if (url != null) {
                                onSendMessage(context, url, MessageType.image,
                                    uploadTimestamp);
                              } else {}
                            });
                          },
                          elevation: .5,
                          fillColor: Colors.purple,
                          child: Icon(
                            Icons.image_rounded,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'image'),
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 14),
                        )
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () {
                            hidekeyboard(context);

                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AudioRecord(
                                          title: getTranslated(
                                              this.context, 'record'),
                                          callback: getImage,
                                        ))).then((url) {
                              if (url != null) {
                                onSendMessage(
                                    context,
                                    url +
                                        '-BREAK-' +
                                        uploadTimestamp.toString(),
                                    MessageType.audio,
                                    uploadTimestamp);
                              } else {}
                            });
                          },
                          elevation: .5,
                          fillColor: Colors.yellow[900],
                          child: Icon(
                            Icons.mic_rounded,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'audio'),
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () async {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            await _determinePosition().then(
                              (location) async {
                                Fiberchat.toast(
                                  getTranslated(this.context, 'sent'),
                                );

                                print(location.latitude.toString());
                                print(location.longitude.toString());
                                var locationstring =
                                    'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
                                onSendMessage(
                                    context,
                                    locationstring,
                                    MessageType.location,
                                    DateTime.now().millisecondsSinceEpoch);
                                setState(() {});
                              },
                            );
                          },
                          elevation: .5,
                          fillColor: Colors.cyan[700],
                          child: Icon(
                            Icons.location_on,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'location'),
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () async {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ContactsSelect(
                                        currentUserNo: widget.currentUserNo,
                                        model: widget.model,
                                        biometricEnabled: false,
                                        prefs: prefs,
                                        onSelect: (name, phone) {
                                          onSendMessage(
                                              context,
                                              '$name-BREAK-$phone',
                                              MessageType.contact,
                                              DateTime.now()
                                                  .millisecondsSinceEpoch);
                                        })));
                          },
                          elevation: .5,
                          fillColor: Colors.blue[800],
                          child: Icon(
                            Icons.person,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'contact'),
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ]),
          );
        });
  }

  Widget buildInput(
    BuildContext context,
  ) {
    if (chatStatus == ChatStatus.requested.index) {
      return AlertDialog(
        backgroundColor: Colors.white,
        elevation: 10.0,
        title: Text(
          getTranslated(this.context, 'accept') + '${peer[NICKNAME]} ?',
          style: TextStyle(color: fiberchatBlack),
        ),
        actions: <Widget>[
          FlatButton(
              child: Text(getTranslated(this.context, 'rjt')),
              onPressed: () {
                ChatController.block(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.blocked.index;
                });
              }),
          FlatButton(
              child: Text(getTranslated(this.context, 'acpt')),
              onPressed: () {
                ChatController.accept(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.accepted.index;
                });
              })
        ],
      );
    }
    return Container(
      margin: EdgeInsets.only(bottom: Platform.isIOS == true ? 20 : 0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: 10,
              ),
              decoration: BoxDecoration(
                  color: fiberchatWhite,
                  // border: Border.all(
                  //   color: Colors.red[500],
                  // ),
                  borderRadius: BorderRadius.all(Radius.circular(30))),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                            color: fiberchatWhite,
                            padding: EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.gif,
                              size: 40,
                              color: fiberchatGrey,
                            ),
                            onPressed: () async {
                              final gif = await GiphyPicker.pickGif(
                                  context: context, apiKey: GiphyAPIKey);
                              onSendMessage(
                                  context,
                                  gif.images.original.url,
                                  MessageType.image,
                                  DateTime.now().millisecondsSinceEpoch);
                              hidekeyboard(context);
                            }),
                        IconButton(
                          icon: new Icon(
                            Icons.attachment_outlined,
                            color: fiberchatGrey,
                          ),
                          padding: EdgeInsets.all(0.0),
                          onPressed: chatStatus == ChatStatus.blocked.index
                              ? () {
                                  Fiberchat.toast(
                                      getTranslated(this.context, 'unlck'));
                                }
                              : () {
                                  hidekeyboard(context);
                                  shareMedia(context);
                                },
                          color: fiberchatWhite,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: TextField(
                      maxLines: null,
                      style: TextStyle(fontSize: 18.0, color: fiberchatBlack),
                      controller: textEditingController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          // width: 0.0 produces a thin "hairline" border
                          borderRadius: BorderRadius.circular(1),
                          borderSide:
                              BorderSide(color: Colors.transparent, width: 1.5),
                        ),
                        hoverColor: Colors.transparent,
                        focusedBorder: OutlineInputBorder(
                          // width: 0.0 produces a thin "hairline" border
                          borderRadius: BorderRadius.circular(1),
                          borderSide:
                              BorderSide(color: Colors.transparent, width: 1.5),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(1),
                            borderSide: BorderSide(color: Colors.transparent)),
                        contentPadding: EdgeInsets.fromLTRB(7, 4, 7, 4),
                        hintText: getTranslated(this.context, 'typmsg'),
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Button send message
          Container(
            height: 47,
            width: 47,
            // alignment: Alignment.center,
            margin: EdgeInsets.only(left: 6, right: 10),
            decoration: BoxDecoration(
                color: fiberchatgreen,
                // border: Border.all(
                //   color: Colors.red[500],
                // ),
                borderRadius: BorderRadius.all(Radius.circular(30))),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: IconButton(
                icon: new Icon(
                  Icons.send,
                  color: fiberchatWhite.withOpacity(0.9),
                ),
                onPressed: chatStatus == ChatStatus.blocked.index
                    ? null
                    : () => onSendMessage(
                        context,
                        textEditingController.text,
                        MessageType.text,
                        DateTime.now().millisecondsSinceEpoch),
                color: fiberchatWhite,
              ),
            ),
          ),
        ],
      ),
      width: double.infinity,
      height: 60.0,
      decoration: new BoxDecoration(
        // border: new Border(top: new BorderSide(color: Colors.grey, width: 0.5)),
        color: Colors.transparent,
      ),
    );
  }

  bool empty = true;

  loadMessagesAndListen(
    BuildContext context,
  ) async {
    await FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .collection(chatId)
        .orderBy(TIMESTAMP)
        .get()
        .then((docs) {
      if (docs.docs.isNotEmpty) empty = false;
      docs.docs.forEach((doc) {
        Map<String, dynamic> _doc = Map.from(doc.data());
        int ts = _doc[TIMESTAMP];
        _doc[CONTENT] = decryptWithCRC(_doc[CONTENT]);
        messages.add(Message(buildMessage(context, _doc),
            onDismiss: _doc[FROM] == peerNo ? () => deleteUpto(ts) : null,
            onTap: _doc[TYPE] == MessageType.image.index
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoViewWrapper(
                        message: _doc[CONTENT],
                        tag: ts.toString(),
                        imageProvider:
                            CachedNetworkImageProvider(_doc[CONTENT]),
                      ),
                    ))
                : null, onDoubleTap: () {
          save(_doc);
        }, onLongPress: () {
          contextMenu(context, _doc);
        }, from: _doc[FROM], timestamp: ts));
      });
      if (mounted) {
        setState(() {
          messages = List.from(messages);
        });
      }
      msgSubscription = FirebaseFirestore.instance
          .collection(MESSAGES)
          .doc(chatId)
          .collection(chatId)
          .where(FROM, isEqualTo: peerNo)
          .snapshots()
          .listen((query) {
        if (empty == true || query.docs.length != query.docChanges.length) {
          query.docChanges.where((doc) {
            return doc.oldIndex <= doc.newIndex;
          }).forEach((change) {
            Map<String, dynamic> _doc = Map.from(change.doc.data());
            int ts = _doc[TIMESTAMP];
            _doc[CONTENT] = decryptWithCRC(_doc[CONTENT]);
            messages.add(Message(buildMessage(context, _doc),
                onLongPress: () {
                  contextMenu(context, _doc);
                },
                onTap: _doc[TYPE] == MessageType.image.index
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoViewWrapper(
                            tag: ts.toString(),
                            imageProvider:
                                CachedNetworkImageProvider(_doc[CONTENT]),
                          ),
                        ))
                    : null,
                onDoubleTap: () {
                  save(_doc);
                },
                from: _doc[FROM],
                timestamp: ts,
                onDismiss: () => deleteUpto(ts)));
          });
          if (mounted) {
            setState(() {
              messages = List.from(messages);
            });
          }
        }
      });
    });
  }

  void loadSavedMessages() {
    if (_savedMessageDocs.isEmpty) {
      Save.getSavedMessages(peerNo).then((_msgDocs) {
        if (_msgDocs != null) {
          setState(() {
            _savedMessageDocs = _msgDocs;
          });
        }
      });
    }
  }

  List<Widget> sortAndGroupSavedMessages(
      BuildContext context, List<Map<String, dynamic>> _msgs) {
    _msgs.sort((a, b) => a[TIMESTAMP] - b[TIMESTAMP]);
    List<Message> _savedMessages = new List<Message>();
    List<Widget> _groupedSavedMessages = new List<Widget>();
    _msgs.forEach((msg) {
      _savedMessages.add(Message(
          buildMessage(context, msg, saved: true, savedMsgs: _savedMessages),
          saved: true,
          from: msg[FROM],
          onDoubleTap: () {}, onLongPress: () {
        contextMenu(context, msg, saved: true);
      },
          onDismiss: null,
          onTap: msg[TYPE] == MessageType.image.index
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewWrapper(
                      tag: "saved_" + msg[TIMESTAMP].toString(),
                      imageProvider: msg[CONTENT].toString().startsWith(
                              'http') // See if it is an online or saved
                          ? CachedNetworkImageProvider(msg[CONTENT])
                          : Save.getImageFromBase64(msg[CONTENT]).image,
                    ),
                  ))
              : null,
          timestamp: msg[TIMESTAMP]));
    });

    _groupedSavedMessages.add(Center(
        child: Chip(label: Text(getTranslated(this.context, 'savedconv')))));

    groupBy<Message, String>(_savedMessages, (msg) {
      return getWhen(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));
    }).forEach((when, _actualMessages) {
      _groupedSavedMessages.add(Center(
          child: Chip(
        label: Text(
          when,
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      )));
      _actualMessages.forEach((msg) {
        _groupedSavedMessages.add(msg.child);
      });
    });
    return _groupedSavedMessages;
  }

//-- GROUP BY DATE ---
  List<Widget> getGroupedMessages() {
    List<Widget> _groupedMessages = new List<Widget>();
    int count = 0;
    groupBy<Message, String>(messages, (msg) {
      return getWhen(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));
    }).forEach((when, _actualMessages) {
      _groupedMessages.add(Center(
          child: Chip(
        backgroundColor: Colors.blue[50],
        label: Text(
          when,
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      )));
      _actualMessages.forEach((msg) {
        count++;
        if (unread != 0 && (messages.length - count) == unread - 1) {
          _groupedMessages.add(Center(
              child: Chip(
            backgroundColor: Colors.blueGrey[50],
            label: Text('$unread' + getTranslated(this.context, 'unread')),
          )));
          unread = 0; // reset
        }
        _groupedMessages.add(msg.child);
      });
    });
    return _groupedMessages.reversed.toList();
  }

  Widget buildSavedMessages(
    BuildContext context,
  ) {
    return Flexible(
        child: ListView(
      padding: EdgeInsets.all(10.0),
      children: _savedMessageDocs.isEmpty
          ? [
              Padding(
                  padding: EdgeInsets.only(top: 200.0),
                  child: Text(getTranslated(this.context, 'nosave'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey, fontSize: 18)))
            ]
          : sortAndGroupSavedMessages(context, _savedMessageDocs),
      controller: saved,
    ));
  }

  Widget buildMessages(
    BuildContext context,
  ) {
    if (chatStatus == ChatStatus.blocked.index) {
      return AlertDialog(
        backgroundColor: Colors.white,
        elevation: 10.0,
        title: Text(
          getTranslated(this.context, 'unblock') + ' ${peer[NICKNAME]}?',
          style: TextStyle(color: fiberchatBlack),
        ),
        actions: <Widget>[
          RaisedButton(
              color: fiberchatBlack,
              child: Text(getTranslated(this.context, 'cancel')),
              onPressed: () {
                Navigator.pop(context);
              }),
          RaisedButton(
              color: fiberchatLightGreen,
              child: Text(
                getTranslated(this.context, 'unblock'),
                style: TextStyle(color: fiberchatWhite),
              ),
              onPressed: () {
                ChatController.accept(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.accepted.index;
                });
              })
        ],
      );
    }
    return Flexible(
        child: chatId == '' || messages.isEmpty || sharedSecret == null
            ? ListView(
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(top: 200.0),
                      child: sharedSecret == null
                          ? Center(
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      fiberchatLightGreen)),
                            )
                          : Text(getTranslated(this.context, 'sayhi'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: fiberchatWhite, fontSize: 18))),
                ],
                controller: realtime,
              )
            : ListView(
                padding: EdgeInsets.all(10.0),
                children: getGroupedMessages(),
                controller: realtime,
                reverse: true,
              ));
  }

  getWhen(date) {
    DateTime now = DateTime.now();
    String when;
    if (date.day == now.day)
      when = getTranslated(this.context, 'today');
    else if (date.day == now.subtract(Duration(days: 1)).day)
      when = getTranslated(this.context, 'yesterday');
    else
      when = DateFormat.MMMd().format(date);
    return when;
  }

  getPeerStatus(val) {
    if (val is bool && val == true) {
      return getTranslated(this.context, 'online');
    } else if (val is int) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(val);
      String at = DateFormat.jm().format(date), when = getWhen(date);
      return getTranslated(this.context, 'lastseen') + ' $when $at';
    } else if (val is String) {
      if (val == currentUserNo) return getTranslated(this.context, 'typing');
      return getTranslated(this.context, 'online');
    }
    return getTranslated(this.context, 'loading');
  }

  bool isBlocked() {
    return chatStatus == ChatStatus.blocked.index ?? true;
  }

  call(BuildContext context, bool isvideocall) async {
    prefs = await SharedPreferences.getInstance();
    var mynickname = prefs.getString(NICKNAME) ?? '';

    var myphotoUrl = prefs.getString(PHOTO_URL) ?? '';

    CallUtils.dial(
        currentuseruid: widget.currentUserNo,
        fromDp: myphotoUrl,
        toDp: peer["photoUrl"],
        fromUID: widget.currentUserNo,
        fromFullname: mynickname,
        toUID: widget.peerNo,
        toFullname: peer["nickname"],
        context: context,
        isvideocall: isvideocall);
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      scaffold: Fiberchat.getNTPWrappedWidget(WillPopScope(
          onWillPop: () async {
            setLastSeen();
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              var currentpeer =
                  Provider.of<CurrentChatPeer>(this.context, listen: false);
              currentpeer.setpeer('');
            });
            if (lastSeen == peerNo)
              await FirebaseFirestore.instance
                  .collection(USERS)
                  .doc(currentUserNo)
                  .set({LAST_SEEN: true}, SetOptions(merge: true));
            return Future.value(true);
          },
          child: ScopedModel<DataModel>(
              model: _cachedModel,
              child: ScopedModelDescendant<DataModel>(
                  builder: (context, child, _model) {
                _cachedModel = _model;
                updateLocalUserData(_model);
                return peer != null
                    ? Scaffold(
                        key: _scaffold,
                        backgroundColor: fiberchatGrey,
                        appBar: AppBar(
                          titleSpacing: -10,
                          backgroundColor: fiberchatDeepGreen,
                          title: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (context, a1, a2) =>
                                          ProfileView(peer)));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 5, 0, 5),
                                  child: Fiberchat.avatar(peer),
                                ),
                                SizedBox(
                                  width: 7,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Fiberchat.getNickname(peer),
                                      style: TextStyle(
                                          color: fiberchatWhite,
                                          fontSize: 17.0,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      height: 6,
                                    ),
                                    chatId.isNotEmpty
                                        ? Text(
                                            getPeerStatus(peer[LAST_SEEN]),
                                            style: TextStyle(
                                                color: fiberchatWhite,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400),
                                          )
                                        : Text(
                                            'loading…',
                                            style: TextStyle(
                                                color: fiberchatWhite,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400),
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            SizedBox(
                              width: 35,
                              child: IconButton(
                                  icon: Icon(
                                    Icons.video_call,
                                  ),
                                  onPressed: () async {
                                    //interstitialAd.show();
                                    await Permissions
                                            .cameraAndMicrophonePermissionsGranted()
                                        .then((isgranted) {
                                      if (isgranted == true) {
                                        call(context, true);
                                      } else {
                                        Fiberchat.showRationale(
                                            getTranslated(this.context, 'pmc'));
                                        Navigator.push(
                                            context,
                                            new MaterialPageRoute(
                                                builder: (context) =>
                                                    OpenSettings()));
                                      }
                                    }).catchError((onError) {
                                      Fiberchat.showRationale(
                                            getTranslated(this.context, 'pmc'));
                                      Navigator.push(
                                          context,
                                          new MaterialPageRoute(
                                              builder: (context) =>
                                                  OpenSettings()));
                                    });
                                  }),
                            ),
                            SizedBox(
                              width: 55,
                              child: IconButton(
                                  icon: Icon(
                                    Icons.phone,
                                  ),
                                  onPressed: () async {
                                    //interstitialAd.show();

                                    await Permissions
                                            .cameraAndMicrophonePermissionsGranted()
                                        .then((isgranted) {
                                      print('call button taped by SM,,,,,,,,,,,,,,,,,,');
                                      if (isgranted == true) {
                                        print('call button isgranted true.................');
                                        call(context, false);
                                      } else {
                                        Fiberchat.showRationale(
                                            getTranslated(this.context, 'pmc'));
                                        print('call button isgranted false,,,,,,,,,,,');
                                        Navigator.push(
                                            context,
                                            new MaterialPageRoute(
                                                builder: (context) =>
                                                    OpenSettings()));
                                      }
                                    }).catchError((onError) {
                                      Fiberchat.showRationale(
                                          getTranslated(this.context, 'pmc'));
                                      Navigator.push(
                                          context,
                                          new MaterialPageRoute(
                                              builder: (context) =>
                                                  OpenSettings()));
                                    });
                                  }),
                            ),
                            SizedBox(
                              width: 25,
                              child: PopupMenuButton(
                                padding: EdgeInsets.all(0),
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 0),
                                  child: Icon(Icons.more_vert_outlined,
                                      color: fiberchatWhite),
                                ),
                                color: fiberchatWhite,
                                onSelected: (val) {
                                  switch (val) {
                                    case 'hide':
                                      ChatController.hideChat(
                                          currentUserNo, peerNo);
                                      break;
                                    case 'unhide':
                                      ChatController.unhideChat(
                                          currentUserNo, peerNo);
                                      break;
                                    case 'lock':
                                      ChatController.lockChat(
                                          currentUserNo, peerNo);
                                      break;
                                    case 'unlock':
                                      ChatController.unlockChat(
                                          currentUserNo, peerNo);
                                      break;
                                    case 'block':
                                      ChatController.block(
                                          currentUserNo, peerNo);
                                      break;
                                    case 'unblock':
                                      ChatController.accept(
                                          currentUserNo, peerNo);
                                      Fiberchat.toast(getTranslated(
                                          this.context, 'unblocked'));
                                      break;
                                    case 'tutorial':
                                      Fiberchat.toast(
                                          getTranslated(this.context, 'drag'));
                                      Future.delayed(Duration(seconds: 2))
                                          .then((_) {
                                        Fiberchat.toast(getTranslated(
                                            this.context, 'vsmsg'));
                                      });
                                      break;
                                    case 'remove_wallpaper':
                                      _cachedModel.removeWallpaper(peerNo);
                                      // Fiberchat.toast('Wallpaper removed.');
                                      break;
                                    case 'set_wallpaper':
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  HybridImagePicker(
                                                    title: getTranslated(
                                                        this.context,
                                                        'pickimage'),
                                                    callback: getWallpaper,
                                                  )));
                                      break;
                                  }
                                },
                                itemBuilder: (context) =>
                                    <PopupMenuItem<String>>[
                                  PopupMenuItem<String>(
                                    value: hidden ? 'unhide' : 'hide',
                                    child: Text(
                                      '${hidden ? getTranslated(this.context, 'unhidechat') : getTranslated(this.context, 'hidechat')}',
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: locked ? 'unlock' : 'lock',
                                    child: Text(
                                        '${locked ? getTranslated(this.context, 'unlockchat') : getTranslated(this.context, 'lockchat')}'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: isBlocked() ? 'unblock' : 'block',
                                    child: Text(
                                        '${isBlocked() ? getTranslated(this.context, 'unblockchat') : getTranslated(this.context, 'blockchat')}'),
                                  ),
                                  PopupMenuItem<String>(
                                      value: 'set_wallpaper',
                                      child: Text(getTranslated(
                                          this.context, 'setwall'))),
                                  peer[WALLPAPER] != null
                                      ? PopupMenuItem<String>(
                                          value: 'remove_wallpaper',
                                          child: Text(getTranslated(
                                              this.context, 'removewall')))
                                      : null,
                                  PopupMenuItem<String>(
                                    child: Text(getTranslated(
                                        this.context, 'showtutor')),
                                    value: 'tutorial',
                                  )
                                ].where((o) => o != null).toList(),
                              ),
                            ),
                          ],
                        ),
                        body: Stack(
                          children: <Widget>[
                            new Container(
                              decoration: new BoxDecoration(
                                image: new DecorationImage(
                                    image: peer[WALLPAPER] == null
                                        ? AssetImage(
                                            "assets/images/background.png")
                                        : Image.file(File(peer[WALLPAPER]))
                                            .image,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            PageView(
                              children: <Widget>[
                                Column(
                                  children: [
                                    // List of messages
                                    buildMessages(context),
                                    // Input content
                                    isBlocked()
                                        ? Container()
                                        : buildInput(context),
                                  ],
                                ),
                                Column(
                                  children: [
                                    // List of saved messages
                                    buildSavedMessages(context)
                                  ],
                                ),
                              ],
                            ),

                            // Loading
                            buildLoading()
                          ],
                        ))
                    : Container();
              })))),
    );
  }
}
