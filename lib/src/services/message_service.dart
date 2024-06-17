part of 'uikit_service.dart';

mixin ZegoMessageService {
  /// send in-room message
  Future<bool> sendInRoomMessage(String message) async {
    final resultErrorCode =
        await ZegoUIKitCore.shared.message.sendBroadcastMessage(message);

    if (ZegoUIKitErrorCode.success != resultErrorCode) {
      ZegoUIKitCore.shared.error.errorStreamCtrl?.add(
        ZegoUIKitError(
          code: ZegoUIKitErrorCode.messageSendError,
          message: 'send in-room message error:$resultErrorCode, '
              'message:$message, '
              '${ZegoUIKitErrorCode.expressErrorCodeDocumentTips}',
          method: 'sendInRoomCommand',
        ),
      );
    }

    return ZegoErrorCode.CommonSuccess == resultErrorCode;
  }

  /// re-send in-room message
  Future<bool> resendInRoomMessage(ZegoInRoomMessage message) async {
    final resultErrorCode =
        await ZegoUIKitCore.shared.message.resendInRoomMessage(message);

    if (ZegoUIKitErrorCode.success != resultErrorCode) {
      ZegoUIKitCore.shared.error.errorStreamCtrl?.add(
        ZegoUIKitError(
          code: ZegoUIKitErrorCode.messageReSendError,
          message: 'resend in-room message error:$resultErrorCode, '
              'message:$message, '
              '${ZegoUIKitErrorCode.expressErrorCodeDocumentTips}',
          method: 'sendInRoomCommand',
        ),
      );
    }

    return ZegoErrorCode.CommonSuccess == resultErrorCode;
  }

  /// get history messages
  List<ZegoInRoomMessage> getInRoomMessages() {
    return ZegoUIKitCore.shared.coreData.messageList;
  }

  /// messages notifier
  Stream<List<ZegoInRoomMessage>> getInRoomMessageListStream() {
    return ZegoUIKitCore.shared.coreData.streamControllerMessageList?.stream ??
        const Stream.empty();
  }

  /// latest message received notifier
  Stream<ZegoInRoomMessage> getInRoomMessageStream() {
    return ZegoUIKitCore
            .shared.coreData.streamControllerRemoteMessage?.stream ??
        const Stream.empty();
  }

  /// local message sent notifier
  Stream<ZegoInRoomMessage> getInRoomLocalMessageStream() {
    return ZegoUIKitCore.shared.coreData.streamControllerLocalMessage?.stream ??
        const Stream.empty();
  }
}
