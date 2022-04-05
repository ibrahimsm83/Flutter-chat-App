import 'package:flutter/material.dart';
import 'package:flutter_sound/public/util/log.dart';
import 'package:story_view/story_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoryPageView extends StatefulWidget {
  String number;
  StoryPageView(this.number);
  @override
  _StoryPageViewState createState() => _StoryPageViewState();
}

class _StoryPageViewState extends State<StoryPageView> {

  final _storyController = StoryController();

  final db=Firestore.instance;
   var url;
  var firebaseuserid=FirebaseAuth.instance.currentUser;
  List<String> urls = List<String>();
  List<StoryItem> storyItems=List<StoryItem>();
//



  //
  void initState() {
    super.initState();
   getdata();

   // print("dsfsadhf ${urls[0]}");
    //AddStoryItem();
    //dispose();
  }

  // @override
  // void dispose() {
  //   _storyController.dispose();
  //   super.dispose();
  // }

   getdata() async{
    print(firebaseuserid.uid);
    print(widget.number);

   await db.collection("status").doc(widget.number).collection('status').get().then((value){
     //print();

     setState(() {
       for(int i=0; i<value.docs.length; i++){
         //urls.add(StoryItem.pageImage(url:value.docs[i]['ImageUrl']));
       urls.add(value.docs[i]['ImageUrl']);
       storyItems.add(StoryItem.pageImage(url: value.docs[i]['ImageUrl'], controller: _storyController,duration: Duration(seconds: 2))
       );
       }
       print(urls);
     });
       print('urrrllllsss');
       //print(urls);
       print(storyItems[0]);
     // });

      /*print(value.data()["ImageUrl"]);
      var imgurl=value.data()["ImageUrl"];
      setState(() {
        url=imgurl;
        print("dsfsadhf ${url}");
      });*/
    });

  }

  // void handleCompleted(){
  //   widget.controller.nextpage(
  //     duration:Duration(milliseconds: 300),
  //     curve:Curves.easeIn,
  //   );
  //   final currentIndex=u
  // }


  @override
  Widget build(BuildContext context) {
      print("sfdsdfasdfasd {$urls}");

      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          //child:Text("stou view paga")
          child: storyItems.length>0? StoryView(
            controller: _storyController,
             storyItems: storyItems,
            inline: false,
            repeat: true,
      //onComplete fun use for moving next status after comper 1st status
      onComplete: (){
              Navigator.pop(context);
      },
              /*onStoryShow: (s) {
      //Navigator.pop(context);
       },*/
          ):Container(),
        ),
      );
  }
}