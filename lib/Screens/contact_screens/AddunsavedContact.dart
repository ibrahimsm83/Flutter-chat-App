import 'dart:core';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Screens/auth_screens/login.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Screens/chat_screen/chat.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddunsavedNumber extends StatefulWidget {
  final String currentUserNo;
  final DataModel model;
  const AddunsavedNumber({@required this.currentUserNo, @required this.model});

  @override
  _AddunsavedNumberState createState() => _AddunsavedNumberState();
}

class _AddunsavedNumberState extends State<AddunsavedNumber> {
  bool isLoading, isUser = true;
  bool istyping = true;
  @override
  initState() {
    super.initState();
    // getUser();
    // isLoading = true;
  }

  getUser(String searchphone) {
    FirebaseFirestore.instance
        .collection(USERS)
        .doc(searchphone)
        .get()
        .then((user) {
      if (user.exists &&
          user.data().containsKey(PHONE) &&
          user.data().containsKey(PHONERAW) &&
          user.data().containsKey(COUNTRY_CODE)) {
        print('userfound');
        setState(() {
          isLoading = false;
          istyping = false;
          isUser = user.exists;

          if (isUser) {
            // var peer = user;
            widget.model.addUser(user);
            Navigator.pushReplacement(
                context,
                new MaterialPageRoute(
                    builder: (context) => new ChatScreen(
                        unread: 0,
                        currentUserNo: widget.currentUserNo,
                        model: widget.model,
                        peerNo: searchphone)));
          }
        });
      } else {
        print('usernotfound');
        setState(() {
          isLoading = false;
          isUser = false;
          istyping = false;
        });
      }
    }).catchError((err) {});
  }

  final _phoneNo = TextEditingController();

  String phoneCode = DEFAULT_COUNTTRYCODE_NUMBER;
  Widget buildLoading() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(17, 52, 17, 8),
          child: Container(
            margin: EdgeInsets.only(top: 0),

            // padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            // height: 63,
            height: 63,
            // width: w / 1.18,
            child: Form(
              // key: _enterNumberFormKey,
              child: MobileInputWithOutline(
                buttonhintTextColor: fiberchatGrey,
                borderColor: fiberchatGrey.withOpacity(0.2),
                controller: _phoneNo,
                initialCountryCode: DEFAULT_COUNTTRYCODE_ISO,
                onSaved: (phone) {
                  setState(() {
                    phoneCode = phone.countryCode;
                    istyping = true;
                  });
                  print(phoneCode);
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(13, 22, 13, 8),
          child: isLoading == true
              ? Center(
                  child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(fiberchatLightGreen)),
                )
              : MySimpleButton(
                  buttoncolor: fiberchatLightGreen.withOpacity(0.99),
                  buttontext: getTranslated(context, 'searchuser'),
                  onpressed: () {
                    RegExp e164 = new RegExp(r'^\+[1-9]\d{1,14}$');

                    String _phone = _phoneNo.text.toString().trim();
                    if ((_phone.isNotEmpty &&
                            e164.hasMatch(phoneCode + _phone)) &&
                        widget.currentUserNo != phoneCode + _phone) {
                      setState(() {
                        isLoading = true;
                      });

                      print(phoneCode + _phone);
                      getUser(phoneCode + _phone);
                    } else {
                      Fiberchat.toast(widget.currentUserNo != phoneCode + _phone
                          ? getTranslated(context, 'validnum')
                          : getTranslated(context, 'validnum'));
                    }
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Fiberchat.getNTPWrappedWidget(Scaffold(
      appBar: AppBar(
          backgroundColor: fiberchatDeepGreen,
          title: Text(
            getTranslated(context, 'chatws'),
            style: TextStyle(fontSize: 15),
          )),
      body: Stack(children: <Widget>[
        Container(
            child: Center(
          child: !isUser
              ? istyping == true
                  ? SizedBox()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          SizedBox(
                            height: 140,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Text(
                                phoneCode +
                                    '-' +
                                    _phoneNo.text.trim() +
                                    getTranslated(context, 'notexist') +
                                    Appname,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: fiberchatBlack,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20.0)),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          RaisedButton(
                            elevation: 0.5,
                            color: fiberchatBlue,
                            textColor: fiberchatWhite,
                            child: Text(
                              getTranslated(context, 'invite'),
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
