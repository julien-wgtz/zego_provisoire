// Package imports:
import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';

/// @nodoc
mixin ZegoPluginBackgroundMessageService {
  Future<ZegoSignalingPluginSetMessageHandlerResult>
      setBackgroundMessageHandler(
          ZegoSignalingPluginZPNsBackgroundMessageHandler handler) async {
    return ZegoPluginAdapter()
        .signalingPlugin!
        .setBackgroundMessageHandler(handler);
  }

  Future<ZegoSignalingPluginSetMessageHandlerResult> setThroughMessageHandler(
    ZegoSignalingPluginZPNsThroughMessageHandler? handler,
  ) async {
    return ZegoPluginAdapter()
        .signalingPlugin!
        .setThroughMessageHandler(handler);
  }
}
