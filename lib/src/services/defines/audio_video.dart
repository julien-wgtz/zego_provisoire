// Package imports:

// Package imports:
import 'package:zego_express_engine/zego_express_engine.dart';

String get attributeKeyAvatar => 'avatar';

class ZegoUIKitReceiveTurnOnLocalMicrophoneEvent {
  final String fromUserID;
  final bool muteMode;

  ZegoUIKitReceiveTurnOnLocalMicrophoneEvent(this.fromUserID, this.muteMode);

  @override
  String toString() {
    return 'from user id:$fromUserID, mute mode:$muteMode';
  }
}

enum ZegoUIKitInnerSEIType {
  mixerDeviceState,
  mediaSyncInfo,
  custom,
}

/// receive SEI from remote
class ZegoUIKitReceiveSEIEvent {
  final String typeIdentifier;

  final String senderID;
  final Map<String, dynamic> sei;

  final String streamID;
  final ZegoStreamType streamType;

  ZegoUIKitReceiveSEIEvent({
    required this.streamID,
    required this.typeIdentifier,
    required this.senderID,
    required this.sei,
    required this.streamType,
  });

  @override
  String toString() {
    return 'ZegoUIKitReceiveSEIEvent{'
        'streamID:$streamID, '
        'streamType:$streamType, '
        'senderID:$senderID, '
        'typeIdentifier:$typeIdentifier, '
        'sei:$sei, '
        '}';
  }
}

/// Stream Resource Mode
enum ZegoAudioVideoResourceMode {
  /// Default mode. The SDK will automatically select the streaming resource according to the cdnConfig parameters set by the player config and the ready-made background configuration.
  defaultMode,

  /// Playing stream only from CDN.
  onlyCDN,

  /// Playing stream only from L3.
  onlyL3,

  /// Playing stream only from RTC.
  onlyRTC,

  /// CDN Plus mode. The SDK will automatically select the streaming resource according to the network condition.
  cdnPlus,
}

typedef ZegoPresetResolution = ZegoVideoConfigPreset;

///  configuration parameters for audio and video streaming, such as Resolution, Frame rate, Bit rate..
class ZegoUIKitVideoConfig {
  /// Frame rate, control the frame rate of the camera and the frame rate of the encoder.
  int fps;

  /// Bit rate in kbps.
  int bitrate;

  /// resolution width, control the image width of camera image acquisition or encoder when publishing stream.
  int width;

  /// resolution height, control the image height of camera image acquisition or encoder when publishing stream.
  int height;

  ZegoUIKitVideoConfig({
    required this.bitrate,
    required this.fps,
    required this.width,
    required this.height,
  });

  ZegoUIKitVideoConfig.preset180P()
      : width = 180,
        height = 320,
        bitrate = 300,
        fps = 15;

  ZegoUIKitVideoConfig.preset270P()
      : width = 270,
        height = 480,
        bitrate = 400,
        fps = 15;

  ZegoUIKitVideoConfig.preset360P()
      : width = 360,
        height = 640,
        bitrate = 600,
        fps = 15;

  ZegoUIKitVideoConfig.preset540P()
      : width = 540,
        height = 960,
        bitrate = 1200,
        fps = 15;

  ZegoUIKitVideoConfig.preset720P()
      : width = 720,
        height = 1280,
        bitrate = 1500,
        fps = 15;

  ZegoUIKitVideoConfig.preset1080P()
      : width = 1080,
        height = 1920,
        bitrate = 3000,
        fps = 15;

  ZegoUIKitVideoConfig.preset2K()
      : width = 1440,
        height = 2560,
        bitrate = 6000,
        fps = 15;

  ZegoUIKitVideoConfig.preset4K()
      : width = 2160,
        height = 3840,
        bitrate = 12000,
        fps = 15;

  ZegoVideoConfig get toSDK {
    final videoConfig = ZegoVideoConfig.preset(
      ZegoVideoConfigPreset.Preset360P,
    );

    videoConfig.bitrate = bitrate;
    videoConfig.fps = fps;

    videoConfig.encodeWidth = width;
    videoConfig.captureWidth = width;

    videoConfig.encodeHeight = height;
    videoConfig.captureHeight = height;

    return videoConfig;
  }

  @override
  String toString() {
    return 'ZegoUIKitVideoConfig{'
        'fps:$fps, '
        'bitrate:$bitrate, '
        'width:$width, '
        'height:$height, '
        '}';
  }
}

enum ZegoStreamType {
  main,
  media,
  screenSharing,
  mix,
}

extension ZegoStreamTypeExtension on ZegoStreamType {
  String get text {
    switch (this) {
      case ZegoStreamType.main:
      case ZegoStreamType.mix:
        return name;
      case ZegoStreamType.media:
        return 'player';
      case ZegoStreamType.screenSharing:
        return 'screensharing';
    }
  }

  ZegoPublishChannel get channel {
    switch (this) {
      case ZegoStreamType.main:
        return ZegoPublishChannel.Main;
      case ZegoStreamType.media:
      case ZegoStreamType.screenSharing:
      case ZegoStreamType.mix:
        return ZegoPublishChannel.Aux;
    }
  }
}

/// Audio route
enum ZegoUIKitAudioRoute {
  speaker,
  headphone,

  /// bluetooth device
  bluetooth,

  /// telephone receiver
  receiver,

  /// external USB audio device
  externalUSB,

  /// apple AirPlay
  airPlay,
}

/// Traffic control property (bitmask enumeration).
enum ZegoUIKitTrafficControlProperty {
  /// Basic (Adaptive (reduce) video bitrate)
  basic,

  /// Adaptive (reduce) video FPS
  adaptiveFPS,

  /// Adaptive (reduce) video resolution
  adaptiveResolution,

  /// Adaptive (reduce) audio bitrate
  adaptiveAudioBitrate,
}

extension ZegoUIKitTrafficControlPropertyExtension
    on ZegoUIKitTrafficControlProperty {
  int get value {
    switch (this) {
      case ZegoUIKitTrafficControlProperty.basic:
        return 0;
      case ZegoUIKitTrafficControlProperty.adaptiveFPS:
        return 1;
      case ZegoUIKitTrafficControlProperty.adaptiveResolution:
        return 1 << 1;
      case ZegoUIKitTrafficControlProperty.adaptiveAudioBitrate:
        return 1 << 2;
    }
  }
}

enum ZegoUIKitDeviceExceptionType {
  /// Unknown device exception.
  unknown,

  /// Generic device exception.
  generic,

  /// Invalid device ID exception.
  invalidId,

  /// Device permission is not granted.
  permissionNotGranted,

  /// The capture frame rate of the device is 0.
  zeroCaptureFps,

  /// The device is being occupied.
  deviceOccupied,

  /// The device is unplugged (not plugged in).
  deviceUnplugged,

  /// The device requires the system to restart before it can work (Windows platform only).
  rebootRequired,

  /// The system media service is unavailable, e.g. when the iOS system detects that the current pressure is huge (such as playing a lot of animation), it is possible to disable all media related services (Apple platform only).
  mediaServicesWereLost,

  /// The device is being occupied by Siri (Apple platform only).
  siriIsRecording,

  /// The device captured sound level is too low (Windows platform only).
  soundLevelTooLow,

  /// The device is being occupied, and maybe cause by iPad magnetic case (Apple platform only).
  magneticCase,

  /// Audio session deactivate (Apple platform only).
  audioSessionDeactivate,

  /// Audio session category change (Apple platform only).
  audioSessionCategoryChange,

  /// The device is interrupted, such as a phone call interruption, etc.
  interruption,

  /// There are multiple apps at the same time in the foreground, such as the iPad app split screen, the system will prohibit all apps from using the camera.
  inBackground,

  /// CDN server actively disconnected
  multiForegroundApp,

  /// The system is under high load pressure and may cause abnormal equipment.
  bySystemPressure,
}

extension ZegoUIKitDeviceExceptionTypeExtension
    on ZegoUIKitDeviceExceptionType {
  static ZegoUIKitDeviceExceptionType fromSDKValue(
    ZegoDeviceExceptionType value,
  ) {
    switch (value) {
      case ZegoDeviceExceptionType.Unknown:
        return ZegoUIKitDeviceExceptionType.unknown;
      case ZegoDeviceExceptionType.Generic:
        return ZegoUIKitDeviceExceptionType.generic;
      case ZegoDeviceExceptionType.InvalidId:
        return ZegoUIKitDeviceExceptionType.invalidId;
      case ZegoDeviceExceptionType.PermissionNotGranted:
        return ZegoUIKitDeviceExceptionType.permissionNotGranted;
      case ZegoDeviceExceptionType.ZeroCaptureFps:
        return ZegoUIKitDeviceExceptionType.zeroCaptureFps;
      case ZegoDeviceExceptionType.DeviceOccupied:
        return ZegoUIKitDeviceExceptionType.deviceOccupied;
      case ZegoDeviceExceptionType.DeviceUnplugged:
        return ZegoUIKitDeviceExceptionType.deviceUnplugged;
      case ZegoDeviceExceptionType.RebootRequired:
        return ZegoUIKitDeviceExceptionType.rebootRequired;
      case ZegoDeviceExceptionType.MediaServicesWereLost:
        return ZegoUIKitDeviceExceptionType.mediaServicesWereLost;
      case ZegoDeviceExceptionType.SiriIsRecording:
        return ZegoUIKitDeviceExceptionType.siriIsRecording;
      case ZegoDeviceExceptionType.SoundLevelTooLow:
        return ZegoUIKitDeviceExceptionType.soundLevelTooLow;
      case ZegoDeviceExceptionType.MagneticCase:
        return ZegoUIKitDeviceExceptionType.magneticCase;
      case ZegoDeviceExceptionType.AudioSessionDeactive:
        return ZegoUIKitDeviceExceptionType.audioSessionDeactivate;
      case ZegoDeviceExceptionType.AudioSessionCategoryChange:
        return ZegoUIKitDeviceExceptionType.audioSessionCategoryChange;
    }
  }

  static ZegoUIKitDeviceExceptionType? fromDeviceState(
    ZegoRemoteDeviceState value,
  ) {
    switch (value) {
      case ZegoRemoteDeviceState.GenericError:
        return ZegoUIKitDeviceExceptionType.generic;
      case ZegoRemoteDeviceState.InvalidID:
        return ZegoUIKitDeviceExceptionType.invalidId;
      case ZegoRemoteDeviceState.NoAuthorization:
        return ZegoUIKitDeviceExceptionType.permissionNotGranted;
      case ZegoRemoteDeviceState.ZeroFPS:
        return ZegoUIKitDeviceExceptionType.zeroCaptureFps;
      case ZegoRemoteDeviceState.InUseByOther:
        return ZegoUIKitDeviceExceptionType.deviceOccupied;
      case ZegoRemoteDeviceState.Unplugged:
        return ZegoUIKitDeviceExceptionType.deviceUnplugged;
      case ZegoRemoteDeviceState.RebootRequired:
        return ZegoUIKitDeviceExceptionType.rebootRequired;
      case ZegoRemoteDeviceState.SystemMediaServicesLost:
        return ZegoUIKitDeviceExceptionType.mediaServicesWereLost;
      case ZegoRemoteDeviceState.Interruption:
        return ZegoUIKitDeviceExceptionType.interruption;
      case ZegoRemoteDeviceState.InBackground:
        return ZegoUIKitDeviceExceptionType.inBackground;
      case ZegoRemoteDeviceState.MultiForegroundApp:
        return ZegoUIKitDeviceExceptionType.multiForegroundApp;
      case ZegoRemoteDeviceState.BySystemPressure:
        return ZegoUIKitDeviceExceptionType.bySystemPressure;
      case ZegoRemoteDeviceState.NotSupport:
      case ZegoRemoteDeviceState.Open:
      case ZegoRemoteDeviceState.Disable:
      case ZegoRemoteDeviceState.Mute:
        // not error
        return null;
    }
  }
}
