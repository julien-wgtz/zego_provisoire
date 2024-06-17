// Package imports:
import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';

// Project imports:
import 'package:zego_uikit/src/plugins/signaling/impl/core/core.dart';

/// @nodoc
mixin ZegoPluginNotificationService {
  /// enable notification
  Future<ZegoSignalingPluginEnableNotifyResult>
      enableNotifyWhenAppRunningInBackgroundOrQuit(
    bool enabled, {
    bool? isIOSSandboxEnvironment,
    bool enableIOSVoIP = true,
    int /*ZegoSignalingPluginMultiCertificate*/ certificateIndex = 1,
    String appName = '',
    String androidChannelID = '',
    String androidChannelName = '',
    String androidSound = '',
  }) {
    return ZegoSignalingPluginCore.shared.coreData
        .enableNotifyWhenAppRunningInBackgroundOrQuit(
      enabled,
      isIOSSandboxEnvironment: isIOSSandboxEnvironment,
      certificateIndex: ZegoSignalingPluginIOSMultiCertificateExtension.fromID(
        certificateIndex,
      ),
      enableIOSVoIP: enableIOSVoIP,
      appName: appName,
      androidChannelID: androidChannelID,
      androidChannelName: androidChannelName,
      androidSound: androidSound,
    );
  }
}
