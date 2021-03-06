import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Services/Admob/admob.dart';
import 'package:fiberchat/Screens/chat_screen/utils/messagedata.dart';
import 'package:fiberchat/Screens/call_history/callhistory.dart';
import 'package:fiberchat/Screens/chat_screen/chat.dart';
import 'package:fiberchat/Screens/contact_screens/contacts.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Services/Providers/user_provider.dart';
import 'package:fiberchat/Utils/alias.dart';
import 'package:fiberchat/Utils/chat_controller.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';

class RecentChats extends StatefulWidget {
  RecentChats(
      {@required this.currentUserNo,
      @required this.isSecuritySetupDone,
      @required this.prefs,
      key})
      : super(key: key);
  final String currentUserNo;
  final SharedPreferences prefs;
  final bool isSecuritySetupDone;
  @override
  State createState() =>
      new RecentChatsState(currentUserNo: this.currentUserNo);
}

class RecentChatsState extends State<RecentChats> {
  RecentChatsState({Key key, this.currentUserNo}) {
    _filter.addListener(() {
      _userQuery.add(_filter.text.isEmpty ? '' : _filter.text);
    });
  }

  final TextEditingController _filter = new TextEditingController();
  bool isAuthenticating = false;

  List<StreamSubscription> unreadSubscriptions = List<StreamSubscription>();

  List<StreamController> controllers = new List<StreamController>();

  @override
  void initState() {
    super.initState();

    Fiberchat.internetLookUp();
  }

  getuid(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    userProvider.getUserDetails(currentUserNo);
  }

  void cancelUnreadSubscriptions() {
    unreadSubscriptions.forEach((subscription) {
      subscription?.cancel();
    });
  }

  DataModel _cachedModel;
  bool showHidden = false, biometricEnabled = false;

  String currentUserNo;

  bool isLoading = false;

  Widget buildItem(BuildContext context, Map<String, dynamic> user) {
    if (user[PHONE] as String == currentUserNo) {
      return Container(width: 0, height: 0);
    } else {
      return StreamBuilder(
        stream: getUnread(user).asBroadcastStream(),
        builder: (context, AsyncSnapshot<MessageData> unreadData) {
          int unread =
              unreadData.hasData && unreadData.data.snapshot.docs.isNotEmpty
                  ? unreadData.data.snapshot.docs
                      .where((t) => t[TIMESTAMP] > unreadData.data.lastSeen)
                      .length
                  : 0;
          return Theme(
              data: ThemeData(
                  splashColor: fiberchatBlue,
                  highlightColor: Colors.transparent),
              child: Column(
                children: [
                  ListTile(
                      onLongPress: () {
                        // ChatController.authenticate(_cachedModel,
                        //     'Authentication needed to unlock the chat.',
                        //     state: state,
                        //     shouldPop: true,
                        //     type: Fiberchat.getAuthenticationType(
                        //         biometricEnabled, _cachedModel),
                        //     prefs: prefs, onSuccess: () async {
                        //   await Future.delayed(Duration(seconds: 0));
                        //   unawaited(showDialog(
                        //       context: context,
                        //       builder: (context) {
                        //         return AliasForm(user, _cachedModel);
                        //       }));
                        // });

                        unawaited(showDialog(
                            context: context,
                            builder: (context) {
                              return AliasForm(user, _cachedModel);
                            }));
                      },
                      leading:
                          customCircleAvatar(url: user['photoUrl'], radius: 22),
                      title: Text(
                        Fiberchat.getNickname(user),
                        style: TextStyle(color: fiberchatBlack, fontSize: 16),
                      ),
                      onTap: () {
                        if (_cachedModel.currentUser[LOCKED] != null &&
                            _cachedModel.currentUser[LOCKED]
                                .contains(user[PHONE])) {
                          NavigatorState state = Navigator.of(context);
                          ChatController.authenticate(_cachedModel,
                              getTranslated(context, 'auth_neededchat'),
                              state: state,
                              shouldPop: false,
                              type: Fiberchat.getAuthenticationType(
                                  biometricEnabled, _cachedModel),
                              prefs: widget.prefs, onSuccess: () {
                            state.pushReplacement(new MaterialPageRoute(
                                builder: (context) => new ChatScreen(
                                    unread: unread,
                                    model: _cachedModel,
                                    currentUserNo: currentUserNo,
                                    peerNo: user[PHONE] as String)));
                          });
                        } else {
                          Navigator.push(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => new ChatScreen(
                                      unread: unread,
                                      model: _cachedModel,
                                      currentUserNo: currentUserNo,
                                      peerNo: user[PHONE] as String)));
                        }
                      },
                      trailing: unread != 0
                          ? Container(
                              child: Text(unread.toString(),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              padding: const EdgeInsets.all(7.0),
                              decoration: new BoxDecoration(
                                shape: BoxShape.circle,
                                color: user[LAST_SEEN] == true
                                    ? Colors.green[400]
                                    : Colors.blue[300],
                              ),
                            )
                          : Container(
                              child: Container(width: 0, height: 0),
                              padding: const EdgeInsets.all(7.0),
                              decoration: new BoxDecoration(
                                shape: BoxShape.circle,
                                color: user[LAST_SEEN] == true
                                    ? Colors.green[400]
                                    : Colors.grey,
                              ),
                            )),
                  Divider(),
                ],
              ));
        },
      );
    }
  }

  Stream<MessageData> getUnread(Map<String, dynamic> user) {
    String chatId = Fiberchat.getChatId(currentUserNo, user[PHONE]);
    var controller = StreamController<MessageData>.broadcast();
    unreadSubscriptions.add(FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .snapshots()
        .listen((doc) {
      if (doc[currentUserNo] != null && doc[currentUserNo] is int) {
        unreadSubscriptions.add(FirebaseFirestore.instance
            .collection(MESSAGES)
            .doc(chatId)
            .collection(chatId)
            .snapshots()
            .listen((snapshot) {
          controller.add(
              MessageData(snapshot: snapshot, lastSeen: doc[currentUserNo]));
        }));
      }
    }));
    controllers.add(controller);
    return controller.stream;
  }

  _isHidden(phoneNo) {
    Map<String, dynamic> _currentUser = _cachedModel.currentUser;
    return _currentUser[HIDDEN] != null &&
        _currentUser[HIDDEN].contains(phoneNo);
  }

  StreamController<String> _userQuery =
      new StreamController<String>.broadcast();

  List<Map<String, dynamic>> _users = List<Map<String, dynamic>>();

  _chats(Map<String, Map<String, dynamic>> _userData,
      Map<String, dynamic> currentUser) {
    _users = Map.from(_userData)
        .values
        .where((_user) => _user.keys.contains(CHAT_STATUS))
        .toList()
        .cast<Map<String, dynamic>>();
    Map<String, int> _lastSpokenAt = _cachedModel.lastSpokenAt;
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>();

    _users.sort((a, b) {
      int aTimestamp = _lastSpokenAt[a[PHONE]] ?? 0;
      int bTimestamp = _lastSpokenAt[b[PHONE]] ?? 0;
      return bTimestamp - aTimestamp;
    });

    if (!showHidden) {
      _users.removeWhere((_user) => _isHidden(_user[PHONE]));
    }

    return Stack(
      children: <Widget>[
        RefreshIndicator(
            // ignore: missing_return
            onRefresh: () {
              isAuthenticating = false;
              setState(() {
                showHidden = true;
              });
              return Future.value(false);

              // if (showHidden == false && _userData.length != _users.length) {
              //   isAuthenticating = true;
              //   ChatController.authenticate(_cachedModel,
              //       'Authentication needed to show the hidden chats.',
              //       shouldPop: true,
              //       type: Fiberchat.getAuthenticationType(
              //           biometricEnabled, _cachedModel),
              //       state: Navigator.of(context),
              //       prefs: prefs, onSuccess: () {
              //     isAuthenticating = false;
              //     setState(() {
              //       showHidden = true;
              //     });
              //   });
              // } else {
              //   if (showHidden != false)
              //     setState(() {
              //       showHidden = false;
              //     });
              //   return Future.value(false);
              // }
              // return Future.value(false);
            },
            child: Container(
                child: _users.isNotEmpty
                    ? StreamBuilder(
                        stream: _userQuery.stream.asBroadcastStream(),
                        builder: (context, snapshot) {
                          if (_filter.text.isNotEmpty ||
                              snapshot.hasData && snapshot.data.isNotEmpty) {
                            filtered = this._users.where((user) {
                              return user[NICKNAME]
                                  .toLowerCase()
                                  .trim()
                                  .contains(new RegExp(r'' +
                                      _filter.text.toLowerCase().trim() +
                                      ''));
                            }).toList();
                            if (filtered.isNotEmpty)
                              return ListView.builder(
                                padding: EdgeInsets.all(10.0),
                                itemBuilder: (context, index) => buildItem(
                                    context, filtered.elementAt(index)),
                                itemCount: filtered.length,
                              );
                            else
                              return ListView(children: [
                                Padding(
                                    padding: EdgeInsets.only(
                                        top:
                                            MediaQuery.of(context).size.height /
                                                3.5),
                                    child: Center(
                                      child: Text(
                                          getTranslated(
                                              context, 'nosearchresult'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: fiberchatGrey,
                                          )),
                                    ))
                              ]);
                          }
                          return ListView.builder(
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 120),
                            itemBuilder: (context, index) =>
                                buildItem(context, _users.elementAt(index)),
                            itemCount: _users.length,
                          );
                        })
                    : ListView(padding: EdgeInsets.all(0), children: [
                        Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height / 3.5),
                            child: Center(
                              child: Padding(
                                  padding: EdgeInsets.all(30.0),
                                  child:
                                      Text(getTranslated(context, 'startchat'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.59,
                                            color: fiberchatGrey,
                                          ))),
                            ))
                      ]))),
      ],
    );
  }

  DataModel getModel() {
    _cachedModel ??= DataModel(currentUserNo);
    return _cachedModel;
  }

  @override
  Widget build(BuildContext context) {
    return Fiberchat.getNTPWrappedWidget(ScopedModel<DataModel>(
      model: getModel(),
      child:
          ScopedModelDescendant<DataModel>(builder: (context, child, _model) {
        _cachedModel = _model;
        return Scaffold(
            bottomSheet: IsBannerAdShow == true
                ? Container(
                    height: 60,
                    margin: EdgeInsets.only(
                        bottom: Platform.isIOS == true ? 25.0 : 5, top: 0),
                    child: Center(
                      child: AdmobBanner(
                        adUnitId: getBannerAdUnitId(),
                        adSize: AdmobBannerSize.BANNER,
                        listener:
                            (AdmobAdEvent event, Map<String, dynamic> args) {
                          // handleEvent(event, args, 'Banner');
                        },
                        onBannerCreated: (AdmobBannerController controller) {
                          // Dispose is called automatically for you when Flutter removes the banner from the widget tree.
                          // Normally you don't need to worry about disposing this yourself, it's handled.
                          // If you need direct access to dispose, this is your guy!
                          // controller.dispose();
                        },
                      ),
                    ),
                  )
                : SizedBox(
                    height: 0,
                  ),
            backgroundColor: fiberchatWhite,
            floatingActionButton:
                //  _model.loaded
                //     ?
                Padding(
              padding: const EdgeInsets.only(
                  bottom: IsBannerAdShow == true ? 60 : 0),
              child: FloatingActionButton(
                  backgroundColor: fiberchatLightGreen,
                  child: Icon(
                    Icons.chat,
                    size: 30.0,
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new Contacts(
                                prefs: widget.prefs,
                                biometricEnabled: biometricEnabled,
                                currentUserNo: currentUserNo,
                                model: _cachedModel)),
                    );
                    print("sfsgdfsgdfg");
                    print(widget.currentUserNo);
                    print(_cachedModel);
                  }),
            ),
            // : Container(),
            // appBar: AppBar(
            //     bottom: PreferredSize(
            //         preferredSize: Size.fromHeight(40.0),
            //         child: TextField(
            //           autofocus: false,
            //           style: TextStyle(color: fiberchatWhite),
            //           controller: _filter,
            //           decoration: new InputDecoration(
            //               focusedBorder: InputBorder.none,
            //               prefixIcon: Icon(
            //                 Icons.search,
            //                 color: fiberchatWhite.withOpacity(0.5),
            //               ),
            //               hintText: 'Search Recent chats',
            //               hintStyle: TextStyle(
            //                 color: fiberchatWhite.withOpacity(0.4),
            //               )),
            //         )),
            //     backgroundColor: fiberchatDeepGreen,
            //     title: Text(
            //       'Fiberchat',
            //       style: TextStyle(
            //           color: fiberchatWhite,
            //           fontWeight: FontWeight.bold),
            //     ),
            //     centerTitle: false,
            //     actions: []),
            body: _chats(_model.userData, _model.currentUser));
      }),
    ));
  }
}
