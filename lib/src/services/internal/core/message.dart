// ignore_for_file: no_leading_underscores_for_local_identifiers
part of 'core.dart';

/// @nodoc
mixin ZegoUIKitCoreMessage {
  final _messageImpl = ZegoUIKitCoreMessageImpl();

  ZegoUIKitCoreMessageImpl get message => _messageImpl;
}

/// @nodoc
class ZegoUIKitCoreMessageImpl extends ZegoUIKitExpressEventInterface {
  ZegoUIKitCoreData get coreData => ZegoUIKitCore.shared.coreData;

  void clear() {
    coreData.messageList.clear();
    coreData.streamControllerMessageList?.add(
      List<ZegoInRoomMessage>.from(coreData.messageList),
    );
  }

  /// @return Error code, please refer to the error codes document https://docs.zegocloud.com/en/5548.html for details.
  Future<int> sendBroadcastMessage(String message) async {
    coreData.localMessageId = coreData.localMessageId - 1;

    final messageItem = ZegoInRoomMessage(
      messageID: coreData.localMessageId,
      user: coreData.localUser.toZegoUikitUser(),
      message: message,
      timestamp: coreData.networkDateTime_.millisecondsSinceEpoch,
    );
    messageItem.state.value = ZegoInRoomMessageState.idle;

    coreData.messageList.add(messageItem);
    coreData.streamControllerMessageList?.add(
      List<ZegoInRoomMessage>.from(coreData.messageList),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (ZegoInRoomMessageState.idle == messageItem.state.value) {
        /// if the status is still Idle after 300 ms,  it mean the message is not sent yet.
        messageItem.state.value = ZegoInRoomMessageState.sending;
        coreData.streamControllerMessageList?.add(
          List<ZegoInRoomMessage>.from(coreData.messageList),
        );
      }
    });

    return ZegoExpressEngine.instance
        .sendBroadcastMessage(coreData.room.id, message)
        .then((ZegoIMSendBroadcastMessageResult result) {
      messageItem.state.value = (result.errorCode == 0)
          ? ZegoInRoomMessageState.success
          : ZegoInRoomMessageState.failed;

      if (ZegoErrorCode.CommonSuccess == result.errorCode) {
        messageItem.messageID = result.messageID;
      }
      coreData.streamControllerLocalMessage?.add(messageItem);

      coreData.streamControllerMessageList?.add(
        List<ZegoInRoomMessage>.from(coreData.messageList),
      );

      return result.errorCode;
    });
  }

  /// @return Error code, please refer to the error codes document https://docs.zegocloud.com/en/5548.html for details.
  Future<int> resendInRoomMessage(ZegoInRoomMessage message) async {
    coreData.messageList.removeWhere(
      (element) => element.messageID == message.messageID,
    );
    return sendBroadcastMessage(message.message);
  }

  @override
  void onIMRecvBroadcastMessage(
    String roomID,
    List<ZegoBroadcastMessageInfo> messageList,
  ) {
    for (final _message in messageList) {
      final message = ZegoInRoomMessage.fromBroadcastMessage(_message);
      coreData.streamControllerRemoteMessage?.add(message);
      coreData.messageList.add(message);
    }

    if (coreData.messageList.length > 500) {
      coreData.messageList.removeRange(
        0,
        coreData.messageList.length - 500,
      );
    }

    coreData.streamControllerMessageList?.add(List<ZegoInRoomMessage>.from(
      coreData.messageList,
    ));
  }
}
