import 'dart:core';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Screens/chat_screen/chat.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreChat extends StatefulWidget {
  final String name, phone, currentUserNo;
  final DataModel model;
  const PreChat(
      {@required this.name,
      @required this.phone,
      @required this.currentUserNo,
      @required this.model});

  @override
  _PreChatState createState() => _PreChatState();
}

class _PreChatState extends State<PreChat> {
  bool isLoading, isUser = false;
  bool issearching = true;
  String peerphone;
  bool issearchraw = false;
  String formattedphone;

  @override
  initState() {
    super.initState();
    print(widget.phone);
    isLoading = true;
    String peer = widget.phone;
    // String peer = '+213-0791809113';
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
              formattedphone =
                  peerphone.substring(code.length, peerphone.length);
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
    getUser();
  }

  getUser() {
    Query query = issearchraw == true
        ? FirebaseFirestore.instance
            .collection(USERS)
            .where(PHONERAW, isEqualTo: formattedphone ?? peerphone)
            .limit(1)
        : FirebaseFirestore.instance
            .collection(USERS)
            .where(PHONE, isEqualTo: formattedphone ?? peerphone)
            .limit(1);

    query.get().then((user) {
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
                        : formattedphone.substring(1, formattedphone.length))
                .limit(1)
            : FirebaseFirestore.instance
                .collection(USERS)
                .where(PHONERAW,
                    isEqualTo: formattedphone == null
                        ? peerphone.substring(1, peerphone.length)
                        : formattedphone.substring(1, formattedphone.length))
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

  @override
  Widget build(BuildContext context) {
    return Fiberchat.getNTPWrappedWidget(Scaffold(
      appBar:
          AppBar(backgroundColor: fiberchatDeepGreen, title: Text(widget.name)),
      body: isLoading == true
          ? Center(
              child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(fiberchatBlue),
            ))
          : Stack(children: <Widget>[
              Container(
                  child: Center(
                child: !isUser
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Padding(
                              padding: const EdgeInsets.all(28.0),
                              child: Text(
                                  widget.name +
                                      getTranslated(context, 'notexist') +
                                      " $Appname",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: fiberchatBlack,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.0)),
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            RaisedButton(
                              elevation: 0.5,
                              color: fiberchatBlue,
                              textColor: fiberchatWhite,
                              child: Text(
                                getTranslated(context, 'invite') +
                                    ' ${widget.name}',
                                style: TextStyle(color: fiberchatWhite),
                              ),
                              onPressed: () {
                                Fiberchat.invite(context);
                              },
                            )
                          ])
                    : Container(),
              )),
              // Loading
              buildLoading()
            ]),
      backgroundColor: fiberchatWhite,
    ));
  }
}
