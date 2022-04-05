import 'dart:async';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/widgets/GiphyPicker/widgets/giphy_context.dart';
import 'package:fiberchat/widgets/GiphyPicker/widgets/giphy_search_page.dart';
import 'package:flutter/material.dart';
import 'package:giphy_client/giphy_client.dart';

typedef ErrorListener = void Function(dynamic error);

/// Provides Giphy picker functionality.
class GiphyPicker {
  /// Renders a full screen modal dialog for searching, and selecting a Giphy image.
  static Future<GiphyGif> pickGif(
      {@required BuildContext context,
      @required String apiKey,
      String rating = GiphyRating.g,
      String lang = GiphyLanguage.english,
      Widget title,
      ErrorListener onError}) async {
    GiphyGif result;

    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => GiphyContext(
                child: GiphySearchPage(onSelected: (gif) {
                  result = gif;
                }),
                apiKey: apiKey,
                rating: rating,
                language: lang,
                onError: onError ?? (error) => _showErrorDialog(context, error),
                onSelected: (gif) {
                  result = gif;
                  Navigator.pop(context);
                }),
            fullscreenDialog: true));

    return result;
  }

  static void _showErrorDialog(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text('Giphy error'),
          content: new Text('An error occurred. $error'),
          actions: <Widget>[
            new FlatButton(
              child: new Text(
                getTranslated(context, 'close'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}