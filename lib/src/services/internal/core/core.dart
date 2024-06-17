// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:file_picker/file_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

// Project imports:
import 'package:zego_uikit/src/services/internal/core/data/media.dart';
import 'package:zego_uikit/src/services/internal/core/data/message.dart';
import 'package:zego_uikit/src/services/internal/core/data/network_timestamp.dart';
import 'package:zego_uikit/src/services/internal/core/data/screen_sharing.dart';
import 'package:zego_uikit/src/services/internal/core/data/stream.dart';
import 'package:zego_uikit/src/services/internal/core/data/user.dart';
import 'package:zego_uikit/src/services/internal/core/event/event.dart';
import 'package:zego_uikit/src/services/internal/core/event_handler.dart';
import 'package:zego_uikit/src/services/services.dart';

part 'data/data.dart';

part 'defines.dart';

part 'media.dart';

part 'error.dart';

part 'message.dart';

/// @nodoc
class ZegoUIKitCore
    with
        ZegoUIKitCoreMessage,
        ZegoUIKitCoreEventHandler,
        ZegoUIKitCoreDataError {
  ZegoUIKitCore._internal();

  static final ZegoUIKitCore shared = ZegoUIKitCore._internal();

  final ZegoUIKitCoreData coreData = ZegoUIKitCoreData();
  var event = ZegoUIKitEvent();

  bool isInit = false;
  bool isNeedDisableWakelock = false;
  final expressEngineCreatedNotifier = ValueNotifier<bool>(false);
  List<StreamSubscription<dynamic>?> subscriptions = [];

  Future<String> getZegoUIKitVersion() async {
    final expressVersion = await ZegoExpressEngine.getVersion();
    const zegoUIKitVersion = 'zego_uikit: 2.22.2; ';
    return '${zegoUIKitVersion}zego_express:$expressVersion';
  }

  Future<void> init({
    required int appID,
    String appSign = '',
    bool? enablePlatformView,
    ZegoScenario scenario = ZegoScenario.Default,
  }) async {
    if (isInit) {
      ZegoLoggerService.logWarn(
        'core had init',
        tag: 'uikit',
        subTag: 'core',
      );
      return;
    }

    isInit = true;

    ZegoLoggerService.logInfo(
      'init, '
      'appID:$appID, '
      'enablePlatformView:$enablePlatformView, '
      'scenario:$scenario, ',
      tag: 'uikit',
      subTag: 'core',
    );

    coreData.init();
    event.init();
    error.init();
    initEventHandle();

    ZegoExpressEngine.setEngineConfig(ZegoEngineConfig(advancedConfig: {
      'vcap_external_mem_class': '1',
    }));

    ZegoLoggerService.logInfo(
      'create engine with profile',
      tag: 'uikit',
      subTag: 'core',
    );
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(
        appID,
        scenario,
        appSign: appSign,
        enablePlatformView: enablePlatformView,
      ),
    ).then((value) {
      ZegoLoggerService.logInfo(
        'engine created',
        tag: 'uikit',
        subTag: 'core',
      );
    });
    expressEngineCreatedNotifier.value = true;

    ZegoExpressEngine.setEngineConfig(ZegoEngineConfig(advancedConfig: {
      'notify_remote_device_unknown_status': 'true',
      'notify_remote_device_init_status': 'true',
      'keep_audio_session_active': 'true',
    }));

    ZegoLoggerService.logInfo(
      'get network time info',
      tag: 'uikit',
      subTag: 'core',
    );
    await ZegoExpressEngine.instance.getNetworkTimeInfo().then((timeInfo) {
      coreData.initNetworkTimestamp(timeInfo.timestamp);

      ZegoLoggerService.logInfo(
        'network time info is init, timestamp:${timeInfo.timestamp}, max deviation:${timeInfo.maxDeviation}',
        tag: 'uikit',
        subTag: 'core',
      );
    });

    final initAudioRoute = await ZegoExpressEngine.instance.getAudioRouteType();
    coreData.localUser.audioRoute.value =
        ZegoUIKitAudioRouteExtension.fromSDKValue(initAudioRoute);
    coreData.localUser.lastAudioRoute =
        ZegoUIKitAudioRouteExtension.fromSDKValue(initAudioRoute);

    subscriptions.add(
      coreData.customCommandReceivedStreamCtrl?.stream.listen(
        onInternalCustomCommandReceived,
      ),
    );
  }

  Future<void> uninit() async {
    if (!isInit) {
      ZegoLoggerService.logWarn(
        'core is not init',
        tag: 'uikit',
        subTag: 'core',
      );
      return;
    }

    isInit = false;

    ZegoLoggerService.logInfo(
      'uninit',
      tag: 'uikit',
      subTag: 'core',
    );

    coreData.uninit();
    event.uninit();
    error.uninit();
    uninitEventHandle();

    clear();

    for (final subscription in subscriptions) {
      subscription?.cancel();
    }

    expressEngineCreatedNotifier.value = false;
    await ZegoExpressEngine.destroyEngine();
  }

  Future<void> setAdvanceConfigs(Map<String, String> configs) async {
    ZegoLoggerService.logInfo(
      'set advance configs:$configs',
      tag: 'uikit',
      subTag: 'core',
    );

    await ZegoExpressEngine.setEngineConfig(
      ZegoEngineConfig(advancedConfig: configs),
    );
  }

  void clear() {
    coreData.clear();
    message.clear();
  }

  void initEventHandle() {
    ZegoLoggerService.logInfo(
      'init event handle',
      tag: 'uikit',
      subTag: 'core',
    );

    event.express.register(eventHandler);
    event.express.register(error);
    event.express.register(message);

    event.media.register(coreData.media);
  }

  void uninitEventHandle() {
    ZegoLoggerService.logInfo(
      'uninit event handle',
      tag: 'uikit',
      subTag: 'core',
    );

    event.express.unregister(eventHandler);
    event.express.unregister(error);
    event.express.unregister(message);

    event.media.unregister(coreData.media);
  }

  ValueNotifier<DateTime?> getNetworkTime() {
    return coreData.networkDateTime;
  }

  void login(String id, String name) {
    coreData.login(id, name);
  }

  void logout() {
    coreData.logout();
  }

  Future<ZegoRoomLoginResult> joinRoom(
    String roomID, {
    bool markAsLargeRoom = false,
  }) async {
    ZegoLoggerService.logInfo(
      'join room, room id:"$roomID", markAsLargeRoom:$markAsLargeRoom',
      tag: 'uikit',
      subTag: 'core',
    );

    if (coreData.room.id == roomID) {
      return ZegoRoomLoginResult(0, {});
    }

    clear();
    coreData.setRoom(roomID, markAsLargeRoom: markAsLargeRoom);

    event.init();

    final originWakelockEnabledF = WakelockPlus.enabled;

    final joinRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      coreData.localUser.toZegoUser(),
      config: ZegoRoomConfig(0, true, ''),
    );
    ZegoLoggerService.logInfo(
      'join room result: ${joinRoomResult.errorCode} ${joinRoomResult.extendedData}',
      tag: 'uikit',
      subTag: 'core',
    );

    if (ZegoErrorCode.CommonSuccess == joinRoomResult.errorCode) {
      await coreData.startPublishOrNot();
      await syncDeviceStatusByStreamExtraInfo();

      final originWakelockEnabled = await originWakelockEnabledF;
      if (originWakelockEnabled) {
        isNeedDisableWakelock = false;
      } else {
        isNeedDisableWakelock = true;
        WakelockPlus.enable();
      }

      await ZegoExpressEngine.instance.startSoundLevelMonitor();
    } else if (joinRoomResult.errorCode == ZegoErrorCode.RoomCountExceed) {
      ZegoLoggerService.logInfo(
        'room count exceed',
        tag: 'uikit',
        subTag: 'core',
      );

      await leaveRoom();
      return joinRoom(roomID);
    } else {
      ZegoLoggerService.logInfo(
        'joinRoom failed: ${joinRoomResult.errorCode}, ${joinRoomResult.extendedData}',
        tag: 'uikit',
        subTag: 'core',
      );
    }

    return joinRoomResult;
  }

  Future<ZegoRoomLogoutResult> leaveRoom() async {
    ZegoLoggerService.logInfo(
      'leave room',
      tag: 'uikit',
      subTag: 'core',
    );

    if (isNeedDisableWakelock) {
      WakelockPlus.disable();
    }

    clear();

    await ZegoExpressEngine.instance.stopSoundLevelMonitor();

    final leaveResult = await ZegoExpressEngine.instance.logoutRoom();
    if (ZegoErrorCode.CommonSuccess != leaveResult.errorCode) {
      ZegoLoggerService.logError(
        'leaveRoom failed: ${leaveResult.errorCode}, ${leaveResult.extendedData}',
        tag: 'uikit',
        subTag: 'core',
      );
    }

    event.uninit();

    return leaveResult;
  }

  Future<int> removeUserFromRoom(List<String> userIDs) async {
    ZegoLoggerService.logInfo(
      'remove users from room:$userIDs',
      tag: 'uikit',
      subTag: 'core',
    );

    if (coreData.room.isLargeRoom || coreData.room.markAsLargeRoom) {
      ZegoLoggerService.logInfo(
        'remove all users, because is a large room',
        tag: 'uikit',
        subTag: 'core',
      );
      return sendInRoomCommand(
        const JsonEncoder().convert({removeUserInRoomCommandKey: userIDs}),
        [],
      );
    } else {
      return sendInRoomCommand(
        const JsonEncoder().convert({removeUserInRoomCommandKey: userIDs}),
        userIDs,
      );
    }
  }

  Future<bool> setRoomProperty(String key, String value) async {
    return updateRoomProperties({key: value});
  }

  Future<bool> updateRoomProperties(Map<String, String> properties) async {
    ZegoLoggerService.logInfo(
      'set room property: $properties',
      tag: 'uikit',
      subTag: 'core',
    );

    if (!isInit) {
      ZegoLoggerService.logError(
        'core had not init',
        tag: 'uikit',
        subTag: 'core',
      );

      error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.coreNotInit,
        message: 'core not init',
        method: 'updateRoomProperties',
      ));

      return false;
    }

    if (coreData.room.id.isEmpty) {
      ZegoLoggerService.logError(
        'room is not login',
        tag: 'uikit',
        subTag: 'core',
      );

      error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.roomNotLogin,
        message: 'room not login',
        method: 'updateRoomProperties',
      ));

      return false;
    }

    if (coreData.room.propertiesAPIRequesting) {
      properties.forEach((key, value) {
        coreData.room.pendingProperties[key] = value;
      });
      ZegoLoggerService.logInfo(
        'room property is updating, pending: ${coreData.room.pendingProperties}',
        tag: 'uikit',
        subTag: 'core',
      );
      return false;
    }

    final localUser = ZegoUIKit().getLocalUser();

    var isAllPropertiesSame = coreData.room.properties.isNotEmpty;
    properties.forEach((key, value) {
      if (coreData.room.properties.containsKey(key) &&
          coreData.room.properties[key]!.value == value) {
        ZegoLoggerService.logInfo(
          'key exist and value is same, ${coreData.room.properties}',
          tag: 'uikit',
          subTag: 'core',
        );
        isAllPropertiesSame = false;
      }
    });
    if (isAllPropertiesSame) {
      ZegoLoggerService.logInfo(
        'all key exist and value is same',
        tag: 'uikit',
        subTag: 'core',
      );
      // return true;
    }

    final oldProperties = <String, RoomProperty?>{};
    properties
      ..forEach((key, value) {
        if (coreData.room.properties.containsKey(key)) {
          oldProperties[key] =
              RoomProperty.copyFrom(coreData.room.properties[key]!);
          oldProperties[key]!.updateUserID = localUser.id;
        }
      })

      /// local update
      ..forEach((key, value) {
        if (coreData.room.properties.containsKey(key)) {
          coreData.room.properties[key]!.oldValue =
              coreData.room.properties[key]!.value;
          coreData.room.properties[key]!.value = value;
          coreData.room.properties[key]!.updateTime =
              coreData.networkDateTime_.millisecondsSinceEpoch;
          coreData.room.properties[key]!.updateFromRemote = false;
        } else {
          coreData.room.properties[key] = RoomProperty(
            key,
            value,
            coreData.networkDateTime_.millisecondsSinceEpoch,
            localUser.id,
            false,
          );
        }
      });

    /// server update
    final extraInfoMap = <String, String>{};
    coreData.room.properties.forEach((key, value) {
      extraInfoMap[key] = value.value;
    });
    final extraInfo = const JsonEncoder().convert(extraInfoMap);
    // if (extraInfo.length > 128) {
    //   ZegoLoggerService.logInfo("value length out of limit");
    //   return false;
    // }
    ZegoLoggerService.logInfo(
      'call set room extra info, $extraInfo',
      tag: 'uikit',
      subTag: 'core',
    );

    ZegoLoggerService.logInfo(
      'call setRoomExtraInfo',
      tag: 'uikit',
      subTag: 'core',
    );
    coreData.room.propertiesAPIRequesting = true;
    return ZegoExpressEngine.instance
        .setRoomExtraInfo(coreData.room.id, 'extra_info', extraInfo)
        .then((ZegoRoomSetRoomExtraInfoResult result) {
      ZegoLoggerService.logInfo(
        'setRoomExtraInfo finished',
        tag: 'uikit',
        subTag: 'core',
      );
      if (ZegoErrorCode.CommonSuccess == result.errorCode) {
        properties.forEach((key, value) {
          if (!coreData.room.properties.containsKey(key)) {
            return;
          }

          /// exception
          final updatedProperty = coreData.room.properties[key]!
            ..updateFromRemote = true;
          coreData.room.propertyUpdateStream?.add(updatedProperty);
          coreData.room.propertiesUpdatedStream?.add({key: updatedProperty});
        });
      } else {
        properties.forEach((key, value) {
          if (coreData.room.properties.containsKey(key)) {
            coreData.room.properties[key]!.copyFrom(oldProperties[key]!);
          }
        });
        ZegoLoggerService.logError(
          'fail to set room properties:$properties! error code:${result.errorCode}',
          tag: 'uikit',
          subTag: 'core',
        );
      }

      coreData.room.propertiesAPIRequesting = false;
      if (coreData.room.pendingProperties.isNotEmpty) {
        final pendingProperties =
            Map<String, String>.from(coreData.room.pendingProperties);
        coreData.room.pendingProperties.clear();
        ZegoLoggerService.logInfo(
          'update pending properties:$pendingProperties',
          tag: 'uikit',
          subTag: 'core',
        );
        updateRoomProperties(pendingProperties);
      }

      return ZegoErrorCode.CommonSuccess != result.errorCode;
    });
  }

  Future<int> sendInRoomCommand(
    String command,
    List<String> toUserIDs,
  ) async {
    ZegoLoggerService.logInfo(
      'send in-room command:$command to $toUserIDs',
      tag: 'uikit',
      subTag: 'core',
    );

    return ZegoExpressEngine.instance
        .sendCustomCommand(
      coreData.room.id,
      command,
      toUserIDs.isEmpty
          // empty mean send to all users
          ? coreData.remoteUsersList
              .map((ZegoUIKitCoreUser user) => ZegoUser(user.id, user.name))
              .toList()
          : toUserIDs
              .map((String userID) => coreData.remoteUsersList
                  .firstWhere((element) => element.id == userID,
                      orElse: ZegoUIKitCoreUser.empty)
                  .toZegoUser())
              .toList(),
    )
        .then(
      (ZegoIMSendCustomCommandResult result) {
        ZegoLoggerService.logInfo(
          'send custom command result, code:${result.errorCode}',
          tag: 'uikit',
          subTag: 'core',
        );

        return result.errorCode;
      },
    );
  }

  void useFrontFacingCamera(bool isFrontFacing) {
    if (isFrontFacing == coreData.localUser.isFrontFacing.value) {
      return;
    }

    ZegoExpressEngine.instance.useFrontCamera(isFrontFacing);
    coreData.localUser.isFrontFacing.value = isFrontFacing;

    ZegoExpressEngine.instance.setVideoMirrorMode(
      isFrontFacing
          ? (coreData.localUser.isVideoMirror.value
              ? ZegoVideoMirrorMode.BothMirror
              : ZegoVideoMirrorMode.NoMirror)
          : ZegoVideoMirrorMode.NoMirror,
    );
  }

  void enableVideoMirroring(bool isVideoMirror) {
    coreData.localUser.isVideoMirror.value = isVideoMirror;

    ZegoExpressEngine.instance.setVideoMirrorMode(
      isVideoMirror
          ? ZegoVideoMirrorMode.BothMirror
          : ZegoVideoMirrorMode.NoMirror,
    );
  }

  void setAudioVideoResourceMode(ZegoAudioVideoResourceMode mode) {
    coreData.playResourceMode = mode;

    ZegoLoggerService.logInfo(
      'set audio video resource mode: $mode',
      tag: 'uikit',
      subTag: 'core',
    );
  }

  Future<void> startPlayAllAudioVideo() async {
    coreData.muteAllPlayStreamAudioVideo(false);
  }

  Future<void> stopPlayAllAudioVideo() async {
    coreData.muteAllPlayStreamAudioVideo(true);
  }

  Future<bool> muteUserAudioVideo(String userID, bool mute) async {
    return coreData.muteUserAudioVideo(
      userID,
      mute,
      forAudio: true,
      forVideo: true,
    );
  }

  Future<bool> muteUserAudio(String userID, bool mute) async {
    return coreData.muteUserAudioVideo(
      userID,
      mute,
      forAudio: true,
      forVideo: false,
    );
  }

  Future<bool> muteUserVideo(String userID, bool mute) async {
    return coreData.muteUserAudioVideo(
      userID,
      mute,
      forAudio: false,
      forVideo: true,
    );
  }

  void setAudioOutputToSpeaker(bool useSpeaker) {
    if (!isInit) {
      ZegoLoggerService.logError(
        'set audio output to speaker, core had not init',
        tag: 'uikit',
        subTag: 'core',
      );

      error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.coreNotInit,
        message: 'core not init',
        method: 'setAudioOutputToSpeaker',
      ));

      return;
    }

    if (useSpeaker ==
        (coreData.localUser.audioRoute.value == ZegoUIKitAudioRoute.speaker)) {
      return;
    }

    ZegoExpressEngine.instance.setAudioRouteToSpeaker(useSpeaker);

    // TODO: use sdk callback to update audioRoute
    if (useSpeaker) {
      coreData.localUser.lastAudioRoute = coreData.localUser.audioRoute.value;
      coreData.localUser.audioRoute.value = ZegoUIKitAudioRoute.speaker;
    } else {
      coreData.localUser.audioRoute.value = coreData.localUser.lastAudioRoute;
    }
  }

  Future<bool> turnCameraOn(String userID, bool isOn) async {
    ZegoLoggerService.logInfo(
      "turn ${isOn ? "on" : "off"} $userID camera",
      tag: 'uikit',
      subTag: 'core',
    );

    if (coreData.localUser.id == userID) {
      return turnOnLocalCamera(isOn);
    } else {
      final isLargeRoom =
          coreData.room.isLargeRoom || coreData.room.markAsLargeRoom;
      ZegoLoggerService.logInfo(
        'is large room:$isLargeRoom',
        tag: 'uikit',
        subTag: 'core',
      );

      if (isOn) {
        return ZegoUIKitErrorCode.success ==
            await sendInRoomCommand(
              const JsonEncoder()
                  .convert({turnCameraOnInRoomCommandKey: userID}),
              isLargeRoom ? [] : [userID],
            );
      } else {
        return ZegoUIKitErrorCode.success ==
            await sendInRoomCommand(
              const JsonEncoder()
                  .convert({turnCameraOffInRoomCommandKey: userID}),
              isLargeRoom ? [] : [userID],
            );
      }
    }
  }

  Future<bool> turnOnLocalCamera(bool isOn) async {
    ZegoLoggerService.logInfo(
      "turn ${isOn ? "on" : "off"} local camera",
      tag: 'uikit',
      subTag: 'core',
    );

    if (!isInit) {
      ZegoLoggerService.logError(
        'turn on local camera, core had not init',
        tag: 'uikit',
        subTag: 'core',
      );

      error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.coreNotInit,
        message: 'core not init',
        method: 'turnOnLocalCamera',
      ));

      return false;
    }

    if (isOn == coreData.localUser.camera.value) {
      ZegoLoggerService.logInfo(
        'turn on local camera, value is equal',
        tag: 'uikit',
        subTag: 'core',
      );

      return true;
    }

    if (isOn) {
      await coreData.startPreview();
    } else {
      await coreData.stopPreview();
    }

    await ZegoExpressEngine.instance.enableCamera(isOn);

    coreData.localUser.cameraMuteMode.value = false;
    coreData.localUser.camera.value = isOn;

    await coreData.startPublishOrNot();

    await syncDeviceStatusByStreamExtraInfo();

    return true;
  }

  void turnMicrophoneOn(String userID, bool isOn, {bool muteMode = false}) {
    ZegoLoggerService.logInfo(
      "turn ${isOn ? "on" : "off"} $userID microphone, muteMode:$muteMode",
      tag: 'uikit',
      subTag: 'core',
    );

    if (coreData.localUser.id == userID) {
      turnOnLocalMicrophone(isOn, muteMode: muteMode);
    } else {
      final isLargeRoom =
          coreData.room.isLargeRoom || coreData.room.markAsLargeRoom;
      ZegoLoggerService.logInfo(
        'is large room:$isLargeRoom',
        tag: 'uikit',
        subTag: 'core',
      );

      if (isOn) {
        sendInRoomCommand(
          const JsonEncoder().convert(
            {
              turnMicrophoneOnInRoomCommandKey: {
                userIDCommandKey: userID,
                muteModeCommandKey: muteMode,
              },
            },
          ),
          isLargeRoom ? [userID] : [],
        );
      } else {
        sendInRoomCommand(
          const JsonEncoder().convert(
            {
              turnMicrophoneOffInRoomCommandKey: {
                userIDCommandKey: userID,
                muteModeCommandKey: muteMode,
              },
            },
          ),
          isLargeRoom ? [userID] : [],
        );
      }
    }
  }

  Future<void> turnOnLocalMicrophone(bool isOn, {bool muteMode = false}) async {
    ZegoLoggerService.logInfo(
      "turn ${isOn ? "on" : "off"} local microphone${muteMode ? ', muteMode:$muteMode' : ''}",
      tag: 'uikit',
      subTag: 'core',
    );

    if (!isInit) {
      ZegoLoggerService.logError(
        'turn ${isOn ? "on" : "off"} local microphone, core had not init',
        tag: 'uikit',
        subTag: 'core',
      );

      error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.coreNotInit,
        message: 'core not init',
        method: 'turnOnLocalMicrophone',
      ));

      return;
    }

    if ((isOn == coreData.localUser.microphone.value) &&
        (muteMode == coreData.localUser.microphoneMuteMode.value)) {
      ZegoLoggerService.logInfo(
        'turn ${isOn ? "on" : "off"} local microphone, value is equal isOn:$isOn, muteMode:$muteMode',
        tag: 'uikit',
        subTag: 'core',
      );
      return;
    }

    if (isOn) {
      await ZegoExpressEngine.instance.muteMicrophone(false);
      await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
      coreData.localUser.microphoneMuteMode.value = false;
    } else {
      if (muteMode) {
        await ZegoExpressEngine.instance.muteMicrophone(false);
        await ZegoExpressEngine.instance.mutePublishStreamAudio(true);
        coreData.localUser.microphoneMuteMode.value = true;

        /// local sound level should be mute too
        coreData.localUser.mainChannel.soundLevel?.add(0.0);
      } else {
        await ZegoExpressEngine.instance.muteMicrophone(true);
        await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
        coreData.localUser.microphoneMuteMode.value = false;
      }
    }

    coreData.localUser.microphone.value = isOn;
    await coreData.startPublishOrNot();

    await syncDeviceStatusByStreamExtraInfo();
  }

  Future<void> syncDeviceStatusByStreamExtraInfo() async {
    // sync device status via stream extra info
    final streamExtraInfo = <String, dynamic>{
      streamExtraInfoCameraKey: coreData.localUser.camera.value,
      streamExtraInfoMicrophoneKey: coreData.localUser.microphone.value
    };

    final extraInfo = jsonEncode(streamExtraInfo);
    await ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    await syncDeviceStatusBySEI();
  }

  Future<void> syncDeviceStatusBySEI() async {
    final seiMap = <String, dynamic>{
      ZegoUIKitSEIDefines.keyCamera: coreData.localUser.camera.value,
      ZegoUIKitSEIDefines.keyMicrophone: coreData.localUser.microphone.value,
    };
    await coreData.sendSEI(
      ZegoUIKitInnerSEIType.mixerDeviceState.name,
      seiMap,
      streamType: ZegoStreamType.main,
    );
  }

  void updateTextureRendererOrientation(Orientation orientation) {
    switch (orientation) {
      case Orientation.portrait:
        ZegoExpressEngine.instance
            .setAppOrientation(DeviceOrientation.portraitUp);
        break;
      case Orientation.landscape:
        ZegoExpressEngine.instance
            .setAppOrientation(DeviceOrientation.landscapeLeft);
        break;
    }
  }

  Future<void> setVideoConfig(
    ZegoUIKitVideoConfig config,
    ZegoStreamType streamType,
  ) async {
    ZegoLoggerService.logError(
      'set video config:$config',
      tag: 'uikit',
      subTag: 'core',
    );

    await ZegoExpressEngine.instance.setVideoConfig(
      config.toSDK,
      channel: streamType.channel,
    );
    coreData.localUser.mainChannel.viewSize.value = Size(
      config.width.toDouble(),
      config.height.toDouble(),
    );
  }

  Future<void> enableTrafficControl(
    bool enabled,
    List<ZegoUIKitTrafficControlProperty> properties, {
    ZegoUIKitVideoConfig? minimizeVideoConfig,
    bool isFocusOnRemote = true,
    ZegoStreamType streamType = ZegoStreamType.main,
  }) async {
    int propertyBitMask = 0;
    for (var property in properties) {
      propertyBitMask |= property.value;
    }

    minimizeVideoConfig ??= ZegoUIKitVideoConfig.preset360P();

    ZegoLoggerService.logInfo(
      'enable traffic control, '
      'properties:$properties, '
      'minimizeVideoConfig:$minimizeVideoConfig, '
      'isFocusOnRemote:$isFocusOnRemote, '
      'bitmask:$propertyBitMask',
      tag: 'uikit',
      subTag: 'core',
    );

    await ZegoExpressEngine.instance.setMinVideoBitrateForTrafficControl(
      minimizeVideoConfig.bitrate,
      ZegoTrafficControlMinVideoBitrateMode.UltraLowFPS,
    );
    await ZegoExpressEngine.instance.setMinVideoResolutionForTrafficControl(
      minimizeVideoConfig.width,
      minimizeVideoConfig.height,
    );
    await ZegoExpressEngine.instance.setMinVideoFpsForTrafficControl(
      minimizeVideoConfig.fps,
    );
    await ZegoExpressEngine.instance.setTrafficControlFocusOn(
      isFocusOnRemote
          ? ZegoTrafficControlFocusOnMode.ZegoTrafficControlFounsOnRemote
          : ZegoTrafficControlFocusOnMode.ZegoTrafficControlFounsOnLocalOnly,
    );

    await ZegoExpressEngine.instance.enableTrafficControl(
      enabled,
      propertyBitMask,
      channel: streamType.channel,
    );
  }

  void setInternalVideoConfig(ZegoUIKitVideoInternalConfig config) {
    if (coreData.pushVideoConfig.needUpdateVideoConfig(config)) {
      final zegoVideoConfig = config.toZegoVideoConfig();
      ZegoExpressEngine.instance.setVideoConfig(
        zegoVideoConfig,
        channel: ZegoPublishChannel.Main,
      );
      coreData.localUser.mainChannel.viewSize.value = Size(
        zegoVideoConfig.captureWidth.toDouble(),
        zegoVideoConfig.captureHeight.toDouble(),
      );
    }
    if (coreData.pushVideoConfig.needUpdateOrientation(config)) {
      ZegoExpressEngine.instance.setAppOrientation(
        config.orientation,
        channel: ZegoPublishChannel.Main,
      );
    }

    coreData.pushVideoConfig = config;
  }

  void updateAppOrientation(DeviceOrientation orientation) {
    if (coreData.pushVideoConfig.orientation == orientation) {
      ZegoLoggerService.logInfo(
        'app orientation is equal',
        tag: 'uikit',
        subTag: 'core',
      );
      return;
    } else {
      ZegoLoggerService.logInfo(
        'update app orientation:$orientation',
        tag: 'uikit',
        subTag: 'core',
      );

      setInternalVideoConfig(
        coreData.pushVideoConfig.copyWith(orientation: orientation),
      );
    }
  }

  void setVideoConfigByPreset(ZegoPresetResolution resolution) {
    if (coreData.pushVideoConfig.resolution == resolution) {
      ZegoLoggerService.logInfo(
        'video config preset is equal',
        tag: 'uikit',
        subTag: 'core',
      );
      return;
    } else {
      ZegoLoggerService.logInfo(
        'update video config preset:$resolution',
        tag: 'uikit',
        subTag: 'core',
      );

      setInternalVideoConfig(
        coreData.pushVideoConfig.copyWith(resolution: resolution),
      );
    }
  }

  void updateVideoViewMode(bool useVideoViewAspectFill) {
    if (coreData.pushVideoConfig.useVideoViewAspectFill ==
        useVideoViewAspectFill) {
      ZegoLoggerService.logInfo(
        'video view mode is equal',
        tag: 'uikit',
        subTag: 'core',
      );
      return;
    } else {
      coreData.pushVideoConfig.useVideoViewAspectFill = useVideoViewAspectFill;
      // TODO: need re preview, and re playStream
    }
  }

  void onInternalCustomCommandReceived(
      ZegoInRoomCommandReceivedData commandData) {
    dynamic commandJson;
    try {
      commandJson = jsonDecode(commandData.command);
    } catch (e) {
      ZegoLoggerService.logInfo(
        'custom command is not a json, $e',
        tag: 'uikit',
        subTag: 'core',
      );
    }

    if (commandJson is! Map<String, dynamic>) {
      ZegoLoggerService.logInfo(
        'custom command is not a map',
        tag: 'uikit',
        subTag: 'core',
      );
      return;
    }

    ZegoLoggerService.logInfo(
      'on map custom command received, from user:${commandData.fromUser}, command:${commandData.command}',
      tag: 'uikit',
      subTag: 'core',
    );

    final extraInfos = Map.from(commandJson);
    if (extraInfos.keys.contains(removeUserInRoomCommandKey)) {
      var selfKickedOut = false;
      final commandValue = extraInfos[removeUserInRoomCommandKey];
      if (commandValue is String) {
        /// compatible with web protocols
        final kickUserID = commandValue;
        selfKickedOut = kickUserID == coreData.localUser.id;
      } else if (commandValue is List<dynamic>) {
        final kickUserIDs = commandValue;
        selfKickedOut = kickUserIDs.contains(coreData.localUser.id);
      }

      if (selfKickedOut) {
        ZegoLoggerService.logInfo(
          'local user had been remove by ${commandData.fromUser.id}, auto leave room',
          tag: 'uikit',
          subTag: 'core',
        );
        leaveRoom();

        coreData.meRemovedFromRoomStreamCtrl?.add(commandData.fromUser.id);
      }
    } else if (extraInfos.keys.contains(turnCameraOnInRoomCommandKey) &&
        extraInfos[turnCameraOnInRoomCommandKey]!.toString() ==
            coreData.localUser.id) {
      ZegoLoggerService.logInfo(
        'local camera request turn on by ${commandData.fromUser}',
        tag: 'uikit',
        subTag: 'core',
      );
      coreData.turnOnYourCameraRequestStreamCtrl?.add(commandData.fromUser.id);
    } else if (extraInfos.keys.contains(turnCameraOffInRoomCommandKey) &&
        extraInfos[turnCameraOffInRoomCommandKey]!.toString() ==
            coreData.localUser.id) {
      ZegoLoggerService.logInfo(
        'local camera request turn off by ${commandData.fromUser}',
        tag: 'uikit',
        subTag: 'core',
      );
      turnCameraOn(coreData.localUser.id, false);
    } else if (extraInfos.keys.contains(turnMicrophoneOnInRoomCommandKey)) {
      final mapData =
          extraInfos[turnMicrophoneOnInRoomCommandKey] as Map<String, dynamic>;
      final userID = mapData[userIDCommandKey] ?? '';
      final muteMode = mapData[muteModeCommandKey] as bool? ?? false;

      if (userID == coreData.localUser.id) {
        ZegoLoggerService.logInfo(
          'local microphone request turn on by ${commandData.fromUser}',
          tag: 'uikit',
          subTag: 'core',
        );

        coreData.turnOnYourMicrophoneRequestStreamCtrl
            ?.add(ZegoUIKitReceiveTurnOnLocalMicrophoneEvent(
          commandData.fromUser.id,
          muteMode,
        ));
      }
    } else if (extraInfos.keys.contains(turnMicrophoneOffInRoomCommandKey)) {
      var userID = '';
      var muteMode = false;
      final commandValue = extraInfos[turnMicrophoneOffInRoomCommandKey];
      if (commandValue is String) {
        /// compatible with web protocols
        userID = commandValue;
      } else if (commandValue is Map<String, dynamic>) {
        /// support mute mode paramater
        final mapData = commandValue;
        userID = mapData[userIDCommandKey] ?? '';
        muteMode = mapData[muteModeCommandKey] as bool? ?? false;
      }

      if (userID == coreData.localUser.id) {
        ZegoLoggerService.logInfo(
          'local microphone request turn off by ${commandData.fromUser}',
          tag: 'uikit',
          subTag: 'core',
        );
        turnMicrophoneOn(coreData.localUser.id, false, muteMode: muteMode);
      }
    }
  }

  void enableCustomVideoProcessing(bool enable) {
    var type = ZegoVideoBufferType.CVPixelBuffer;
    if (Platform.isAndroid) {
      type = ZegoVideoBufferType.GLTexture2D;
    }
    ZegoLoggerService.logInfo(
      '${enable ? "enable" : "disable"} custom video processing, buffer type:$type',
      tag: 'uikit',
      subTag: 'core',
    );

    ZegoExpressEngine.instance.enableCustomVideoProcessing(
        enable, ZegoCustomVideoProcessConfig(type));
  }
}

/// @nodoc
extension ZegoUIKitCoreBaseBeauty on ZegoUIKitCore {
  Future<void> enableBeauty(bool isOn) async {
    ZegoLoggerService.logInfo(
      '${isOn ? "enable" : "disable"} beauty',
      tag: 'uikit',
      subTag: 'core',
    );

    ZegoExpressEngine.instance.enableEffectsBeauty(isOn);
  }

  Future<void> startEffectsEnv() async {
    ZegoLoggerService.logInfo(
      'start effects env',
      tag: 'uikit',
      subTag: 'core',
    );

    await ZegoExpressEngine.instance.startEffectsEnv();
  }

  Future<void> stopEffectsEnv() async {
    ZegoLoggerService.logInfo(
      'stop effects env',
      tag: 'uikit',
      subTag: 'core',
    );

    await ZegoExpressEngine.instance.stopEffectsEnv();
  }
}

/// @nodoc
extension ZegoUIKitCoreMixer on ZegoUIKitCore {
  Future<ZegoMixerStartResult> startMixerTask(ZegoMixerTask task) async {
    final startMixerResult =
        await ZegoExpressEngine.instance.startMixerTask(task);
    ZegoLoggerService.logInfo(
      'startMixerTask, code:${startMixerResult.errorCode},extendedData:${startMixerResult.extendedData}',
      tag: 'uikit',
      subTag: 'core',
    );

    if (ZegoErrorCode.CommonSuccess == startMixerResult.errorCode) {
      if (coreData.mixerSEITimer?.isActive ?? false) {
        coreData.mixerSEITimer?.cancel();
      }
      coreData.mixerSEITimer =
          Timer.periodic(const Duration(milliseconds: 300), (timer) {
        ZegoUIKitCore.shared.syncDeviceStatusBySEI();
      });
    }

    return startMixerResult;
  }

  Future<ZegoMixerStopResult> stopMixerTask(ZegoMixerTask task) async {
    final stopMixerResult =
        await ZegoExpressEngine.instance.stopMixerTask(task);
    ZegoLoggerService.logInfo(
      'stopMixerTask, code:${stopMixerResult.errorCode}',
      tag: 'uikit',
      subTag: 'core',
    );

    if (coreData.mixerSEITimer?.isActive ?? false) {
      coreData.mixerSEITimer?.cancel();
    }

    return stopMixerResult;
  }

  Future<void> startPlayMixAudioVideo(
    String mixerID,
    List<ZegoUIKitCoreUser> users,
    Map<String, int> userSoundIDs,
  ) {
    return coreData.startPlayMixAudioVideo(mixerID, users, userSoundIDs);
  }

  Future<void> stopPlayMixAudioVideo(String mixerID) {
    return coreData.stopPlayMixAudioVideo(mixerID);
  }
}

/// @nodoc
extension ZegoUIKitCoreAudioVideo on ZegoUIKitCore {
  Future<void> startPlayAnotherRoomAudioVideo(
    String roomID,
    String userID,
    String userName,
  ) async {
    return coreData.startPlayAnotherRoomAudioVideo(roomID, userID, userName);
  }

  Future<void> stopPlayAnotherRoomAudioVideo(String userID) async {
    return coreData.stopPlayAnotherRoomAudioVideo(userID);
  }
}

/// @nodoc
extension ZegoUIKitCoreScreenShare on ZegoUIKitCore {}
