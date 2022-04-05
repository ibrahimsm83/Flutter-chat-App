import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadeNews extends StatefulWidget {
  @override
  _UploadeNewsState createState() => _UploadeNewsState();
}

class _UploadeNewsState extends State<UploadeNews> {
  //snackbar message
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  void _showMessageInScaffold(String message){
    _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(message),
        )
    );
  }
//text input field clear
  clearTextInput1(){
    _Controllernewstitle.clear();
  }
  clearTextInput2(){

    _Controllernewsdesc.clear();

  }

  TextEditingController _Controllernewstitle = TextEditingController();
  TextEditingController _Controllernewsdesc = TextEditingController();
  var newstitle;
  var newsdes;
  var selectpic;
  var disablebutton=null;
  bool _validate = false;
  bool _validated=false;
  bool onpressedfun=false;

  @override
  void initState() {
    super.initState();
    selectpic=false;
  }

  File _imageFile;
  final picker = ImagePicker();
  final db = Firestore.instance;

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() async {
      _imageFile = File(pickedFile.path);
      onpressedfun=true;
    });
  }

  Future<void> uploadeNews() async {
    String fileName = basename(_imageFile.path);
    final ref = FirebaseStorage.instance.ref().child('NewsImages/$fileName');
    if (_imageFile.path != null) {
      await ref.putFile(_imageFile).onComplete;
      final url = await ref.getDownloadURL();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      //Return String
      String currentuserno = prefs.getString('currentuserno');
      print(currentuserno);
      if (newstitle != null || newsdes != null) {
        await db.collection('News').doc("$currentuserno").collection('NewsData').doc().set({
       // await db.collection('News').doc("$currentuserno").add({

        'ImageUrl': url,
          'NewsTitle': newstitle,
          'NewsDescription': newsdes
        })
            .then((value)async{
          await db.collection('News').doc("$currentuserno").set({'data':true});
        });

        /*set({
          'ImageUrl': url,
          'NewsTitle': newstitle,
          'NewsDescription': newsdes
        });*/
      } else {
        print("newstitle or newsdes ${newstitle + newsdes}");
      }
      print("newstitle or newsdes ${newstitle + newsdes}");
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: Text(
            "Upload News",
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          leading:IconButton( icon: Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: ()=>Navigator.of(context).pop(),
        ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: _imageFile==null
                    ? Container(
                        margin: EdgeInsets.only(top: 30),
                        height: MediaQuery.of(context).size.height * 0.32,
                        width: MediaQuery.of(context).size.width * 0.8,
                        //color: Colors.grey,
                        child: InkWell(
                          child: Card(
                            child: Container(
                              color: Colors.grey[300],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.image,
                                        size: 60.0,
                                      ),
                                    ),
                                  ),
                                  Container(
                                      margin: EdgeInsets.only(top: 40),
                                      child: Text(
                                        "Choose Your Image",
                                        style: TextStyle(fontSize: 24),
                                      )),
                                ],
                              ),
                            ),
                          ),
                          onTap: () {

                            setState(() {
                              getImage();
                              selectpic=true;
                              print("Select image from gallery");
                            });
                          },
                        ),
                      )
                    : Container(
                        margin: EdgeInsets.only(top: 30),
                        height: MediaQuery.of(context).size.height * 0.32,
                        width: MediaQuery.of(context).size.width * 0.8,
                        //color: Colors.grey,
                        child: Card(
                          child: Container(
                            color: Colors.grey[300],
                            child: _imageFile != null
                                ? Image.file(
                                    _imageFile,
                                    fit: BoxFit.fill,
                                  )
                                : Text("No selected image"),
                          ),
                        ),
                      ),
              ),

              Container(
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.01),
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: _Controllernewstitle,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "News Title",
                    //'Value Can\'t Be Empty'
                    errorText: _validate ? 'Value Can\'t Be Empty': null,
                  ),

                  // keyboardType:TextInputType.number ,
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.01),
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: _Controllernewsdesc,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "News Description",
                    errorText:  _validated ? 'Value Can\'t Be Empty': null,
                  ),
                  maxLines: 5,
                  // keyboardType:TextInputType.number ,
                ),
              ),
              //buttons
              Container(
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.08),
                height: 40,
                width: MediaQuery.of(context).size.width * 0.25,
                child: TextButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.resolveWith(
                        (Set<MaterialState> states) {
                      return Colors.white;
                    }),
                    backgroundColor: MaterialStateProperty.resolveWith(
                        (Set<MaterialState> states) {
                      return Colors.red;
                    }),
                  ),
                  onPressed: () async{
                    onpressedfun==true?
                    setState(() {
                      newstitle = _Controllernewstitle.text;
                      newsdes = _Controllernewsdesc.text;
                      _Controllernewstitle.text.isEmpty ? _validate = true : _validate = false;
                      _Controllernewsdesc.text.isEmpty ? _validated = true : _validated = false;
                      if( _Controllernewstitle.text.isNotEmpty && _Controllernewsdesc.text.isNotEmpty&&onpressedfun==true){
                        _showMessageInScaffold("News Uploaded Successfully!");
                      }
                      clearTextInput1();
                      clearTextInput2();
                    }):{};
                    await uploadeNews();
                  },
                  child: Text('Upload'),
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
