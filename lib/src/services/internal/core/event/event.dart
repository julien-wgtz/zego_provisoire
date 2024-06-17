// Dart imports:
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:zego_express_engine/zego_express_engine.dart';

// Project imports:
import 'package:zego_uikit/src/services/defines/express.event.dart';
import 'package:zego_uikit/src/services/defines/media.event.dart';
import 'package:zego_uikit/src/services/uikit_service.dart';

part 'express.dart';

part 'media.dart';

class ZegoUIKitEvent with ZegoUIKitExpressEvent, ZegoUIKitMediaEvent {
  bool _isInit = false;

  bool uninitOnRoomLeaved = true;

  void enableUninitOnRoomLeaved(bool enabled) {
    uninitOnRoomLeaved = enabled;
  }

  void init() {
    if (_isInit) {
      ZegoLoggerService.logInfo(
        'had init before',
        tag: 'uikit core',
        subTag: 'event',
      );

      return;
    }

    ZegoLoggerService.logInfo(
      'init',
      tag: 'uikit core',
      subTag: 'event',
    );

    _isInit = true;

    express.init();
    media.init();
  }

  void uninit() {
    if (!_isInit) {
      ZegoLoggerService.logInfo(
        'is not init',
        tag: 'uikit core',
        subTag: 'event',
      );

      return;
    }

    ZegoLoggerService.logInfo(
      'uninit',
      tag: 'uikit core',
      subTag: 'event',
    );

    if (uninitOnRoomLeaved) {
      express.uninit();
      media.uninit();
    }

    _isInit = false;
  }
}
