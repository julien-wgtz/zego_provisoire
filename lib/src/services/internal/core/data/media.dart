// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

// Project imports:
import 'package:zego_uikit/src/services/internal/internal.dart';
import 'package:zego_uikit/src/services/services.dart';

/// @nodoc
mixin ZegoUIKitCoreDataMedia {
  final _mediaImpl = ZegoUIKitCoreDataMediaImpl();

  ZegoUIKitCoreDataMediaImpl get media => _mediaImpl;
}

/// @nodoc
class ZegoUIKitCoreDataMediaImpl extends ZegoUIKitMediaEventInterface {
  String? _ownerID;
  ZegoMediaPlayer? _currentPlayer;

  int _duration = 0;
  double _soundLevel = 0.0;
  ZegoMediaPlayerMediaInfo? _mediaInfo;

  StreamController<List<ZegoUIKitCoreUser>>? mediaListStreamCtrl;

  /// [0~200] => [0~100]
  final volumeNotifier = ValueNotifier<int>(30);

  /// millisecond
  final progressNotifier = ValueNotifier<int>(0);
  final stateNotifier =
      ValueNotifier<ZegoUIKitMediaPlayState>(ZegoUIKitMediaPlayState.noPlay);
  final typeNotifier =
      ValueNotifier<ZegoUIKitMediaType>(ZegoUIKitMediaType.unknown);
  final muteNotifier = ValueNotifier<bool>(false);

  List<String> get pureAudioExtensions => ['mp3', 'aac', 'wav', 'midi', "ogg"];

  List<String> get videoExtensions =>
      ['mp4', 'avi', 'mov', "flv", "mkv", "mpeg", "webm", "wmv"];

  ZegoMediaPlayerMediaInfo? get mediaInfo => _mediaInfo;

  String? get ownerID => _ownerID;

  ZegoMediaPlayer? get currentPlayer => _currentPlayer;

  void init() {
    ZegoLoggerService.logInfo(
      'init media',
      subTag: 'media',
    );

    mediaListStreamCtrl ??=
        StreamController<List<ZegoUIKitCoreUser>>.broadcast();
  }

  void uninit() {
    ZegoLoggerService.logInfo(
      'uninit media',
      subTag: 'media',
    );

    mediaListStreamCtrl?.close();
    mediaListStreamCtrl = null;
  }

  ZegoVideoConfig getPreferVideoConfig() {
    if (null == _mediaInfo) {
      return ZegoVideoConfig.preset(ZegoVideoConfigPreset.Preset540P);
    }

    var preset = ZegoVideoConfigPreset.Preset540P;
    final mediaHeight = _mediaInfo!.height;
    if (mediaHeight <= 180) {
      preset = ZegoVideoConfigPreset.Preset180P;
    } else if (mediaHeight <= 270) {
      preset = ZegoVideoConfigPreset.Preset270P;
    } else if (mediaHeight <= 360) {
      preset = ZegoVideoConfigPreset.Preset360P;
    } else if (mediaHeight <= 540) {
      preset = ZegoVideoConfigPreset.Preset540P;
    } else if (mediaHeight <= 720) {
      preset = ZegoVideoConfigPreset.Preset720P;
    } else {
      preset = ZegoVideoConfigPreset.Preset1080P;
    }
    return ZegoVideoConfig.preset(preset)
      ..captureHeight = _mediaInfo!.height
      ..captureWidth = _mediaInfo!.width
      ..encodeHeight = _mediaInfo!.height
      ..encodeWidth = _mediaInfo!.width
      ..fps = _mediaInfo!.frameRate;
  }

  Future<void> clear() async {
    ZegoLoggerService.logInfo(
      'clear',
      tag: 'uikit core data',
      subTag: 'media',
    );

    await stop();

    if (null != _currentPlayer) {
      ZegoLoggerService.logInfo(
        'destroy media player',
        tag: 'uikit core data',
        subTag: 'media',
      );

      await ZegoExpressEngine.instance.destroyMediaPlayer(_currentPlayer!);
      _currentPlayer = null;
    }
  }

  Future<ZegoUIKitMediaPlayResult> play({
    required String filePathOrURL,
    bool enableRepeat = false,
    bool autoStart = true,
  }) async {
    ZegoLoggerService.logInfo(
      'play media, path:$filePathOrURL, repeat:$enableRepeat, auto start:$autoStart',
      tag: 'uikit core data',
      subTag: 'media',
    );

    if (ZegoUIKitMediaPlayState.playing == stateNotifier.value ||
        ZegoUIKitMediaPlayState.pausing == stateNotifier.value) {
      ZegoLoggerService.logInfo(
        'playMedia exist playing source:${stateNotifier.value}',
        tag: 'uikit core data',
        subTag: 'media',
      );
      await stop();
    }

    _currentPlayer ??= await ZegoExpressEngine.instance.createMediaPlayer();
    _currentPlayer!.enableSoundLevelMonitor(true, 200);
    _currentPlayer!.enableRepeat(enableRepeat);

    _ownerID = ZegoUIKitCore.shared.coreData.localUser.id;

    ZegoLoggerService.logInfo(
      'try load resource:$filePathOrURL',
      tag: 'uikit core data',
      subTag: 'media',
    );
    final loadResult = await _currentPlayer!.loadResource(filePathOrURL);
    if (ZegoErrorCode.CommonSuccess != loadResult.errorCode) {
      ZegoLoggerService.logInfo(
        'loadResource, code:${loadResult.errorCode}',
        tag: 'uikit core data',
        subTag: 'media',
      );
      return ZegoUIKitMediaPlayResult(
        errorCode: loadResult.errorCode,
        message: 'loadResource error:${loadResult.errorCode}, '
            'path:$filePathOrURL, '
            '${ZegoUIKitErrorCode.expressErrorCodeDocumentTips}',
      );
    }
    _updatePlayStateWithSync(ZegoUIKitMediaPlayState.loadReady);

    _mediaInfo = await _currentPlayer!.getMediaInfo();

    final pathExtension = path.extension(filePathOrURL);
    final extension = pathExtension.substring(1); //  remove point
    if (pureAudioExtensions.contains(extension)) {
      typeNotifier.value = ZegoUIKitMediaType.pureAudio;
    } else if (videoExtensions.contains(extension)) {
      typeNotifier.value = ZegoUIKitMediaType.video;
    } else {
      ZegoLoggerService.logInfo(
        'parse media extension error, path:$filePathOrURL, extension:$extension',
        tag: 'uikit core data',
        subTag: 'media',
      );
      typeNotifier.value = ZegoUIKitMediaType.unknown;
    }

    if (autoStart) {
      start();
    }

    _currentPlayer!.setPublishVolume(200);

    volumeNotifier.value = await _currentPlayer!.getPlayVolume() ~/ 2;
    _duration = await _currentPlayer!.getTotalDuration();
    progressNotifier.value = await _currentPlayer!.getCurrentProgress();

    return ZegoUIKitMediaPlayResult(errorCode: ZegoUIKitErrorCode.success);
  }

  Future<void> start() async {
    ZegoLoggerService.logInfo(
      'try start media..',
      tag: 'uikit core data',
      subTag: 'media',
    );

    await _currentPlayer?.start();
    _updatePlayStateWithSync(ZegoUIKitMediaPlayState.playing);

    ZegoLoggerService.logInfo(
      'start done',
      tag: 'uikit core data',
      subTag: 'media',
    );
  }

  Future<void> stop() async {
    ZegoLoggerService.logInfo(
      'stopMedia',
      tag: 'uikit core data',
      subTag: 'media',
    );

    if (ZegoUIKitMediaPlayState.playing == stateNotifier.value) {
      await _updatePlayStateWithSync(ZegoUIKitMediaPlayState.playEnded);
    }

    _currentPlayer?.stop();

    _duration = 0;
    volumeNotifier.value = 30;
    progressNotifier.value = 0;
    _soundLevel = 0.0;
    typeNotifier.value = ZegoUIKitMediaType.unknown;
    muteNotifier.value = false;
    _ownerID = null;

    await _updatePlayStateWithSync(ZegoUIKitMediaPlayState.noPlay);

    ZegoLoggerService.logInfo(
      'stopMedia done',
      tag: 'uikit core data',
      subTag: 'media',
    );
  }

  Future<void> pause() async {
    if (ZegoUIKitMediaPlayState.pausing == stateNotifier.value) {
      ZegoLoggerService.logInfo(
        'pauseMedia, state(${stateNotifier.value}) is not pausing',
        tag: 'uikit core data',
        subTag: 'media',
      );
      return;
    }

    ZegoLoggerService.logInfo(
      'pauseMedia',
      tag: 'uikit core data',
      subTag: 'media',
    );

    _updatePlayStateWithSync(ZegoUIKitMediaPlayState.pausing);

    return _currentPlayer?.pause();
  }

  Future<void> resume() async {
    if (ZegoUIKitMediaPlayState.playing == stateNotifier.value) {
      ZegoLoggerService.logInfo(
        'resumeMedia, state(${stateNotifier.value}) is playing',
        tag: 'uikit core data',
        subTag: 'media',
      );
      return;
    }

    ZegoLoggerService.logInfo(
      'resumeMedia',
      tag: 'uikit core data',
      subTag: 'media',
    );

    _updatePlayStateWithSync(ZegoUIKitMediaPlayState.playing);

    return _currentPlayer?.resume();
  }

  Future<ZegoUIKitMediaSeekToResult> seekTo(int millisecond) async {
    ZegoLoggerService.logInfo(
      'media seek to $millisecond',
      tag: 'uikit core data',
      subTag: 'media',
    );

    /// change local first, sdk callback will correct if failed
    progressNotifier.value = millisecond;

    final seekResult = await _currentPlayer?.seekTo(millisecond);
    ZegoLoggerService.logInfo(
      'media seek result:${seekResult?.errorCode}',
      tag: 'uikit core data',
      subTag: 'media',
    );

    final seekResultErrorCode =
        seekResult?.errorCode ?? ZegoUIKitErrorCode.success;
    return ZegoUIKitMediaSeekToResult(
      errorCode: seekResultErrorCode,
      message: ZegoUIKitErrorCode.success == seekResultErrorCode
          ? ''
          : 'seekTo error:$seekResultErrorCode, ${ZegoUIKitErrorCode.expressErrorCodeDocumentTips}',
    );
  }

  Future<void> setVolume(int volume, bool isSync) async {
    if (volume == volumeNotifier.value) {
      return;
    }

    ZegoLoggerService.logInfo(
      'set media volume:$volume, isSync:$isSync',
      tag: 'uikit core data',
      subTag: 'media',
    );
    volumeNotifier.value = volume;

    return isSync
        ? _currentPlayer?.setVolume(volume)
        : _currentPlayer?.setPlayVolume(volume);
  }

  int getVolume() {
    return volumeNotifier.value;
  }

  Future<void> muteLocal(bool mute) async {
    muteNotifier.value = mute;

    if (null != _currentPlayer) {
      ZegoLoggerService.logInfo(
        'mute local, mute:$mute',
        tag: 'uikit core data',
        subTag: 'media',
      );

      _currentPlayer?.muteLocal(mute);
    } else {
      // mute remote play stream
      final mediaOwner = ZegoUIKitCore.shared.coreData.getUser(_ownerID ?? '');
      ZegoLoggerService.logInfo(
        'mute remote, mute:$mute, owner:$mediaOwner',
        tag: 'uikit core data',
        subTag: 'media',
      );
      ZegoExpressEngine.instance.mutePlayStreamAudio(
        mediaOwner.auxChannel.streamID,
        mute,
      );
    }
  }

  int getTotalDuration() {
    return _duration;
  }

  Future<bool> _syncMediaInfoBySEI() async {
    return ZegoUIKitCore.shared.coreData.sendSEI(
      ZegoUIKitInnerSEIType.mediaSyncInfo.name,
      {
        ZegoUIKitSEIDefines.keyMediaStatus: stateNotifier.value.index,
        ZegoUIKitSEIDefines.keyMediaProgress: progressNotifier.value,
        ZegoUIKitSEIDefines.keyMediaDuration: _duration,
        ZegoUIKitSEIDefines.keyMediaSoundLevel: _soundLevel,
      },
      streamType: ZegoStreamType.media,
    );
  }

  @override
  void onMediaPlayerStateUpdate(
    ZegoMediaPlayer mediaPlayer,
    ZegoMediaPlayerState state,
    int errorCode,
  ) {
    ZegoLoggerService.logInfo(
      'onMediaPlayerStateUpdate state:$state, errorCode:$errorCode',
      tag: 'uikit core data',
      subTag: 'media',
    );

    _updatePlayStateWithSync(ZegoUIKitMediaPlayStateExtension.fromZego(state));
  }

  @override
  void onMediaPlayerNetworkEvent(
    ZegoMediaPlayer mediaPlayer,
    ZegoMediaPlayerNetworkEvent networkEvent,
  ) {
    ZegoLoggerService.logInfo(
      'onMediaPlayerNetworkEvent $networkEvent',
      tag: 'uikit core data',
      subTag: 'media',
    );
  }

  @override
  void onMediaPlayerPlayingProgress(
    ZegoMediaPlayer mediaPlayer,
    int millisecond,
  ) {
    progressNotifier.value = millisecond;
    _syncMediaInfoBySEI();
  }

  @override
  void onMediaPlayerRecvSEI(
    ZegoMediaPlayer mediaPlayer,
    Uint8List data,
  ) {
    // ZegoLoggerService.logInfo(
    //   'onMediaPlayerRecvSEI $data',
    //   tag: 'uikit core data',
    //   subTag: 'media',
    // );
  }

  @override
  void onMediaPlayerSoundLevelUpdate(
    ZegoMediaPlayer mediaPlayer,
    double soundLevel,
  ) {
    _soundLevel = soundLevel;

    ZegoUIKitCore.shared.coreData.localUser.auxChannel.soundLevel
        ?.add(soundLevel);
  }

  @override
  void onMediaPlayerFrequencySpectrumUpdate(
    ZegoMediaPlayer mediaPlayer,
    List<double> spectrumList,
  ) {
    ZegoLoggerService.logInfo(
      'onMediaPlayerFrequencySpectrumUpdate $spectrumList',
      tag: 'uikit core data',
      subTag: 'media',
    );
  }

  @override
  void onMediaPlayerFirstFrameEvent(
    ZegoMediaPlayer mediaPlayer,
    ZegoMediaPlayerFirstFrameEvent event,
  ) {
    ZegoLoggerService.logInfo(
      'onMediaPlayerFirstFrameEvent $event',
      tag: 'uikit core data',
      subTag: 'media',
    );
  }

  void onRemoteMediaTypeUpdate(String streamID, int remoteMediaType) {
    ZegoLoggerService.logInfo(
      'onRemoteMediaTypeUpdate $remoteMediaType',
      tag: 'uikit core data',
      subTag: 'media',
    );

    typeNotifier.value = ZegoUIKitMediaType.values[remoteMediaType];
  }

  void onMediaPlayerStreamStateUpdated(
    String streamID,
    ZegoPlayerState state,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    if (ZegoPlayerState.NoPlay == state) {
      stateNotifier.value = ZegoUIKitMediaPlayState.playEnded;
      stateNotifier.value = ZegoUIKitMediaPlayState.noPlay;
    }
  }

  void onMediaPlayerRecvSEIFromSDK(
    String streamID,
    String userID,
    Map<String, dynamic> sei,
  ) {
    _ownerID ??= ZegoUIKitCore.shared.coreData.streamDic[streamID] ?? '';
    final isLocalMedia = _ownerID == ZegoUIKitCore.shared.coreData.localUser.id;

    if (sei.keys.contains(ZegoUIKitSEIDefines.keyMediaStatus)) {
      final playState = ZegoUIKitMediaPlayState
          .values[sei[ZegoUIKitSEIDefines.keyMediaStatus] as int];
      if (isLocalMedia) {
        /// remote user control local media
        switch (playState) {
          case ZegoUIKitMediaPlayState.noPlay:
          case ZegoUIKitMediaPlayState.loadReady:
            break;
          case ZegoUIKitMediaPlayState.playing:
            resume();
            break;
          case ZegoUIKitMediaPlayState.pausing:
            pause();
            break;
          case ZegoUIKitMediaPlayState.playEnded:
            stop();
            break;
        }
      } else {
        /// sync media owner play state by remote
        stateNotifier.value = playState;
      }
    }

    if (sei.keys.contains(ZegoUIKitSEIDefines.keyMediaProgress)) {
      final progress = sei[ZegoUIKitSEIDefines.keyMediaProgress] as int? ?? 0;
      if (isLocalMedia) {
        /// remote user control local media
        seekTo(progress);
      } else {
        progressNotifier.value = progress;
      }
    }

    if (sei.keys.contains(ZegoUIKitSEIDefines.keyMediaDuration)) {
      final duration = sei[ZegoUIKitSEIDefines.keyMediaDuration] as int? ?? 0;
      if (!isLocalMedia) {
        _duration = duration;
      }
    }

    if (sei.keys.contains(ZegoUIKitSEIDefines.keyMediaSoundLevel)) {
      final soundLevel =
          sei[ZegoUIKitSEIDefines.keyMediaSoundLevel] as double? ?? 0.0;
      if (!isLocalMedia) {
        final targetUserIndex = ZegoUIKitCore.shared.coreData.remoteUsersList
            .indexWhere((user) => _ownerID == user.id);
        if (-1 != targetUserIndex) {
          final targetUser =
              ZegoUIKitCore.shared.coreData.remoteUsersList[targetUserIndex];
          targetUser.auxChannel.soundLevel?.add(soundLevel);
        }
      }
    }
  }

  Future<List<PlatformFile>> pickMediaFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    ZegoLoggerService.logInfo(
      'pick media files, '
      'allowMultiple:$allowMultiple, '
      'allowedExtensions:$allowedExtensions',
      tag: 'uikit core data',
      subTag: 'media',
    );

    try {
      await requestPermission(Permission.storage);
      final pickFilesResult = (await FilePicker.platform.pickFiles(
            type: null == allowedExtensions ? FileType.media : FileType.custom,
            allowMultiple: allowMultiple,
            allowedExtensions: allowedExtensions,
            onFileLoading: (p0) {
              ZegoLoggerService.logInfo(
                'pick files onFileLoading:$p0,${DateTime.now().millisecondsSinceEpoch}',
                tag: 'uikit core data',
                subTag: 'media',
              );
            },
          ))
              ?.files ??
          [];
      ZegoLoggerService.logInfo(
        'pick files: $pickFilesResult, ${DateTime.now().millisecondsSinceEpoch}',
        tag: 'uikit core data',
        subTag: 'media',
      );
      return pickFilesResult;
    } on PlatformException catch (e) {
      ZegoLoggerService.logInfo(
        'pick files Unsupported operation $e',
        tag: 'uikit core data',
        subTag: 'media',
      );

      ZegoUIKitCore.shared.error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.mediaPickFilesError,
        message: 'exception:$e',
        method: 'pickMediaFiles',
      ));
    } catch (e) {
      ZegoLoggerService.logInfo(
        'pick files exception:$e',
        tag: 'uikit core data',
        subTag: 'media',
      );

      ZegoUIKitCore.shared.error.errorStreamCtrl?.add(ZegoUIKitError(
        code: ZegoUIKitErrorCode.mediaPickFilesError,
        message: 'exception:$e',
        method: 'pickMediaFiles',
      ));
    }

    return [];
  }

  Future<void> _updatePlayStateWithSync(
      ZegoUIKitMediaPlayState playState) async {
    stateNotifier.value = playState;

    await _syncMediaInfoBySEI();
  }
}
