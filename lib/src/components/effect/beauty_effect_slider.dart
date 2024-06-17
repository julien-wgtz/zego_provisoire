// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zego_uikit/src/components/screen_util/screen_util.dart';
import 'package:zego_uikit/src/services/services.dart';

/// @nodoc
class ZegoBeautyEffectSlider extends StatefulWidget {
  final BeautyEffectType effectType;
  final int defaultValue;

  final double? thumpHeight;
  final double? trackHeight;
  final String Function(int)? labelFormatFunc;

  /// the style of the text displayed on the Slider's thumb
  final TextStyle? textStyle;

  /// the background color of the text displayed on the Slider's thumb.
  final Color? textBackgroundColor;

  ///  the color of the track that is active when sliding the Slider.
  final Color? activeTrackColor;

  /// the color of the track that is inactive when sliding the Slider.
  final Color? inactiveTrackColor;

  /// the color of the Slider's thumb.
  final Color? thumbColor;

  /// the radius of the Slider's thumb.
  final double? thumbRadius;

  const ZegoBeautyEffectSlider({
    Key? key,
    required this.effectType,
    required this.defaultValue,
    this.thumpHeight,
    this.trackHeight,
    this.labelFormatFunc,
    this.textStyle,
    this.textBackgroundColor,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.thumbRadius,
  }) : super(key: key);

  @override
  State<ZegoBeautyEffectSlider> createState() => _ZegoBeautyEffectSliderState();
}

/// @nodoc
class _ZegoBeautyEffectSliderState extends State<ZegoBeautyEffectSlider> {
  var valueNotifier = ValueNotifier<int>(50);

  @override
  void initState() {
    super.initState();

    valueNotifier.value = widget.defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    valueNotifier.value = widget.defaultValue;

    final thumpHeight = widget.thumpHeight ?? 32.zH;
    return SizedBox(
      width: 480.zW,
      height: thumpHeight,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          valueIndicatorTextStyle: widget.textStyle ??
              TextStyle(
                color: const Color(0xff1B1A1C),
                fontSize: 30.zR,
                fontWeight: FontWeight.w400,
              ),
          valueIndicatorColor:
              widget.textBackgroundColor ?? Colors.white.withOpacity(0.5),
          activeTrackColor: widget.activeTrackColor ?? Colors.white,
          inactiveTrackColor: widget.inactiveTrackColor ??
              const Color(0xff000000).withOpacity(0.3),
          trackHeight: widget.trackHeight ?? 6.0.zR,
          thumbColor: widget.thumbColor ?? Colors.white,
          thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: widget.thumbRadius ?? thumpHeight / 2.0),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: valueNotifier,
          builder: (context, value, _) {
            return Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: widget.labelFormatFunc == null
                  ? value.toDouble().round().toString()
                  : widget.labelFormatFunc?.call(value),
              onChanged: (double defaultValue) {
                valueNotifier.value = defaultValue.toInt();

                ZegoUIKit()
                    .setBeautifyValue(defaultValue.toInt(), widget.effectType);
              },
            );
          },
        ),
      ),
    );
  }
}
