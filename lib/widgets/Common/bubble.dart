import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/Providers/seen_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Bubble extends StatelessWidget {
  const Bubble({
    @required this.child,
    @required this.timestamp,
    @required this.delivered,
    @required this.isMe,
    @required this.isContinuing,
    @required this.messagetype,
  });

  final dynamic messagetype;
  final int timestamp;
  final Widget child;
  final dynamic delivered;
  final bool isMe, isContinuing;

  humanReadableTime() => DateFormat('h:mm a')
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  getSeenStatus(seen) {
    if (seen is bool) return true;
    if (seen is String) return true;
    return timestamp <= seen;
  }

  @override
  Widget build(BuildContext context) {
    final bool seen = getSeenStatus(SeenProvider.of(context).value);
    final bg = isMe ? fiberchatteagreen : fiberchatWhite;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    dynamic icon = delivered is bool && delivered
        ? (seen ? Icons.done_all : Icons.done)
        : Icons.access_time;
    final color = isMe
        ? fiberchatBlack.withOpacity(0.5)
        : fiberchatBlack.withOpacity(0.5);
    icon = Icon(icon, size: 14.0, color: seen ? Colors.lightBlue : color);
    if (delivered is Future) {
      icon = FutureBuilder(
          future: delivered,
          builder: (context, res) {
            switch (res.connectionState) {
              case ConnectionState.done:
                return Icon((seen ? Icons.done_all : Icons.done),
                    size: 13.0, color: seen ? Colors.lightBlue : color);
              case ConnectionState.none:
              case ConnectionState.active:
              case ConnectionState.waiting:
              default:
                return Icon(Icons.access_time,
                    size: 13.0, color: seen ? Colors.lightBlue : color);
            }
          });
    }
    dynamic radius = isMe
        ? BorderRadius.only(
            topLeft: Radius.circular(5.0),
            bottomLeft: Radius.circular(5.0),
            bottomRight: Radius.circular(10.0),
          )
        : BorderRadius.only(
            topRight: Radius.circular(5.0),
            bottomLeft: Radius.circular(10.0),
            bottomRight: Radius.circular(5.0),
          );
    dynamic margin = const EdgeInsets.only(top: 20.0, bottom: 1.5);
    if (isContinuing) {
      radius = BorderRadius.all(Radius.circular(5.0));
      margin = const EdgeInsets.all(1.9);
    }

    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Container(
          margin: margin,
          padding: const EdgeInsets.all(8.0),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                  padding: this.messagetype == null ||
                          this.messagetype == MessageType.image ||
                          this.messagetype == MessageType.text
                      ? child is Container
                          ? EdgeInsets.fromLTRB(0, 0, 0, 17)
                          : EdgeInsets.only(right: isMe ? 65.0 : 50.0)
                      : child is Container
                          ? EdgeInsets.all(0.0)
                          : EdgeInsets.only(
                              right: isMe ? 5.0 : 5.0, bottom: 20),
                  child: child),
              Positioned(
                bottom: 0.0,
                right: 0.0,
                child: Row(
                  children: <Widget>[
                    Text(humanReadableTime().toString() + (isMe ? ' ' : ''),
                        style: TextStyle(
                          color: color,
                          fontSize: 10.0,
                        )),
                    isMe ? icon : null
                  ].where((o) => o != null).toList(),
                ),
              ),
            ],
          ),
        )
      ],
    ));
  }
}
