// Dart imports:
import 'dart:io' show Platform;

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:zego_uikit/src/channel/platform_interface.dart';
import 'package:zego_uikit/src/services/services.dart';

/// @nodoc
/// An implementation of [ZegoUIKitPluginPlatform] that uses method channels.
class MethodChannelZegoUIKitPlugin extends ZegoUIKitPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zego_uikit_plugin');

  /// backToDesktop
  @override
  Future<void> backToDesktop({
    bool nonRoot = false,
  }) async {
    if (Platform.isIOS) {
      ZegoLoggerService.logInfo(
        'backToDesktop, not support in iOS',
        tag: 'signaling',
        subTag: 'channel',
      );
      return;
    }

    ZegoLoggerService.logInfo(
      'backToDesktop, nonRoot:$nonRoot',
      tag: 'signaling',
      subTag: 'channel',
    );

    try {
      await methodChannel.invokeMethod<String>('backToDesktop', {
        'nonRoot': nonRoot,
      });
    } on PlatformException catch (e) {
      ZegoLoggerService.logError(
        'Failed to back to desktop: $e.',
        tag: 'signaling',
        subTag: 'channel',
      );
    }
  }
}
