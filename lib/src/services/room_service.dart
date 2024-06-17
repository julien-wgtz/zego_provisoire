part of 'uikit_service.dart';

mixin ZegoRoomService {
  /// join room
  Future<ZegoRoomLoginResult> joinRoom(
    String roomID, {
    String token = '',
    bool markAsLargeRoom = false,
  }) async {
    final joinRoomResult = await ZegoUIKitCore.shared.joinRoom(
      roomID,
      markAsLargeRoom: markAsLargeRoom,
    );

    if (ZegoErrorCode.CommonSuccess != joinRoomResult.errorCode) {
      ZegoUIKitCore.shared.error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.roomLoginError,
        message: 'login room error:${joinRoomResult.errorCode}, '
            'room id:$roomID, large room:$markAsLargeRoom, '
            '${ZegoUIKitErrorCode.expressErrorCodeDocumentTips}',
        method: 'joinRoom',
      ));
    }

    return joinRoomResult;
  }

  /// leave room
  Future<ZegoRoomLogoutResult> leaveRoom() async {
    final leaveRoomResult = await ZegoUIKitCore.shared.leaveRoom();

    if (ZegoErrorCode.CommonSuccess != leaveRoomResult.errorCode) {
      ZegoUIKitCore.shared.error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.roomLeaveError,
        message: 'leave room error:${leaveRoomResult.errorCode}, '
            '${ZegoUIKitErrorCode.expressErrorCodeDocumentTips}',
        method: 'leaveRoom',
      ));
    }

    return leaveRoomResult;
  }

  /// get room object
  ZegoUIKitRoom getRoom() {
    return ZegoUIKitCore.shared.coreData.room.toUIKitRoom();
  }

  /// get room state notifier
  ValueNotifier<ZegoUIKitRoomState> getRoomStateStream() {
    return ZegoUIKitCore.shared.coreData.room.state;
  }

  /// update one room property
  Future<bool> setRoomProperty(String key, String value) async {
    return ZegoUIKitCore.shared.setRoomProperty(key, value);
  }

  /// update room properties
  Future<bool> updateRoomProperties(Map<String, String> properties) async {
    return ZegoUIKitCore.shared
        .updateRoomProperties(Map<String, String>.from(properties));
  }

  /// get room properties
  Map<String, RoomProperty> getRoomProperties() {
    return Map<String, RoomProperty>.from(
        ZegoUIKitCore.shared.coreData.room.properties);
  }

  /// only notify the property which changed
  /// you can get full properties by getRoomProperties() function
  Stream<RoomProperty> getRoomPropertyStream() {
    return ZegoUIKitCore.shared.coreData.room.propertyUpdateStream?.stream ??
        const Stream.empty();
  }

  /// only notify the properties which changed
  /// you can get full properties by getRoomProperties() function
  Stream<Map<String, RoomProperty>> getRoomPropertiesStream() {
    return ZegoUIKitCore.shared.coreData.room.propertiesUpdatedStream?.stream ??
        const Stream.empty();
  }

  /// get network state notifier
  Stream<ZegoNetworkMode> getNetworkModeStream() {
    return ZegoUIKitCore.shared.coreData.networkModeStreamCtrl?.stream ??
        const Stream.empty();
  }
}
