// import 'package:nedo/constants/app_constants.dart';
// import 'package:nedo/utils/widgets/GiphyPicker/src/widgets/giphy_image.dart';
// import 'package:flutter/material.dart';
// import 'package:giphy_client/giphy_client.dart';

// /// Presents a Giphy preview image.
// class GiphyPreviewage extends StatelessWidget {
//   final GiphyGif gif;
//   final Widget title;
//   final ValueChanged<GiphyGif> onSelected;

//   const GiphyPreviewPage(
//       {@required this.gif, @required this.onSelected, this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//         data: FiberchatTheme,
//         child: Scaffold(
//             appBar: AppBar(
//                 backgroundColor: fiberchatDeepGreen,
//                 title: title,
//                 actions: <Widget>[
//                   // IconButton(
//                   //     icon: Icon(Icons.check),
//                   //     onPressed: () {
//                   //       onSelected(gif);
//                   //       Navigator.pop(context);
//                   //     })
//                   FlatButton(
//                       onPressed: () {
//                         onSelected(gif);
//                         Navigator.pop(context);
//                       },
//                       child: Row(
//                         children: [
//                           Text(
//                             'SEND',
//                             style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white),
//                           ),
//                           SizedBox(
//                             width: 6,
//                           ),
//                           Icon(
//                             Icons.send,
//                             color: Colors.white,
//                             size: 19,
//                           )
//                         ],
//                       ))
//                 ]),
//             body: SafeArea(
//                 child: Center(child: GiphyImage.original(gif: gif)),
//                 bottom: false)));
//   }
// }
