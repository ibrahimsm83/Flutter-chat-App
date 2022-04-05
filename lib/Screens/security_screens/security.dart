import 'dart:async';
import 'dart:core';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:fiberchat/widgets/Passcode/passcode_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Security extends StatefulWidget {
  final String phoneNo, answer, title;
  final bool setPasscode, shouldPop;

  final Function onSuccess;

  Security(this.phoneNo,
      {this.shouldPop = false,
      this.setPasscode = false,
      this.answer,
      @required this.title,
      @required this.onSuccess});

  @override
  _SecurityState createState() => _SecurityState();
}

class _SecurityState extends State<Security> {
  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  SharedPreferences prefs;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((_p) {
      prefs = _p;
    });
  }

  String _passCode;

  @override
  Widget build(BuildContext context) {
    return Fiberchat.getNTPWrappedWidget(WillPopScope(
        onWillPop: () {
          // if (!widget.shouldPop) return Future.value(widget.shouldPop);
          // else return widget.onSuccess();
          return Future.value(widget.shouldPop);
        },
        child: Stack(children: [
          Theme(
              child: Scaffold(
                  appBar: AppBar(
                    title: Text(widget.title),
                    elevation: 0,
                    backgroundColor: fiberchatDeepGreen,
                  ),
                  body: SingleChildScrollView(
                      child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          widget.setPasscode
                              ? ListTile(
                                  trailing: Icon(Icons.check_circle,
                                      color: _passCode == null
                                          ? fiberchatGrey
                                          : fiberchatLightGreen,
                                      size: 35),
                                  title: RaisedButton(
                                    color: fiberchatgreen,
                                    elevation: 0.5,
                                    child: Text(
                                      getTranslated(this.context, 'setpass'),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: _showLockScreen,
                                  ))
                              : null,
                          widget.setPasscode ? SizedBox(height: 20) : null,
                          //TODO://----REMOVE BELOW COMMENT TO ASK SECURITY QUESTION SET----
                          // ListTile(
                          //     subtitle: Text(
                          //   getTranslated(this.context, 'setpasslong'),
                          // )),
                          // ListTile(
                          //   leading: Icon(Icons.lock),
                          //   title: TextFormField(
                          //     decoration: InputDecoration(
                          //         labelText:
                          //             getTranslated(this.context, 'sques')),
                          //     controller: _question,
                          //     autovalidateMode: AutovalidateMode.always,
                          //     validator: (v) {
                          //       return v.trim().isEmpty
                          //           ? getTranslated(this.context, 'quesempty')
                          //           : null;
                          //     },
                          //   ),
                          // ),
                          // ListTile(
                          //   leading: Icon(Icons.lock_open),
                          //   title: TextFormField(
                          //     autovalidateMode: AutovalidateMode.always,
                          //     decoration: InputDecoration(
                          //         labelText:
                          //             getTranslated(this.context, 'sans')),
                          //     controller: _answer,
                          //     validator: (v) {
                          //       if (v.trim().isEmpty)
                          //         return getTranslated(
                          //             this.context, 'ansempty');
                          //       if (Fiberchat.getHashedAnswer(v) ==
                          //           widget.answer)
                          //         return getTranslated(this.context, 'newans');
                          //       return null;
                          //     },
                          //   ),
                          // ),
                          SizedBox(height: 20),
                          ListTile(
                              trailing: RaisedButton(
                            color: fiberchatLightGreen,
                            elevation: 0.5,
                            child: Text(
                              getTranslated(this.context, 'done'),
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              if (widget.setPasscode) {
                                if (_passCode == null)
                                  Fiberchat.toast(getTranslated(
                                      this.context, 'setpasscode'));
                                if (
                                    //TODO://----REMOVE BELOW COMMENT TO ASK SECURITY QUESTION SET----
                                    // _formKey.currentState.validate() &&

                                    _passCode != null) {
                                  var data = {
                                    //TODO://----REMOVE BELOW COMMENT TO ASK SECURITY QUESTION SET----
                                    // QUESTION: _question.text,
                                    // ANSWER:
                                    //     Fiberchat.getHashedAnswer(_answer.text),
                                    PASSCODE:
                                        Fiberchat.getHashedString(_passCode)
                                  };
                                  setState(() {
                                    isLoading = true;
                                  });
                                  prefs.setInt(PASSCODE_TRIES, 0);
                                  prefs.setInt(ANSWER_TRIES, 0);
                                  FirebaseFirestore.instance
                                      .collection(USERS)
                                      .doc(widget.phoneNo)
                                      .update(data)
                                      .then((_) {
                                    Fiberchat.toast(getTranslated(
                                            this.context, 'welcometo') +
                                        ' $Appname!');
                                    widget.onSuccess();
                                  });
                                }
                                prefs.setString(
                                    IS_SECURITY_SETUP_DONE, widget.phoneNo);
                              } else {
                                if (_formKey.currentState.validate()) {
                                  var data = {
                                    //TODO://----REMOVE BELOW COMMENT TO ASK SECURITY QUESTION SET----
                                    // QUESTION: _question.text,
                                    // ANSWER:
                                    //     Fiberchat.getHashedAnswer(_answer.text),
                                  };
                                  setState(() {
                                    isLoading = true;
                                  });
                                  prefs.setInt(PASSCODE_TRIES, 0);
                                  prefs.setInt(ANSWER_TRIES, 0);
                                  FirebaseFirestore.instance
                                      .collection(USERS)
                                      .doc(widget.phoneNo)
                                      .update(data)
                                      .then((_) {
                                    // Fiberchat.toast('Done!');
                                    widget.onSuccess();
                                  });
                                }
                                prefs.setString(
                                    IS_SECURITY_SETUP_DONE, widget.phoneNo);
                              }
                            },
                          )),
                        ].where((o) => o != null).toList(),
                      ),
                    ),
                  ))),
              data: FiberchatTheme),
          Positioned(
            child: isLoading
                ? Container(
                    child: Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(fiberchatBlue)),
                    ),
                    color: fiberchatBlack.withOpacity(0.8),
                  )
                : Container(),
          )
        ])));
  }

  _onPasscodeEntered(String enteredPasscode) {
    bool isValid = enteredPasscode.length == 4;
    _verificationNotifier.add(isValid);
    _passCode = null;
    if (isValid)
      setState(() {
        _passCode = enteredPasscode;
      });
  }

  _showLockScreen() {
    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) =>
              PasscodeScreen(
            onSubmit: null,
            wait: true,
            authentication: false,
            passwordDigits: 4,
            title: (getTranslated(this.context, 'enterpass')),
            passwordEnteredCallback: _onPasscodeEntered,
            cancelLocalizedText: getTranslated(this.context, 'cancel'),
            deleteLocalizedText: getTranslated(this.context, 'delete'),
            shouldTriggerVerification: _verificationNotifier.stream,
          ),
        ));
  }
}
