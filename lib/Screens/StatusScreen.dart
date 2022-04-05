import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Utils/open_settings.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
//import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Story_ViewPg.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StatusScreen extends StatefulWidget {
  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  //contacts list
  Map<String, String> contacts;
  Map<String, String> _filtered = new Map<String, String>();

  final TextEditingController _filter = new TextEditingController();

  String _query;
  var statusimgaeloadin;

  @override
  void dispose() {
    super.dispose();
    _filter.dispose();
  }


  //contact list
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




//image picker SM

var firebaseuserid=FirebaseAuth.instance.currentUser;
  File _image;
  final picker = ImagePicker();

DocumentSnapshot doc;
  //String fileName = basename(_image.path);
  //final ref = FirebaseStorage.instance.ref().child('Statusimage/$fileName');
 final ref=FirebaseStorage.instance.ref().child('Statusimage').child('imagename.jpg');
  final db=Firestore.instance;

//image picker sm
void initState() {
  _image=null;
  statusimgaeloadin=null;
  super.initState();

  getContacts();

}
String getNormalizedNumber(String number) {
  if (number == null) return null;
  return number.replaceAll(new RegExp('[^0-9+]'), '');
}

// _isHidden(String phoneNo) {
//  Map<String, dynamic> _currentUser = widget.model.currentUser;
//   return _currentUser[HIDDEN] != null &&
//       _currentUser[HIDDEN].contains(phoneNo);
// }
Future<Map<String, String>> getContacts({bool refresh = false}) async {
  Completer<Map<String, String>> completer = new Completer<Map<String, String>>();

  LocalStorage storage = LocalStorage(CACHED_CONTACTS);

  Map<String, String> _cachedContacts = {};

  completer.future.then((c) {
    // c.removeWhere((key, val) => _isHidden(key));
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
//update status get phone no from streambuilder
  Future updateStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String currentuserno = prefs.getString('currentuserno');
    print(currentuserno);
    if(currentuserno!=null) {
      await db.collection('users').document(currentuserno).updateData({'status': true});
    }
  }
  //update status
  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() async {
      if (pickedFile != null) {
        _image=File(pickedFile.path);
        uploadeStatusImages();
        statusimgaeloadin=true;
      } else {
        print('No image selected.');
      }
    });
  }
  //uploade image in
  Future uploadeStatusImages() async {
    //String fileName = basenamee(_image.path);

    String fileName = _image.path.split('/').last;
    print('filename....................................${fileName}');
    final ref = FirebaseStorage.instance.ref().child('Statusimage/$fileName');
    if (_image.path != null) {
      await ref.putFile(_image).onComplete;
      final url = await ref.getDownloadURL();
      //db.collection('status').add({'ImageUrl':url});
      SharedPreferences prefs = await SharedPreferences.getInstance();
      //Return String
      String currentuserno = prefs.getString('currentuserno');
      print(currentuserno);
      db.collection('status').doc(currentuserno).collection('status').add(
          {'ImageUrl': url});
    }else{
      print('No image selected.');
    }
  }
  @override
  Widget build(BuildContext context) {

      addStringToSF(var pno) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('currentuserno', pno);
    }
    return Container(
      color: Color(0xfff2f2f2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
      InkWell(
      child: Card(
            color: Colors.white,
            elevation: 0.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Stack(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                          "https://s3.amazonaws.com/wll-community-production/images/no-avatar.png"),
                    ),
                    Positioned(
                      bottom: 0.0,
                      right: 1.0,
                      child: Container(
                        height: 20,
                        width: 20,
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  ],
                ),
                title: Text(
                  "My Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Tap to add status update"),
              ),
            ),
          ),
        onTap:
            () {
              print(_filtered);
              print(firebaseuserid.uid);
              updateStatus();
              getImage();
         // loadAssets,
          print("Click event on Container");
        },
      ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Viewed updates",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child:StreamBuilder(
                stream: db.collection('users').snapshots(),
                builder: (context,snapshot){
                  print(snapshot);
                  if(snapshot.hasData)
                  {
                    return ListView.builder(
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context,index) {
                       doc =snapshot.data.documents[index];
                        if(doc['id']==firebaseuserid.uid) {
                          var pho=doc['phone'];
                          addStringToSF(pho);
                          //currentuserno = doc['phone'];
                        }
                        if(doc['status']==true && (_filtered.keys.contains(doc['phone']) ||  _filtered.keys.contains(doc['phone_raw']) ||  _filtered.keys.contains('0'+doc['phone_raw']))){
                          print("rrrrrrrrrrrrrrrrrrrrrr");
                          print(_filtered.keys.contains(doc['phone']));
                  return Container(
                  child: ListTile(
                  leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: doc['photoUrl']==null?NetworkImage( "https://s3.amazonaws.com/wll-community-production/images/no-avatar.png"):NetworkImage(
                    doc['photoUrl']),
                  //"https://pbs.twimg.com/media/EClDvMXU4AAw_lt?format=jpg&name=medium"),
                  // ):_image[0],
                  ),
                          //:Image.file(_image[0]),
                  title:
                  Text(
                  doc['nickname'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Today, 20:16 PM"),
                  onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (context) => StoryPageView(snapshot.data.documents[index]['phone']))),
                  ),
                  //],
                  //),
                  );
                  }else
                    {
                      return Container(height: 5,width: 5,);
                    }
                      }
                    );
                  }
                  else {
                    return Center(child: CircularProgressIndicator());
                  }
                }
            ),
          ),
        ],
      ),
    );
  }
}