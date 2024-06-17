// Flutter imports:
import 'package:flutter/services.dart';

// Package imports:
import 'package:native_device_orientation/native_device_orientation.dart';

/// @nodoc
DeviceOrientation deviceOrientationMap(NativeDeviceOrientation nativeValue) {
  final deviceOrientationMap = <NativeDeviceOrientation, DeviceOrientation>{
    NativeDeviceOrientation.portraitUp: DeviceOrientation.portraitUp,
    NativeDeviceOrientation.portraitDown: DeviceOrientation.portraitDown,
    NativeDeviceOrientation.landscapeLeft: DeviceOrientation.landscapeLeft,
    NativeDeviceOrientation.landscapeRight: DeviceOrientation.landscapeRight,
    NativeDeviceOrientation.unknown: DeviceOrientation.portraitUp,
  };
  return deviceOrientationMap[nativeValue] ?? DeviceOrientation.portraitUp;
}
