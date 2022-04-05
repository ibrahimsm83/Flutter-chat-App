import 'package:contacts_service/contacts_service.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Screens/chat_screen/chat.dart';
import 'package:fiberchat/Screens/chat_screen/pre_chat.dart';
import 'package:fiberchat/Screens/contact_screens/AddunsavedContact.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Utils/chat_controller.dart';
import 'package:fiberchat/Utils/open_settings.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:localstorage/localstorage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Contacts extends StatefulWidget {
  const Contacts({
    @required this.currentUserNo,
    @required this.model,
    @required this.biometricEnabled,
    @required this.prefs,
  });
  final String currentUserNo;
  final DataModel model;
  final SharedPreferences prefs;
  final bool biometricEnabled;

  @override
  _ContactsState createState() => new _ContactsState();
}

class _ContactsState extends State<Contacts>
    with AutomaticKeepAliveClientMixin {
  Map<String, String> contacts;
  Map<String, String> _filtered = new Map<String, String>();

  @override
  bool get wantKeepAlive => true;

  final TextEditingController _filter = new TextEditingController();

  String _query;

  @override
  void dispose() {
    super.dispose();
    _filter.dispose();
  }

  _ContactsState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _query = "";
          this._filtered = this.contacts;
        });
      } else {
        setState(() {
          _query = _filter.text;
          this._filtered =
              Map.fromEntries(this.contacts.entries.where((MapEntry contact) {
            return contact.value
                .toLowerCase()
                .trim()
                .contains(new RegExp(r'' + _query.toLowerCase().trim() + ''));
          }));
        });
      }
    });
  }

  loading() {
    return Stack(children: [
      Container(
        child: Center(
            child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(fiberchatBlue),
        )),
      )
    ]);
  }

  @override
  initState() {
    super.initState();
    getContacts();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _appBarTitle = new Text(
        getTranslated(context, 'searchcontact'),
      );
    });
  }

  String getNormalizedNumber(String number) {
    if (number == null) return null;
    return number.replaceAll(new RegExp('[^0-9+]'), '');
  }

  _isHidden(String phoneNo) {
    Map<String, dynamic> _currentUser = widget.model.currentUser;
    return _currentUser[HIDDEN] != null &&
        _currentUser[HIDDEN].contains(phoneNo);
  }

  Future<Map<String, String>> getContacts({bool refresh = false}) async {
    Completer<Map<String, String>> completer = new Completer<Map<String, String>>();

    LocalStorage storage = LocalStorage(CACHED_CONTACTS);

    Map<String, String> _cachedContacts = {};

    completer.future.then((c) {
      c.removeWhere((key, val) => _isHidden(key));
      if (mounted) {
        setState(() {
          this.contacts = this._filtered = c;
        });
      }
    });

    Fiberchat.checkAndRequestPermission(PermissionGroup.contacts).then((res) {
      if (res) {
        storage.ready.then((ready) async {
          if (ready) {
            // var _stored = await storage.getItem(CACHED_CONTACTS);
            // if (_stored == null)
            //   _cachedContacts = new Map<String, String>();
            // else
            //   _cachedContacts = Map.from(_stored);

            // if (refresh == false && _cachedContacts.isNotEmpty)
            //   completer.complete(_cachedContacts);
            // else {
            String getNormalizedNumber(String number) {
              if (number == null) return null;
              return number.replaceAll(new RegExp('[^0-9+]'), '');
            }

            ContactsService.getContacts(withThumbnails: false)
                .then((Iterable<Contact> contacts) async {
              contacts.where((c) => c.phones.isNotEmpty).forEach((Contact p) {
                if (p?.displayName != null && p.phones.isNotEmpty) {
                  List<String> numbers = p.phones.map((number) {
                        String _phone = getNormalizedNumber(number.value);

                        return _phone;
                      })
                      .toList()
                      .where((s) => s != null)
                      .toList();

                  numbers.forEach((number) {
                    _cachedContacts[number] = p.displayName;
                    setState(() {});
                  });
                  setState(() {});
                }
              });
              // await storage.setItem(CACHED_CONTACTS, _cachedContacts);
              completer.complete(_cachedContacts);
            });
          }
          // }
        });
      } else {
        Fiberchat.showRationale(getTranslated(context, 'perm_contact'));
        Navigator.pushReplacement(context,
            new MaterialPageRoute(builder: (context) => OpenSettings()));
      }
    }).catchError((onError) {
      Fiberchat.showRationale('Error occured: $onError');
    });

    return completer.future;
  }

  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = Text('');

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          autofocus: true,
          style: TextStyle(color: fiberchatWhite),
          controller: _filter,
          decoration: new InputDecoration(
              hintText: getTranslated(context, 'search'),
              hintStyle: TextStyle(color: fiberchatWhite)),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text(getTranslated(context, 'searchcontact'));

        _filter.clear();
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Fiberchat.getNTPWrappedWidget(ScopedModel<DataModel>(
        model: widget.model,
        child:
            ScopedModelDescendant<DataModel>(builder: (context, child, model) {
          return Scaffold(
              backgroundColor: fiberchatWhite,
              appBar: AppBar(
                backgroundColor: fiberchatDeepGreen,
                centerTitle: false,
                title: _appBarTitle,
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.add_call),
                    onPressed: () {
                      Navigator.pushReplacement(context,
                          new MaterialPageRoute(builder: (context) {
                        return new AddunsavedNumber(
                            model: widget.model,
                            currentUserNo: widget.currentUserNo);
                      }));
                    },
                  ),
                  IconButton(
                    icon: _searchIcon,
                    onPressed: _searchPressed,
                  )
                ],
              ),
              body: contacts == null
                  ? loading()
                  : RefreshIndicator(
                      onRefresh: () {
                        return getContacts(refresh: true);
                      },
                      child: _filtered.isEmpty
                          ? ListView(children: [
                              Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height /
                                          2.5),
                                  child: Center(
                                    child: Text(
                                        getTranslated(
                                            context, 'nosearchresult'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: fiberchatWhite,
                                        )),
                                  ))
                            ])
                          : ListView.builder(
                              padding: EdgeInsets.all(10),
                              itemCount: _filtered.length,
                              itemBuilder: (context, idx) {
                                MapEntry user = _filtered.entries.elementAt(idx);
                                String phone = user.key;
                                return ListTile(
                                  leading: CircleAvatar(
                                      backgroundColor: fiberchatgreen,
                                      radius: 22.5,
                                      child: Text(
                                        Fiberchat.getInitials(user.value),
                                        style: TextStyle(color: fiberchatWhite),
                                      )),
                                  title: Text(user.value,
                                      style: TextStyle(color: fiberchatBlack)),
                                  subtitle: Text(phone,
                                      style: TextStyle(color: fiberchatGrey)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 0.0),
                                  onTap: () {
                                    hidekeyboard(context);
                                    dynamic wUser = model.userData[phone];
                                    if (wUser != null &&
                                        wUser[CHAT_STATUS] != null) {
                                      if (model.currentUser[LOCKED] != null &&
                                          model.currentUser[LOCKED]
                                              .contains(phone)) {
                                        ChatController.authenticate(
                                            model,
                                            getTranslated(
                                                context, 'auth_neededchat'),
                                            prefs: widget.prefs,
                                            shouldPop: false,
                                            state: Navigator.of(context),
                                            type:
                                                Fiberchat.getAuthenticationType(
                                                    widget.biometricEnabled,
                                                    model), onSuccess: () {
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              new MaterialPageRoute(
                                                  builder: (context) =>
                                                      new ChatScreen(
                                                          model: model,
                                                          currentUserNo: widget
                                                              .currentUserNo,
                                                          peerNo: phone,
                                                          unread: 0)),
                                              (Route r) => r.isFirst);
                                        });
                                      } else {
                                        Navigator.pushReplacement(
                                            context,
                                            new MaterialPageRoute(
                                                builder: (context) =>
                                                    new ChatScreen(
                                                        model: model,
                                                        currentUserNo: widget
                                                            .currentUserNo,
                                                        peerNo: phone,
                                                        unread: 0)));
                                      }
                                    } else {
                                      Navigator.push(context,
                                          new MaterialPageRoute(
                                              builder: (context) {
                                        return new PreChat(
                                            model: widget.model,
                                            name: user.value,
                                            phone: phone,
                                            currentUserNo:
                                                widget.currentUserNo);
                                      }));
                                    }
                                  },
                                );
                              },
                            )));
        })));
  }
}
