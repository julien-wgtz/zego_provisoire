// Package imports:
import 'package:zego_express_engine/zego_express_engine.dart';

extension ZegoMixerOutputVideoConfigExtesion on ZegoMixerOutputVideoConfig {
  String toStringX() {
    return 'ZegoMixerTask{'
        'videoCodecID, $videoCodecID, '
        'bitrate, $bitrate, '
        'encodeProfile, $encodeProfile, '
        'encodeLatency, $encodeLatency, '
        '}';
  }
}

extension ZegoMixerOutputExtesion on ZegoMixerOutput {
  String toStringX() {
    return 'ZegoMixerOutput{'
        'target:$target, '
        'videoConfig:${videoConfig?.toStringX()}, '
        '}';
  }
}

extension ZegoMixerTaskExtesion on ZegoMixerTask {
  String toStringX() {
    return 'ZegoMixerTask{'
        'taskID:$taskID, '
        'audioConfig:${audioConfig.toMap()}, '
        'videoConfig:${videoConfig.toMap()}, '
        'inputList:${inputList.map((e) => e.toMap())}, '
        'outputList:${outputList.map((e) => e.toStringX())}, '
        'watermark:${watermark.toMap()}, '
        'whiteboard:${whiteboard.toMap()}, '
        'backgroundColor:$backgroundColor, '
        'backgroundImageURL:$backgroundImageURL, '
        'enableSoundLevel:$enableSoundLevel, '
        'streamAlignmentMode:$streamAlignmentMode, '
        'userData:$userData, '
        'advancedConfig:$advancedConfig, '
        'minPlayStreamBufferLength:$minPlayStreamBufferLength, '
        '}';
  }
}

extension ZegoMixerStartResultExtesion on ZegoMixerStartResult {
  String toStringX() {
    return 'ZegoMixerStartResult{'
        'errorCode:$errorCode, '
        'extendedData:$extendedData, '
        '}';
  }
}
