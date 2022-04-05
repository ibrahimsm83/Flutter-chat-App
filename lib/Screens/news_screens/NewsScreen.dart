import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';

import 'UploadeNews.dart';

// final Image image;
// final String title;
// final String description;
//
// const StyleCard({
// Key key,
// this.image,
// this.title,
// this.description
// }) : super(key: key);

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  //snackbar message
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void _showMessageInScaffold(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      content: Text(message),
    ));
  }

  TextEditingController _Controllerphno = TextEditingController();
  TextEditingController _Controllerpassw = TextEditingController();
  bool _validate = false;
  bool _validated = false;
  bool deletebtn = false;

  var phoneno;
  var pass;

  @override
  void initState() {
    body();
    // TODO: implement initState
    super.initState();
  }

  //text input field clear
  clearTextInput1() {
    _Controllerphno.clear();
  }

  clearTextInput2() {
    _Controllerpassw.clear();
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
            "News Screen",
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: <Widget>[
            Container(
              child: TextButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  String currentuserno = prefs.getString('currentuserno');
                  print("Current users numbers ${currentuserno}");
                  //showDialog();
                  _showDialog();

                  // Navigator.push(context,
                  //     MaterialPageRoute(builder: (context) => UploadeNews()));
                },
                child: Text(
                  'Upload',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: body(),
      ),
    );
  }

//dialogbox 1
  _showDialog() async {
    await showDialog<String>(
      context: context,
      child: new AlertDialog(
        //contentPadding: const EdgeInsets.all(16.0),
        content: Container(
          width: 300,
          height: 220,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new TextField(
                autofocus: true,
                controller: _Controllerphno,
                decoration: new InputDecoration(
                  labelText: 'Enter Number*',
                  hintText: '0312345612*',
                  errorText: _validate ? 'Value Can\'t Be Empty' : null,
                ),
              ),
              //password textbox
              new TextField(
                autofocus: true,
                controller: _Controllerpassw,
                obscureText: true,
                decoration: new InputDecoration(
                  labelText: 'Enter Password*',
                  hintText: '*********',
                  errorText: _validated ? 'Value Can\'t Be Empty' : null,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FlatButton(
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(color: Colors.blue),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("admin")
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          final list = snapshot.data.docs;
                          return new FlatButton(
                              child: const Text(
                                'CHECK',
                                style: TextStyle(color: Colors.blue),
                              ),
                              onPressed: () {
                                setState(() {
                                  phoneno = _Controllerphno.text;
                                  pass = _Controllerpassw.text;
                                  _Controllerphno.text.isEmpty
                                      ? _validate = true
                                      : _validate = false;
                                  _Controllerpassw.text.isEmpty
                                      ? _validated = true
                                      : _validated = false;
                                  if (_Controllerphno.text.isNotEmpty &&
                                      _Controllerpassw.text.isNotEmpty) {
                                    clearTextInput1();
                                    clearTextInput2();
                                    print("-------------------------");
                                    print(phoneno);
                                    print(pass);
                                    if (phoneno == list[0]['PhoneNo'] &&
                                        pass == list[0]['Password']) {
                                      setState(() {
                                        deletebtn = true;
                                      });
                                      return Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  UploadeNews()));
                                    } else {
                                      _showMessageInScaffold(
                                          "Incorrect Phone Number and password");
                                    }
                                    //Navigator.pop(context);
                                    //_showMessageInScaffold("News Uploaded Successfully!");
                                  } else {
                                    _showMessageInScaffold(
                                        "Enter Correct Phone Number and password");
                                  }
                                });
                              });
                        } else {
                          return CircularProgressIndicator();
                        }
                      }),
                  //
                  //})
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  //dialogbox 1 end

  Widget body() {
    //var stream=Firestore.instance.collection('News').snapshots();
    //print(stream.first);
    return ListView(
        shrinkWrap: true,
        children: [
      StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("News").snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              final list = snapshot.data.docs;
              print(',,,,,,,,,,,,,,,,,,,${snapshot.hasData.toString()}');
              print(',,,,,,,,,,,,,,,,,,,${snapshot.data.docs.length}');
              print(',,,,,,,,,,,,,,,,,,,${list.length}');
              return ListView.builder(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  //scrollDirection: Axis.vertical,
                  //physics: ScrollPhysics(),
                  //itemCount: snapshot.data.docs.length,
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int index) {
                    String newsid = snapshot.data.docs[index].id;

                    print(',,,,,,,,,,,,,,,,,,,${newsid}');
                    //return Text('$newsid');
                    //for retive subcollection data use another streambuilder

                    return StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('News')
                            .doc(newsid)
                            .collection('NewsData')
                            .snapshots(),
                        // stream: ,
                        builder: (BuildContext context, snap) {
                          if (snap.hasData) {
                            return ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                physics: ScrollPhysics(),
                                itemCount: snap.data.docs.length,
                                itemBuilder: (BuildContext context, int inde) {
                                  String newsdataid = snap.data.docs[inde].id;
                                  print(
                                      ',,,,,,,,newsdataid,,,,,,,,,,,${newsdataid}');
                                  String imgurl =
                                      snap.data.docs[inde]['ImageUrl'];
                                  //print(',,,,,,,,,,,,,,,,,,,${imgurl}');
                                  String ntitle =
                                      snap.data.docs[inde]['NewsTitle'];
                                  //print(',,,,,,,,,,,,,,,,,,,${ntitle}');
                                  String nDescription =
                                      snap.data.docs[inde]['NewsDescription'];
                                  //print(',,,,,,,,,,,,,,,,,,,${nDescription}');
                                  return Card(
                                    child: Column(
                                      //mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.4,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9,
                                          child: Image.network(
                                            imgurl,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                        Text(
                                          ntitle,
                                          style: TextStyle(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              fontSize: 22),
                                          textAlign: TextAlign.left,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          nDescription,
                                          style: TextStyle(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              fontSize: 16),
                                        ),
                                        deletebtn == true
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  RaisedButton(
                                                    color: Colors.red,
                                                    onPressed: () {
                                                      FirebaseFirestore.instance
                                                          .collection('News')
                                                          .doc(newsid)
                                                          .collection(
                                                              'NewsData')
                                                          .doc(newsdataid)
                                                          .delete();
                                                    },
                                                    child: Text(
                                                      "DELETE",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                ],
                                              )
                                            : SizedBox(height: 10),
                                      ],
                                    ),
                                  );
                                });
                          } else {
                            return Center(child: CircularProgressIndicator());
                          }
                        });
                  });
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    ]);
  }
}
