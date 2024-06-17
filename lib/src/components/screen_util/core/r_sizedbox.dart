// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Project imports:
import 'package:zego_uikit/src/components/screen_util/core/size_extension.dart';

/// @nodoc
class ZegoRSizedBox extends SizedBox {
  const ZegoRSizedBox({
    Key? key,
    double? height,
    double? width,
    Widget? child,
  })  : _square = false,
        super(key: key, child: child, width: width, height: height);

  const ZegoRSizedBox.zVertical(
    double? height, {
    Key? key,
    Widget? child,
  })  : _square = false,
        super(key: key, child: child, height: height);

  const ZegoRSizedBox.zHorizontal(
    double? width, {
    Key? key,
    Widget? child,
  })  : _square = false,
        super(key: key, child: child, width: width);

  const ZegoRSizedBox.zSquare({
    Key? key,
    double? height,
    double? dimension,
    Widget? child,
  })  : _square = true,
        super.square(key: key, child: child, dimension: dimension);

  ZegoRSizedBox.fromSize({
    Key? key,
    Size? size,
    Widget? child,
  })  : _square = false,
        super.fromSize(key: key, child: child, size: size);

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      additionalConstraints: _additionalConstraints,
    );
  }

  final bool _square;

  BoxConstraints get _additionalConstraints {
    final boxConstraints =
        BoxConstraints.tightFor(width: width, height: height);
    return _square ? boxConstraints.zR : boxConstraints.zHW;
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = _additionalConstraints;
  }
}
