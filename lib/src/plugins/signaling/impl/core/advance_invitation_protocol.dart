// Project imports:
import 'package:zego_uikit/zego_uikit.dart';

class AdvanceInvitationRequestData {
  AdvanceInvitationRequestData.empty();

  AdvanceInvitationRequestData({
    required this.inviter,
    required this.invitees,
    required this.type,
    required this.customData,
  });

  ZegoUIKitUser inviter = ZegoUIKitUser.empty();
  List<String> invitees = const [];
  int type = -1;
  String customData = '';

  Map<String, dynamic> toJson() => {
        'inviter': inviter,
        'invitees': invitees,
        'type': type,
        'custom_data': customData,
      };

  factory AdvanceInvitationRequestData.fromJson(Map<String, dynamic> json) {
    return AdvanceInvitationRequestData(
      inviter: ZegoUIKitUser.fromJson(
        json['inviter'] as Map<String, dynamic>? ?? {},
      ),
      invitees: List<String>.from(json['invitees']),
      type: json['type'],
      customData: json['custom_data'],
    );
  }
}

class AdvanceInvitationAcceptData {
  AdvanceInvitationAcceptData.empty();

  AdvanceInvitationAcceptData({
    required this.inviter,
    required this.customData,
  });

  /// accept invitation from [inviter]
  ZegoUIKitUser inviter = ZegoUIKitUser.empty();

  /// [invitee]'s [customData]
  String customData = '';

  Map<String, dynamic> toJson() => {
        'inviter': inviter,
        'custom_data': customData,
      };

  factory AdvanceInvitationAcceptData.fromJson(Map<String, dynamic> json) {
    return AdvanceInvitationAcceptData(
      inviter: ZegoUIKitUser.fromJson(
        json['inviter'] as Map<String, dynamic>? ?? {},
      ),
      customData: json['custom_data'],
    );
  }
}
