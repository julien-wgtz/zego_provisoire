// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/services.dart';

// Package imports:
import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';

// Project imports:
import 'package:zego_uikit/src/plugins/signaling/defines.dart';
import 'package:zego_uikit/src/plugins/signaling/impl/core/advance_invitation_protocol.dart';
import 'package:zego_uikit/src/plugins/signaling/impl/core/core.dart';
import 'package:zego_uikit/src/plugins/signaling/impl/core/defines.dart';
import 'package:zego_uikit/src/services/services.dart';

/// @nodoc
mixin ZegoPluginInvitationServiceAdvance {
  /// send invitation to one or more specified users
  /// [invitees] list of invitees.
  /// [timeout] timeout of the call invitation, the unit is seconds
  /// [type] call type
  /// [data] extended field, through which the inviter can carry information to the invitee.
  Future<ZegoSignalingPluginSendInvitationResult> sendAdvanceInvitation({
    required String inviterID,
    required String inviterName,
    required List<String> invitees,
    required int timeout,
    required int type,
    required String data,
    ZegoNotificationConfig? zegoNotificationConfig,
  }) async {
    invitees.removeWhere((item) => ['', null].contains(item));
    if (invitees.isEmpty) {
      ZegoLoggerService.logError(
        'invitees is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return const ZegoSignalingPluginSendInvitationResult(
        invitationID: '',
        errorInvitees: {},
      );
    }

    final zimExtendedData = jsonEncode(AdvanceInvitationRequestData(
      inviter: ZegoUIKitUser(id: inviterID, name: inviterName),
      invitees: invitees,
      type: type,
      customData: data,
    ));

    ZegoSignalingPluginPushConfig? pluginPushConfig;
    if (ZegoSignalingPluginCore
            .shared.coreData.notifyWhenAppIsInTheBackgroundOrQuit &&
        (zegoNotificationConfig?.notifyWhenAppIsInTheBackgroundOrQuit ??
            false)) {
      pluginPushConfig = ZegoSignalingPluginPushConfig(
        resourceID: zegoNotificationConfig!.resourceID,
        title: zegoNotificationConfig.title,
        message: zegoNotificationConfig.message,
        payload: zimExtendedData,
        voipConfig: ZegoSignalingPluginVoIPConfig(
          iOSVoIPHasVideo:
              zegoNotificationConfig.voIPConfig?.iOSVoIPHasVideo ?? false,
        ),
      );
    }

    ZegoLoggerService.logInfo(
      'send invitation, '
      'invitees:$invitees, timeout:$timeout, type:$type, '
      'zimExtendedData:$zimExtendedData, '
      'notification config:$zegoNotificationConfig',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    return ZegoSignalingPluginCore.shared.coreData.advanceInvite(
      invitees: invitees,
      type: type,
      timeout: timeout,
      extendedData: zimExtendedData,
      kitData: data,
      pushConfig: pluginPushConfig,
    );
  }

  ///
  Future<ZegoSignalingPluginSendInvitationResult> addAdvanceInvitation({
    required String inviterID,
    required String inviterName,
    required List<String> invitees,
    required int type,
    required String data,
    String? invitationID,
    ZegoNotificationConfig? zegoNotificationConfig,
  }) async {
    invitees.removeWhere((item) => ['', null].contains(item));
    if (invitees.isEmpty) {
      ZegoLoggerService.logError(
        'invitees is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return const ZegoSignalingPluginSendInvitationResult(
        invitationID: '',
        errorInvitees: {},
      );
    }

    final zimExtendedData = jsonEncode(AdvanceInvitationRequestData(
      inviter: ZegoUIKitUser(id: inviterID, name: inviterName),
      invitees: invitees,
      type: type,
      customData: data,
    ));

    ZegoSignalingPluginPushConfig? pluginPushConfig;
    if (ZegoSignalingPluginCore
            .shared.coreData.notifyWhenAppIsInTheBackgroundOrQuit &&
        (zegoNotificationConfig?.notifyWhenAppIsInTheBackgroundOrQuit ??
            false)) {
      pluginPushConfig = ZegoSignalingPluginPushConfig(
        resourceID: zegoNotificationConfig!.resourceID,
        title: zegoNotificationConfig.title,
        message: zegoNotificationConfig.message,
        payload: zimExtendedData,
        voipConfig: ZegoSignalingPluginVoIPConfig(
          iOSVoIPHasVideo:
              zegoNotificationConfig.voIPConfig?.iOSVoIPHasVideo ?? false,
        ),
      );
    }

    var targetInvitationID = invitationID;
    if (targetInvitationID?.isEmpty ?? true) {
      Map<String, dynamic>? extendedDataMap;
      try {
        extendedDataMap = jsonDecode(data) as Map<String, dynamic>?;
      } catch (e) {
        ZegoLoggerService.logError(
          'add invitation, data is not a json:$data',
          tag: 'uikit',
          subTag: 'signaling advance invitation service',
        );
      } finally {
        if (extendedDataMap?.containsKey('invitation_id') ?? false) {
          targetInvitationID = extendedDataMap!['invitation_id']! as String;
        } else {
          targetInvitationID = ZegoSignalingPluginCore.shared.coreData
              .queryInvitationIDByInviterID(inviterID);
        }
      }
    }
    if (targetInvitationID?.isEmpty ?? true) {
      ZegoLoggerService.logError(
        'add invitation, invitationID is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return ZegoSignalingPluginSendInvitationResult(
        error: PlatformException(code: '-1', message: 'invitationID is empty'),
        invitationID: '',
        errorInvitees: {},
      );
    }

    ZegoLoggerService.logInfo(
      'add invitation: '
      'invitationID:$targetInvitationID, '
      'invitees:$invitees, type:$type, '
      'zimExtendedData:$zimExtendedData, '
      'notification config:$zegoNotificationConfig',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    return ZegoSignalingPluginCore.shared.coreData.advanceAddInvite(
      invitationID: targetInvitationID!,
      invitees: invitees,
      type: type,
      extendedData: data,
      pushConfig: pluginPushConfig,
    );
  }

  /// join invitation
  Future<ZegoSignalingPluginJoinInvitationResult> joinAdvanceInvitation({
    required String invitationID,
    String? data,
  }) async {
    if (invitationID.isEmpty) {
      ZegoLoggerService.logError(
        'invitationID is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return ZegoSignalingPluginJoinInvitationResult(
        error: PlatformException(code: '-1', message: 'invitationID is empty'),
        invitationID: '',
      );
    }

    ZegoLoggerService.logInfo(
      'join invitation: '
      'invitationID:$invitationID, ',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    return ZegoSignalingPluginCore.shared.coreData.advanceJoinInvite(
      invitationID: invitationID,
      extendedData: data ?? '',
    );
  }

  /// cancel invitation to one or more specified users
  /// [inviteeID] invitee's id
  /// [data] extended field
  Future<ZegoSignalingPluginCancelInvitationResult> cancelAdvanceInvitation({
    required List<String> invitees,
    required String data,
    String? invitationID,
  }) async {
    invitees.removeWhere((item) => ['', null].contains(item));
    if (invitees.isEmpty) {
      ZegoLoggerService.logError(
        'invitees is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return ZegoSignalingPluginCancelInvitationResult(
        error: PlatformException(code: '', message: ''),
        errorInvitees: <String>[],
      );
    }

    var targetInvitationID = invitationID;
    if (targetInvitationID?.isEmpty ?? true) {
      Map<String, dynamic>? extendedDataMap;
      try {
        extendedDataMap = jsonDecode(data) as Map<String, dynamic>?;
      } catch (e) {
        ZegoLoggerService.logError(
          'cancel invitation, data is not a json:$data',
          tag: 'uikit',
          subTag: 'signaling advance invitation service',
        );
      } finally {
        if (extendedDataMap?.containsKey('invitation_id') ?? false) {
          targetInvitationID = extendedDataMap!['invitation_id']! as String;
        } else {
          targetInvitationID = ZegoSignalingPluginCore.shared.coreData
              .queryInvitationIDByInvitees(invitees);
        }
      }
    }
    if (targetInvitationID?.isEmpty ?? true) {
      ZegoLoggerService.logError(
        'cancel invitation, invitationID is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return ZegoSignalingPluginCancelInvitationResult(
        error: PlatformException(code: '-1', message: 'invitationID is empty'),
        errorInvitees: invitees,
      );
    }

    final pushConfig = ZegoSignalingPluginIncomingInvitationCancelPushConfig(
      resourcesID: ZegoSignalingPluginCore.shared.coreData
          .queryAdvanceResourceIDByInvitationID(
        targetInvitationID!,
      ),
      payload: data,
    );

    ZegoLoggerService.logInfo(
      'cancel invitation: '
      'invitationID:$invitationID, '
      'invitees:$invitees, '
      'data:$data, '
      'pushConfig:$pushConfig',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    return ZegoSignalingPluginCore.shared.coreData.advanceCancel(
      invitees,
      targetInvitationID,
      data,
      pushConfig,
    );
  }

  /// invitee reject the call invitation
  /// [inviterID] inviter id, who send invitation
  /// [data] extended field, you can include your reasons such as Declined
  Future<ZegoSignalingPluginResponseInvitationResult> refuseAdvanceInvitation({
    required String inviterID,
    required String data,
    String? invitationID,
  }) async {
    var targetInvitationID = invitationID;
    if (targetInvitationID?.isEmpty ?? true) {
      Map<String, dynamic>? extendedDataMap;
      try {
        extendedDataMap = jsonDecode(data) as Map<String, dynamic>?;
      } catch (e) {
        ZegoLoggerService.logError(
          'refuse invitation, data is not a json:$data',
          tag: 'uikit',
          subTag: 'signaling advance invitation service',
        );
      } finally {
        if (extendedDataMap?.containsKey('invitation_id') ?? false) {
          targetInvitationID = extendedDataMap!['invitation_id']! as String;
        } else {
          targetInvitationID = ZegoSignalingPluginCore.shared.coreData
              .queryAdvanceInvitationIDByInitiatorID(
            inviterID,
          );
        }
      }
    }

    if (targetInvitationID?.isEmpty ?? true) {
      ZegoLoggerService.logError(
        'refuse invitation, invitationID is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return const ZegoSignalingPluginResponseInvitationResult();
    }

    ZegoLoggerService.logInfo(
      'refuse invitation, '
      'invitationID:$targetInvitationID, '
      'inviter id:$inviterID, '
      'data:$data',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    return ZegoSignalingPluginCore.shared.coreData.advanceReject(
      targetInvitationID!,
      data,
    );
  }

  Future<ZegoSignalingPluginResponseInvitationResult>
      refuseInvitationByInvitationID({
    required String invitationID,
    required String data,
  }) async {
    ZegoLoggerService.logInfo(
      'refuse invitation, '
      'invitationID:$invitationID, data:$data',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    if (invitationID.isEmpty) {
      ZegoLoggerService.logError(
        'invitationID is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return const ZegoSignalingPluginResponseInvitationResult();
    }

    return ZegoSignalingPluginCore.shared.coreData.advanceReject(
      invitationID,
      data,
    );
  }

  /// invitee accept the call invitation
  /// [inviterID] inviter id, who send invitation
  /// [data] extended field
  Future<ZegoSignalingPluginResponseInvitationResult> acceptAdvanceInvitation({
    required String inviterID,
    required String inviterName,
    required String data,
    String? invitationID,
  }) async {
    final targetInvitationID = invitationID ??
        ZegoSignalingPluginCore.shared.coreData
            .queryAdvanceInvitationIDByInitiatorID(
          inviterID,
        );
    ZegoLoggerService.logInfo(
      'accept invitation: '
      'invitationID:$targetInvitationID, '
      'inviter id:$inviterID, '
      'inviter name:$inviterName, '
      'data:$data, ',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    if (targetInvitationID.isEmpty) {
      ZegoLoggerService.logError(
        'invitationID is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return const ZegoSignalingPluginResponseInvitationResult();
    }

    return ZegoSignalingPluginCore.shared.coreData.advanceAccept(
      targetInvitationID,
      jsonEncode(AdvanceInvitationAcceptData(
        inviter: ZegoUIKitUser(id: inviterID, name: inviterName),
        customData: data,
      )),
    );
  }

  ///
  Future<ZegoSignalingPluginEndInvitationResult> endAdvanceInvitation({
    required String data,
    String? invitationID,
    ZegoNotificationConfig? zegoNotificationConfig,
  }) async {
    final zimExtendedData = const JsonEncoder().convert({
      'data': data,
    });

    ZegoSignalingPluginPushConfig? pluginPushConfig;
    if (ZegoSignalingPluginCore
            .shared.coreData.notifyWhenAppIsInTheBackgroundOrQuit &&
        (zegoNotificationConfig?.notifyWhenAppIsInTheBackgroundOrQuit ??
            false)) {
      pluginPushConfig = ZegoSignalingPluginPushConfig(
        resourceID: zegoNotificationConfig!.resourceID,
        title: zegoNotificationConfig.title,
        message: zegoNotificationConfig.message,
        payload: zimExtendedData,
        voipConfig: ZegoSignalingPluginVoIPConfig(
          iOSVoIPHasVideo:
              zegoNotificationConfig.voIPConfig?.iOSVoIPHasVideo ?? false,
        ),
      );
    }

    var targetInvitationID = invitationID;
    if (targetInvitationID?.isEmpty ?? true) {
      Map<String, dynamic>? extendedDataMap;
      try {
        extendedDataMap = jsonDecode(data) as Map<String, dynamic>?;
      } catch (e) {
        ZegoLoggerService.logError(
          'end invitation, data is not a json:$data',
          tag: 'uikit',
          subTag: 'signaling advance invitation service',
        );
      } finally {
        if (extendedDataMap?.containsKey('invitation_id') ?? false) {
          targetInvitationID = extendedDataMap!['invitation_id']! as String;
        }
      }
    }
    if (targetInvitationID?.isEmpty ?? true) {
      ZegoLoggerService.logError(
        'end invitation, invitationID is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return const ZegoSignalingPluginEndInvitationResult(
        invitationID: '',
      );
    }

    ZegoLoggerService.logInfo(
      'end invitation, '
      'invitationID:$targetInvitationID, '
      'zimExtendedData:$zimExtendedData, '
      'notification config:$zegoNotificationConfig',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    return ZegoSignalingPluginCore.shared.coreData.advanceEnd(
      targetInvitationID!,
      data,
      pluginPushConfig,
    );
  }

  ///
  Future<ZegoSignalingPluginQuitInvitationResult> quitAdvanceInvitation({
    required String data,
    String? invitationID,
    ZegoNotificationConfig? zegoNotificationConfig,
  }) async {
    final zimExtendedData = const JsonEncoder().convert({
      'data': data,
    });

    ZegoSignalingPluginPushConfig? pluginPushConfig;
    if (ZegoSignalingPluginCore
            .shared.coreData.notifyWhenAppIsInTheBackgroundOrQuit &&
        (zegoNotificationConfig?.notifyWhenAppIsInTheBackgroundOrQuit ??
            false)) {
      pluginPushConfig = ZegoSignalingPluginPushConfig(
        resourceID: zegoNotificationConfig!.resourceID,
        title: zegoNotificationConfig.title,
        message: zegoNotificationConfig.message,
        payload: zimExtendedData,
        voipConfig: ZegoSignalingPluginVoIPConfig(
          iOSVoIPHasVideo:
              zegoNotificationConfig.voIPConfig?.iOSVoIPHasVideo ?? false,
        ),
      );
    }

    var targetInvitationID = invitationID;
    if (targetInvitationID?.isEmpty ?? true) {
      Map<String, dynamic>? extendedDataMap;
      try {
        extendedDataMap = jsonDecode(data) as Map<String, dynamic>?;
      } catch (e) {
        ZegoLoggerService.logInfo(
          'quit invitation, data is not a json:$data',
          tag: 'uikit',
          subTag: 'signaling advance invitation service',
        );
      } finally {
        if (extendedDataMap?.containsKey('invitation_id') ?? false) {
          targetInvitationID = extendedDataMap!['invitation_id']! as String;
        }
      }
    }
    if (targetInvitationID?.isEmpty ?? true) {
      ZegoLoggerService.logError(
        '[Error] quit invitation, invitationID is empty',
        tag: 'uikit',
        subTag: 'signaling advance invitation service',
      );
      return const ZegoSignalingPluginQuitInvitationResult(
        invitationID: '',
      );
    }

    ZegoLoggerService.logInfo(
      'quit invitation, '
      'invitationID:$targetInvitationID, '
      'zimExtendedData:$zimExtendedData, '
      'notification config:$zegoNotificationConfig',
      tag: 'uikit',
      subTag: 'signaling advance invitation service',
    );

    return ZegoSignalingPluginCore.shared.coreData.advanceQuit(
      targetInvitationID!,
      data,
      pluginPushConfig,
    );
  }

  List<AdvanceInvitationUser> getAdvanceInvitees(String invitationID) {
    return ZegoSignalingPluginCore.shared.coreData
        .getAdvanceInvitees(invitationID);
  }

  /// a->b, b->c;
  /// in c event, a is initiator, b is inviter
  AdvanceInvitationUser? getAdvanceInitiator(String invitationID) {
    return ZegoSignalingPluginCore.shared.coreData
        .getAdvanceInitiator(invitationID);
  }

  bool isUserInAdvanceInvitationNow(String userID) {
    return ZegoSignalingPluginCore.shared.coreData
        .isUserInAdvanceInvitationNow(userID);
  }

  String advanceInvitationToString() {
    return ZegoSignalingPluginCore.shared.coreData.advanceInvitationToString();
  }

  /// stream callback, Listen for calling user status changes.
  /// When to call: After the call invitation is initiated, the calling member accepts, rejects, or exits, or the response times out, the current calling inviting member receives this callback.
  /// Note: If the user is not the inviter who initiated this call invitation or is not online, the callback will not be received.
  Stream<ZegoSignalingPluginInvitationUserStateChangedEvent>
      getAdvanceInvitationUserStateChangedStream() {
    return ZegoSignalingPluginCore.shared.coreData
            .streamCtrlAdvanceInvitationUserStateChanged?.stream ??
        const Stream.empty();
  }

  /// stream callback, notify invitee when call invitation received
  Stream<Map<String, dynamic>> getAdvanceInvitationReceivedStream() {
    return ZegoSignalingPluginCore
            .shared.coreData.streamCtrlAdvanceInvitationReceived?.stream ??
        const Stream.empty();
  }

  /// stream callback, notify invitee if invitation timeout
  Stream<Map<String, dynamic>> getAdvanceInvitationTimeoutStream() {
    return ZegoSignalingPluginCore
            .shared.coreData.streamCtrlAdvanceInvitationTimeout?.stream ??
        const Stream.empty();
  }

  /// stream callback, notify when call invitation cancelled by inviter
  Stream<Map<String, dynamic>> getAdvanceInvitationCanceledStream() {
    return ZegoSignalingPluginCore
            .shared.coreData.streamCtrlAdvanceInvitationCanceled?.stream ??
        const Stream.empty();
  }

  /// stream callback, notify when call ended by inviter
  Stream<Map<String, dynamic>> getAdvanceInvitationEndedStream() {
    return ZegoSignalingPluginCore
            .shared.coreData.streamCtrlAdvanceInvitationEnded?.stream ??
        const Stream.empty();
  }
}
