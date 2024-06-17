// Dart imports:
import 'dart:io' show Platform;

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:file_picker/file_picker.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';

// Project imports:
import 'package:zego_uikit/src/channel/platform_interface.dart';
import 'package:zego_uikit/src/plugins/beauty/uikit_beauty_plugin_impl.dart';
import 'package:zego_uikit/src/plugins/plugins.dart';
import 'package:zego_uikit/src/plugins/signaling/impl/core/core.dart';
import 'package:zego_uikit/src/services/defines/defines.dart';
import 'package:zego_uikit/src/services/internal/internal.dart';

part 'audio_video_service.dart';

part 'custom_command_service.dart';

part 'channel_service.dart';

part 'device_service.dart';

part 'effect_service.dart';

part 'logger_service.dart';

part 'media_service.dart';

part 'message_service.dart';

part 'plugin_service.dart';

part 'room_service.dart';

part 'user_service.dart';

part 'mixer_service.dart';

/// {@category APIs}
/// {@category Features}
class ZegoUIKit
    with
        ZegoAudioVideoService,
        ZegoRoomService,
        ZegoUserService,
        ZegoChannelService,
        ZegoMessageService,
        ZegoCustomCommandService,
        ZegoDeviceService,
        ZegoEffectService,
        ZegoPluginService,
        ZegoMediaService,
        ZegoMixerService,
        ZegoLoggerService {
  factory ZegoUIKit() {
    /// make sure core data stream had created
    ZegoUIKitCore.shared.coreData.init();

    return instance;
  }

  ZegoUIKit._internal() {
    WidgetsFlutterBinding.ensureInitialized();

    initLog();
  }

  static final ZegoUIKit instance = ZegoUIKit._internal();

  /// version
  Future<String> getZegoUIKitVersion() async {
    return ZegoUIKitCore.shared.getZegoUIKitVersion();
  }

  /// init
  Future<void> init({
    required int appID,
    String appSign = '',
    bool? enablePlatformView,
    ZegoScenario scenario = ZegoScenario.Default,
  }) async {
    return ZegoUIKitCore.shared.init(
      appID: appID,
      appSign: appSign,
      scenario: scenario,
      enablePlatformView: enablePlatformView,
    );
  }

  /// uninit
  Future<void> uninit() async {
    return ZegoUIKitCore.shared.uninit();
  }

  void enableEventUninitOnRoomLeaved(bool enabled) {
    ZegoUIKitCore.shared.event.enableUninitOnRoomLeaved(enabled);
  }

  void registerExpressEvent(ZegoUIKitExpressEventInterface event) {
    ZegoUIKitCore.shared.event.express.register(event);
  }

  void unregisterExpressEvent(ZegoUIKitExpressEventInterface event) {
    ZegoUIKitCore.shared.event.express.unregister(event);
  }

  /// Set advanced engine configuration, Used to enable advanced functions.
  /// For details, please consult ZEGO technical support.
  Future<void> setAdvanceConfigs(Map<String, String> configs) async {
    await ZegoUIKitCore.shared.setAdvanceConfigs(configs);
  }

  ValueNotifier<DateTime?> getNetworkTime() {
    return ZegoUIKitCore.shared.getNetworkTime();
  }

  Stream<ZegoUIKitError> getErrorStream() {
    return ZegoUIKitCore.shared.error.errorStreamCtrl?.stream ??
        const Stream.empty();
  }
}
