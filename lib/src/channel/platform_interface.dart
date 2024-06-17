// Package imports:
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Project imports:
import 'method_channel.dart';

/// @nodoc
abstract class ZegoUIKitPluginPlatform extends PlatformInterface {
  /// Constructs a ZegoUIKitPluginPlatform.
  ZegoUIKitPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZegoUIKitPluginPlatform _instance = MethodChannelZegoUIKitPlugin();

  /// The default instance of [ZegoUIKitPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelUntitled].
  static ZegoUIKitPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZegoUIKitPluginPlatform] when
  /// they register themselves.
  static set instance(ZegoUIKitPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// backToDesktop
  Future<void> backToDesktop({
    bool nonRoot = false,
  }) {
    throw UnimplementedError('backToDesktop has not been implemented.');
  }
}
