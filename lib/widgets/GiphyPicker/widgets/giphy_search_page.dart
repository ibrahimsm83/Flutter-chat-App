import 'package:giphy_client/giphy_client.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/widgets/GiphyPicker/widgets/giphy_search_view.dart';
import 'package:flutter/material.dart';

class GiphySearchPage extends StatelessWidget {
  final Widget title;
  final ValueChanged<GiphyGif> onSelected;
  const GiphySearchPage({this.title, @required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: FiberchatTheme,
        child: Scaffold(
            appBar: AppBar(
              title: Image.asset('assets/giphy.png'),
              backgroundColor: fiberchatDeepGreen,
            ),
            body: SafeArea(
                child: GiphySearchView(
                  onSelected: onSelected,
                ),
                bottom: false)));
  }
}
