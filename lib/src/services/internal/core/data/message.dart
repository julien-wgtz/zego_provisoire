// Dart imports:
import 'dart:async';

// Project imports:
import 'package:zego_uikit/src/services/services.dart';

mixin ZegoUIKitCoreDataMessage {
  int localMessageId = 0;
  List<ZegoInRoomMessage> messageList = []; // uid:user

  StreamController<List<ZegoInRoomMessage>>? streamControllerMessageList;

  StreamController<ZegoInRoomMessage>? streamControllerRemoteMessage;

  StreamController<ZegoInRoomMessage>? streamControllerLocalMessage;

  void initMessage() {
    ZegoLoggerService.logInfo(
      'init message',
      subTag: 'core data',
    );
    streamControllerMessageList ??=
        StreamController<List<ZegoInRoomMessage>>.broadcast();
    streamControllerRemoteMessage ??=
        StreamController<ZegoInRoomMessage>.broadcast();
    streamControllerLocalMessage ??=
        StreamController<ZegoInRoomMessage>.broadcast();
  }

  void uninitMessage() {
    ZegoLoggerService.logInfo(
      'uninit message',
      subTag: 'core data',
    );

    streamControllerMessageList?.close();
    streamControllerMessageList = null;

    streamControllerRemoteMessage?.close();
    streamControllerRemoteMessage = null;

    streamControllerLocalMessage?.close();
    streamControllerLocalMessage = null;
  }
}
