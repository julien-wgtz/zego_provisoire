// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:zego_express_engine/zego_express_engine.dart';

// Project imports:
import 'package:zego_uikit/src/services/defines/user.dart';

/// in-room message send state
enum ZegoInRoomMessageState {
  idle,
  sending,
  success,
  failed,
}

/// in-room message
class ZegoInRoomMessage {
  /// If the local message sending fails, then the message ID at this time is unreliable, and is a negative sequential value.
  int messageID;

  /// message sender.
  ZegoUIKitUser user;

  /// message content.
  String message;

  /// message attributes
  Map<String, String> attributes;

  /// The timestamp at which the message was sent.
  /// You can format the timestamp, which is in milliseconds since epoch, using DateTime.fromMillisecondsSinceEpoch(timestamp).
  int timestamp;

  ///
  var state =
      ValueNotifier<ZegoInRoomMessageState>(ZegoInRoomMessageState.success);

  ZegoInRoomMessage({
    required this.user,
    required this.message,
    required this.timestamp,
    required this.messageID,
    this.attributes = const {},
  }) {
    try {
      /// {'msg':'xxx', 'attrs':''}
      var jsonMap = jsonDecode(message);
      message = jsonMap[messageKey]!;
      attributes = Map.from(jsonMap[attributesKey]!);
    } catch (e) {
      attributes = {};
    }
  }

  ZegoInRoomMessage.fromBroadcastMessage(ZegoBroadcastMessageInfo message)
      : this(
          user: ZegoUIKitUser.fromZego(message.fromUser),
          message: message.message,
          timestamp: message.sendTime,
          messageID: message.messageID,
        );

  static String get messageKey => 'msg';

  static String get attributesKey => 'attrs';

  static String jsonBody({
    /// message content.
    required String message,

    /// message attributes
    required Map<String, String> attributes,
  }) {
    if (attributes.isEmpty) {
      return message;
    }

    /// {'msg':'xxx', 'attrs':''}
    return jsonEncode({
      messageKey: message,
      attributesKey: attributes,
    });
  }

  @override
  String toString() {
    return '{id:$messageID, user:$user message:$message, timestamp:$timestamp}';
  }
}