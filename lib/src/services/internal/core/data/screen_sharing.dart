// Dart imports:
import 'dart:async';
import 'dart:io' show Platform;

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:zego_express_engine/zego_express_engine.dart';

// Project imports:
import 'package:zego_uikit/src/services/internal/internal.dart';
import 'package:zego_uikit/src/services/services.dart';

mixin ZegoUIKitCoreDataScreenSharing {
  StreamController<List<ZegoUIKitCoreUser>>? screenSharingListStreamCtrl;

  ZegoScreenCaptureSource? screenCaptureSource;
  ValueNotifier<bool> isScreenSharing = ValueNotifier(false);
  bool isFirstScreenSharing = true;

  void initScreenSharing() {
    ZegoLoggerService.logInfo(
      'init screen sharing',
      subTag: 'screen sharing',
    );

    screenSharingListStreamCtrl ??=
        StreamController<List<ZegoUIKitCoreUser>>.broadcast();
  }

  void uninitScreenSharing() {
    ZegoLoggerService.logInfo(
      'uninit screen sharing',
      subTag: 'screen sharing',
    );

    screenSharingListStreamCtrl?.close();
    screenSharingListStreamCtrl = null;
  }

  //start screen share
  Future<void> startSharingScreen() async {
    screenCaptureSource =
        await ZegoExpressEngine.instance.createScreenCaptureSource();

    await ZegoExpressEngine.instance
        .setVideoSource(
      ZegoVideoSourceType.ScreenCapture,
      instanceID: screenCaptureSource?.getIndex(),
      channel: ZegoStreamType.screenSharing.channel,
    )
        .then((value) {
      isScreenSharing.value = true;
      ZegoUIKitCore.shared.coreData
          .startPublishingStream(streamType: ZegoStreamType.screenSharing);
      final config = ZegoScreenCaptureConfig(
        true,
        true,
        microphoneVolume: 100,
        applicationVolume: 100,
      );
      screenCaptureSource?.startCapture(config: config);
    });

    if (isFirstScreenSharing && Platform.isAndroid) {
      isFirstScreenSharing = false;
      await stopSharingScreen();
      startSharingScreen();
    }
  }

  //stop screen share
  Future<void> stopSharingScreen() async {
    isScreenSharing.value = false;

    await ZegoUIKitCore.shared.coreData.stopPublishingStream(
      streamType: ZegoStreamType.screenSharing,
    );

    screenCaptureSource?.stopCapture();

    await ZegoExpressEngine.instance
        .destroyScreenCaptureSource(screenCaptureSource!);
  }
}
