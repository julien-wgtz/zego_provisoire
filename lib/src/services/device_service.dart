part of 'uikit_service.dart';

mixin ZegoDeviceService {
  /// protocol: String is 'operator'
  Stream<String> getTurnOnYourCameraRequestStream() {
    return ZegoUIKitCore
            .shared.coreData.turnOnYourCameraRequestStreamCtrl?.stream ??
        const Stream.empty();
  }

  Stream<ZegoUIKitReceiveTurnOnLocalMicrophoneEvent>
      getTurnOnYourMicrophoneRequestStream() {
    return ZegoUIKitCore
            .shared.coreData.turnOnYourMicrophoneRequestStreamCtrl?.stream ??
        const Stream.empty();
  }

  void enableCustomVideoProcessing(bool enable) {
    ZegoUIKitCore.shared.enableCustomVideoProcessing(enable);
  }
}
