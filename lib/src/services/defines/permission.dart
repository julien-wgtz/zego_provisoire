// Package imports:
import 'package:permission_handler/permission_handler.dart';

// Project imports:
import 'package:zego_uikit/src/services/uikit_service.dart';

Future<bool> requestPermission(Permission permission) async {
  PermissionStatus? status;
  try {
    status = await permission.request();
  } catch (e) {
    ZegoLoggerService.logInfo(
      'Exception: $permission permission not granted, $e',
      tag: 'uikit',
      subTag: 'permission',
    );
  }

  if (status != PermissionStatus.granted) {
    ZegoLoggerService.logInfo(
      'Error: $permission permission not granted, $status',
      tag: 'uikit',
      subTag: 'permission',
    );
    return false;
  }

  return true;
}
