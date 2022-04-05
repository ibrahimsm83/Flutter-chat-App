import 'package:flutter/foundation.dart';

class CurrentChatPeer with ChangeNotifier {
  String peerid = '';

  setpeer(
    String id,
  ) {
    peerid = id;
    notifyListeners();
  }
}
