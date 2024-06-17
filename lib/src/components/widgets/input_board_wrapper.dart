// Dart imports:
import 'dart:ui' as ui;

// Flutter imports:
import 'package:flutter/cupertino.dart';

class ZegoInputBoardWrapper extends StatefulWidget {
  const ZegoInputBoardWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  State<ZegoInputBoardWrapper> createState() => _ZegoInputBoardWrapperState();
}

class _ZegoInputBoardWrapperState extends State<ZegoInputBoardWrapper> {
  final padding = MediaQueryData.fromWindow(ui.window).padding;

  @override
  Widget build(BuildContext context) {
    final hasSafeArea = EdgeInsets.zero == MediaQuery.of(context).padding;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: hasSafeArea
                ? (MediaQuery.of(context).size.height -
                    padding.top -
                    padding.bottom)
                : MediaQuery.of(context).size.height,
            child: widget.child,
          )
        ],
      ),
    );
  }
}
