// Dart imports:

// Package imports:
import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';

// Project imports:
import 'package:zego_uikit/src/services/services.dart';

/// @nodoc
mixin ZegoSignalingPluginCoreNotificationData {
  bool notifyWhenAppIsInTheBackgroundOrQuit = false;

  /// enable notification
  Future<ZegoSignalingPluginEnableNotifyResult>
      enableNotifyWhenAppRunningInBackgroundOrQuit(
    bool enabled, {
    bool? isIOSSandboxEnvironment,
    bool enableIOSVoIP = true,
    ZegoSignalingPluginMultiCertificate certificateIndex =
        ZegoSignalingPluginMultiCertificate.firstCertificate,
    String appName = '',
    String androidChannelID = '',
    String androidChannelName = '',
    String androidSound = '',
  }) {
    ZegoLoggerService.logInfo(
      'enable notify when app is in the background or quit: $enabled',
      tag: 'uikit',
      subTag: 'signaling notification data',
    );
    notifyWhenAppIsInTheBackgroundOrQuit = enabled;

    return ZegoPluginAdapter()
        .signalingPlugin!
        .enableNotifyWhenAppRunningInBackgroundOrQuit(
          isIOSSandboxEnvironment: isIOSSandboxEnvironment,
          enableIOSVoIP: enableIOSVoIP,
          certificateIndex: certificateIndex,
          appName: appName,
          androidChannelID: androidChannelID,
          androidChannelName: androidChannelName,
          androidSound: androidSound,
        );
  }
}
