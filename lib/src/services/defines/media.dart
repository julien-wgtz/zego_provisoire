// Package imports:
import 'package:zego_express_engine/zego_express_engine.dart';

/// media type
enum ZegoUIKitMediaType {
  pureAudio,
  video,
  unknown,
}

/// media play result
class ZegoUIKitMediaPlayResult {
  int errorCode;
  String message;

  ZegoUIKitMediaPlayResult({
    required this.errorCode,
    this.message = '',
  });
}

/// seek result of media
class ZegoUIKitMediaSeekToResult {
  int errorCode;
  String message;

  ZegoUIKitMediaSeekToResult({
    required this.errorCode,
    this.message = '',
  });
}

/// media play state
/// normal process: noPlay->loadReady->playing->playEnded
enum ZegoUIKitMediaPlayState {
  /// Not playing
  noPlay,

  /// not start yet
  loadReady,

  /// Playing
  playing,

  /// Pausing
  pausing,

  /// End of play
  playEnded
}

extension ZegoUIKitMediaPlayStateExtension on ZegoUIKitMediaPlayState {
  static ZegoUIKitMediaPlayState fromZego(
      ZegoMediaPlayerState zegoMediaPlayerState) {
    switch (zegoMediaPlayerState) {
      case ZegoMediaPlayerState.NoPlay:
        return ZegoUIKitMediaPlayState.noPlay;
      case ZegoMediaPlayerState.Playing:
        return ZegoUIKitMediaPlayState.playing;
      case ZegoMediaPlayerState.Pausing:
        return ZegoUIKitMediaPlayState.pausing;
      case ZegoMediaPlayerState.PlayEnded:
        return ZegoUIKitMediaPlayState.playEnded;
    }
  }
}

/// Media Infomration of media file.
///
/// Meida information such as video resolution of media file.
class ZegoUIKitMediaInfo {
  /// Video resolution width.
  int width;

  /// Video resolution height.
  int height;

  /// Video frame rate.
  int frameRate;

  ZegoUIKitMediaInfo({
    required this.width,
    required this.height,
    required this.frameRate,
  });

  /// Constructs a media player information object by default.
  ZegoUIKitMediaInfo.defaultInfo()
      : width = 0,
        height = 0,
        frameRate = 0;

  ZegoUIKitMediaInfo.fromZego(ZegoMediaPlayerMediaInfo? zegoMediaInfo)
      : this(
          width: zegoMediaInfo?.width ?? 0,
          height: zegoMediaInfo?.height ?? 0,
          frameRate: zegoMediaInfo?.frameRate ?? 0,
        );
}

@Deprecated('Since 2.17.0, please use ZegoUIKitMediaInfo instead')
typedef MediaInfo = ZegoUIKitMediaInfo;
@Deprecated('Since 2.17.0, please use ZegoUIKitMediaPlayState instead')
typedef MediaPlayState = ZegoUIKitMediaPlayState;
@Deprecated('Since 2.17.0, please use ZegoUIKitMediaType instead')
typedef MediaType = ZegoUIKitMediaType;
@Deprecated('Since 2.17.0, please use ZegoUIKitMediaPlayResult instead')
typedef MediaPlayResult = ZegoUIKitMediaPlayResult;
@Deprecated('Since 2.17.0, please use ZegoUIKitMediaSeekToResult instead')
typedef MediaSeekToResult = ZegoUIKitMediaSeekToResult;
