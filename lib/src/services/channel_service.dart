part of 'uikit_service.dart';

mixin ZegoChannelService {
  /// Android go to the desktop
  Future<void> backToDesktop({
    bool nonRoot = false,
  }) async {
    return ZegoUIKitPluginPlatform.instance.backToDesktop();
  }

  /// 'onWillPop' in Android returns true will cause the Flutter engine to be destroyed,
  /// resulting in the inability to interact between native code and Flutter code.
  ///
  /// Here, if Android wants to go to the desktop,
  /// it should be implemented by calling native code instead of returning true
  Future<bool> onWillPop(BuildContext context) async {
    if (Platform.isAndroid) {
      if (Navigator.of(context).canPop()) {
        return true;
      } else {
        await ZegoUIKit().backToDesktop();
        return false;
      }
    }

    return true;
  }
}
