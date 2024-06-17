// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zego_uikit/src/services/internal/core/core.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// You can use this control to play audio or video.
///
/// You can directly specify the file to be played using [filePathOrURL].
///
/// If you want to specify the allowed formats, you can set them using [allowedExtensions].
/// Currently, for video, we support "avi", "flv", "mkv", "mov", "mp4", "mpeg", "webm", "wmv".
/// For audio, we support "aac", "midi", "mp3", "ogg", "wav".
class ZegoUIKitMediaPlayer extends StatefulWidget {
  const ZegoUIKitMediaPlayer({
    Key? key,
    required this.size,
    this.canControl = true,
    this.showSurface = true,
    this.autoStart = true,
    this.isMovable = true,
    this.autoHideSurface = true,
    this.hideSurfaceSecond = 3,
    this.enableRepeat = false,
    this.isPlayButtonCentral = true,
    this.filePathOrURL,
    this.allowedExtensions,
    this.initPosition,
    this.closeIcon,
    this.moreIcon,
    this.playIcon,
    this.pauseIcon,
    this.volumeIcon,
    this.volumeMuteIcon,
    this.durationTextStyle,
    this.onPlayStateChanged,
  }) : super(key: key);

  final Size size;

  /// load the absolute path to the local resource or the URL of the network resource
  /// is null, will pop-up and pick files from local
  final String? filePathOrURL;
  final List<String>? allowedExtensions;

  final bool canControl;
  final bool enableRepeat;
  final bool autoStart;

  final bool isMovable;
  final Offset? initPosition;
  final bool isPlayButtonCentral;

  final bool showSurface;
  final bool autoHideSurface;
  final int hideSurfaceSecond;

  /// style
  final Widget? closeIcon;
  final Widget? moreIcon;
  final Widget? playIcon;
  final Widget? pauseIcon;
  final Widget? volumeIcon;
  final Widget? volumeMuteIcon;
  final TextStyle? durationTextStyle;

  final void Function(ZegoUIKitMediaPlayState)? onPlayStateChanged;

  @override
  State<StatefulWidget> createState() => _ZegoUIKitMediaPlayerState();
}

class _ZegoUIKitMediaPlayerState extends State<ZegoUIKitMediaPlayer> {
  final showVolumeSliderNotifier = ValueNotifier<bool>(false);
  final surfaceVisibilityNotifier = ValueNotifier<bool>(true);

  Offset? topLeft;

  Timer? hideSurfaceTimer;

  double get spacing => 5;

  double get sliderHeight => 10;

  Size get buttonSize => const Size(20, 20);

  List<String> get allowedExtensions =>
      widget.allowedExtensions ??
      [
        /// video
        "avi",
        "flv",
        "mkv",
        "mov",
        "mp4",
        "mpeg",
        "webm",
        "wmv",

        /// audio
        "aac",
        "midi",
        "mp3",
        "ogg",
        "wav",
      ];

  @override
  void initState() {
    super.initState();

    topLeft = widget.initPosition;

    ZegoUIKit().getMediaPlayStateNotifier().addListener(onPlayStateChanged);

    if (widget.filePathOrURL?.isNotEmpty ?? false) {
      if (ZegoUIKitCore.shared.expressEngineCreatedNotifier.value) {
        autoShareMedia();
      } else {
        ZegoUIKitCore.shared.expressEngineCreatedNotifier
            .addListener(onExpressEngineCreated);

        ZegoLoggerService.logInfo(
          'express engine is not created, wait..',
          tag: 'uikit',
          subTag: 'media player',
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    hideSurfaceTimer?.cancel();

    ZegoUIKitCore.shared.expressEngineCreatedNotifier
        .removeListener(onExpressEngineCreated);

    ZegoUIKit().getMediaPlayStateNotifier().removeListener(onPlayStateChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        movable(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(4.0),
              color: Colors.black.withOpacity(0.5),
            ),
            width: widget.size.width,
            height: widget.size.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    media(),
                    surface(constraints.maxWidth, constraints.maxHeight),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget movable({required Widget child}) {
    return Positioned(
      left: topLeft?.dx ?? 10,
      top: topLeft?.dy ?? 10,
      child: widget.isMovable
          ? LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      var x = topLeft!.dx + details.delta.dx;
                      var y = topLeft!.dy + details.delta.dy;

                      x = x.clamp(
                          0.0,
                          MediaQuery.of(context).size.width -
                              widget.size.width);
                      y = y.clamp(
                          0.0,
                          MediaQuery.of(context).size.height -
                              widget.size.height);
                      topLeft = Offset(x, y);
                    });
                  },
                  child: child,
                );
              },
            )
          : child,
    );
  }

  Widget media() {
    return const Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: ZegoUIKitMediaContainer(),
    );
  }

  Widget surface(double maxViewWidth, double maxViewHeight) {
    if (!widget.showSurface) {
      return Container();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: surfaceVisibilityNotifier,
      builder: (context, surfaceVisibility, _) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (showVolumeSliderNotifier.value) {
              showVolumeSliderNotifier.value = false;
            } else {
              surfaceVisibilityNotifier.value = !surfaceVisibility;

              final playState = ZegoUIKit().getMediaPlayStateNotifier().value;
              if (ZegoUIKitMediaPlayState.noPlay == playState ||
                  ZegoUIKitMediaPlayState.playEnded == playState) {
                /// reject hide if not source playing
                surfaceVisibilityNotifier.value = true;
              }

              if (surfaceVisibilityNotifier.value) {
                if (ZegoUIKitMediaPlayState.playing == playState) {
                  startHideSurfaceTimer();
                }
              }
            }
          },
          child: Container(
            color: Colors.transparent,
            child: surfaceVisibility
                ? controls(
                    maxViewWidth,
                    maxViewHeight,
                  )
                : Container(),
          ),
        );
      },
    );
  }

  Widget controls(double maxViewWidth, double maxViewHeight) {
    return Stack(
      children: [
        ...widget.canControl
            ? [
                closeButton(),
                filePickButton(),
                if (widget.isPlayButtonCentral)
                  bigPlayButton(
                    maxViewWidth,
                    maxViewHeight,
                  )
                else
                  smallPlayButton(),
              ]
            : [],
        volumeButton(),
        volumeSlider(
          maxViewWidth,
          maxViewHeight,
        ),
        progressSlider(),
        progressDuration(),
      ],
    );
  }

  Widget progressSlider() {
    return ValueListenableBuilder<int>(
      valueListenable: ZegoUIKit().getMediaCurrentProgressNotifier(),
      builder: (context, progress, _) {
        return ValueListenableBuilder<ZegoUIKitMediaPlayState>(
          valueListenable: ZegoUIKit().getMediaPlayStateNotifier(),
          builder: (context, playState, _) {
            final duration = ZegoUIKit().getMediaTotalDuration();
            return Positioned(
              left: spacing,
              right: spacing,
              bottom: spacing,
              child: SizedBox(
                height: sliderHeight,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.0,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.0,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.5),
                    disabledThumbColor: Colors.white,
                    disabledActiveTrackColor: Colors.white,
                    disabledInactiveTrackColor: Colors.white,
                  ),
                  child: ZegoUIKitMediaPlayState.noPlay == playState
                      ? const Slider(
                          min: 0,
                          max: 1,
                          value: 0,
                          onChanged: null,
                        )
                      : Slider(
                          min: 0,
                          max: duration.toDouble(),
                          value: progress.toDouble(),
                          onChanged: widget.canControl
                              ? (double value) {
                                  ZegoUIKit().seekTo(value.toInt());
                                }
                              : null,
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget progressDuration() {
    return ValueListenableBuilder<int>(
      valueListenable: ZegoUIKit().getMediaCurrentProgressNotifier(),
      builder: (context, progress, _) {
        final duration = ZegoUIKit().getMediaTotalDuration();
        final progressDuration =
            '${durationFormatString(Duration(milliseconds: progress))} / '
            '${durationFormatString(Duration(milliseconds: duration))}';
        return Positioned(
          bottom: spacing + sliderHeight + 10 / 2,
          left: spacing + (widget.canControl ? buttonSize.width + spacing : 0),
          child: Text(
            progressDuration,
            style: widget.durationTextStyle ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
          ),
        );
      },
    );
  }

  String durationFormatString(Duration elapsedTime) {
    final hours = elapsedTime.inHours;
    final minutes = elapsedTime.inMinutes.remainder(60);
    final seconds = elapsedTime.inSeconds.remainder(60);

    final minutesFormatString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:$minutesFormatString'
        : minutesFormatString;
  }

  Widget volumeButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: ZegoUIKit().getMediaMuteNotifier(),
      builder: (context, isMute, _) {
        return Positioned(
          bottom: spacing + sliderHeight + spacing,
          right: spacing,
          child: GestureDetector(
            onTap: () {
              ZegoUIKit().muteMediaLocal(!isMute);
            },
            onLongPress: widget.canControl
                ? () {
                    showVolumeSliderNotifier.value =
                        !showVolumeSliderNotifier.value;
                  }
                : null,
            child: SizedBox(
              width: buttonSize.width,
              height: buttonSize.height,
              child: (isMute ? widget.volumeMuteIcon : widget.volumeIcon) ??
                  Icon(
                    isMute ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: buttonSize.width,
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget volumeSlider(double maxViewWidth, double maxViewHeight) {
    return ValueListenableBuilder<bool>(
      valueListenable: showVolumeSliderNotifier,
      builder: (context, isShowVolumeSlider, _) {
        return isShowVolumeSlider
            ? Positioned(
                bottom: spacing + sliderHeight + spacing + buttonSize.height,
                right: spacing + sliderHeight / 2,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: SizedBox(
                    width: maxViewHeight / 2,
                    height: sliderHeight,
                    child: ValueListenableBuilder<int>(
                      valueListenable: ZegoUIKit().getMediaVolumeNotifier(),
                      builder: (context, volume, _) {
                        return SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2.0,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6.0,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
                            overlayColor: Colors.yellow.withOpacity(0.4),
                            activeTrackColor: Colors.blue,
                            inactiveTrackColor: Colors.blue.withOpacity(0.5),
                          ),
                          child: Slider(
                            min: 0,
                            max: 100,
                            value: volume.toDouble(),
                            onChangeStart: widget.canControl
                                ? (double value) {
                                    hideSurfaceTimer?.cancel();
                                  }
                                : null,
                            onChangeEnd: widget.canControl
                                ? (double value) {
                                    startHideSurfaceTimer();
                                  }
                                : null,
                            onChanged: widget.canControl
                                ? (double value) {
                                    ZegoUIKit().setMediaVolume(value.toInt());
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            : Container();
      },
    );
  }

  Widget bigPlayButton(double maxViewWidth, double maxViewHeight) {
    final buttonSize = Size(maxViewWidth / 6.0, maxViewWidth / 6.0);
    return Positioned(
      bottom: (maxViewHeight - buttonSize.height) / 2,
      left: (maxViewWidth - buttonSize.height) / 2,
      child: ValueListenableBuilder<ZegoUIKitMediaPlayState>(
        valueListenable: ZegoUIKit().getMediaPlayStateNotifier(),
        builder: (context, playState, _) {
          return GestureDetector(
            onTap: () {
              onPlayButtonClick(playState);
            },
            child: SizedBox(
              width: buttonSize.width,
              height: buttonSize.height,
              child: getPlayButtonIcon(playState, buttonSize),
            ),
          );
        },
      ),
    );
  }

  Widget smallPlayButton() {
    return Positioned(
      bottom: spacing + sliderHeight + spacing,
      left: spacing,
      child: ValueListenableBuilder<ZegoUIKitMediaPlayState>(
        valueListenable: ZegoUIKit().getMediaPlayStateNotifier(),
        builder: (context, playState, _) {
          return GestureDetector(
            onTap: () {
              onPlayButtonClick(playState);
            },
            child: SizedBox(
              width: buttonSize.width,
              height: buttonSize.height,
              child: getPlayButtonIcon(playState, buttonSize),
            ),
          );
        },
      ),
    );
  }

  Widget getPlayButtonIcon(ZegoUIKitMediaPlayState playState, Size buttonSize) {
    var icon = widget.playIcon ??
        Icon(
          Icons.play_circle,
          color: Colors.white,
          size: buttonSize.width,
        );

    switch (playState) {
      case ZegoUIKitMediaPlayState.playing:
        icon = widget.pauseIcon ??
            Icon(
              Icons.pause_circle,
              color: Colors.white,
              size: buttonSize.width,
            );
        break;
      case ZegoUIKitMediaPlayState.noPlay:
      case ZegoUIKitMediaPlayState.loadReady:
      case ZegoUIKitMediaPlayState.pausing:
      case ZegoUIKitMediaPlayState.playEnded:
        icon = widget.playIcon ??
            Icon(
              Icons.play_circle,
              color: Colors.white,
              size: buttonSize.width,
            );
        break;
    }

    return icon;
  }

  Future<void> onPlayButtonClick(ZegoUIKitMediaPlayState playState) async {
    if (!widget.canControl) {
      return;
    }

    switch (playState) {
      case ZegoUIKitMediaPlayState.noPlay:
        if (widget.filePathOrURL?.isNotEmpty ?? false) {
          shareMedia(widget.filePathOrURL!);
        } else {
          pickMediaToShare();
        }
        break;
      case ZegoUIKitMediaPlayState.loadReady:
        ZegoUIKit().startMedia();
        break;
      case ZegoUIKitMediaPlayState.playing:
        ZegoUIKit().pauseMedia();
        break;
      case ZegoUIKitMediaPlayState.pausing:
        ZegoUIKit().resumeMedia();
        break;
      case ZegoUIKitMediaPlayState.playEnded:
        ZegoUIKit().startMedia();
        break;
    }
  }

  Widget closeButton() {
    return Positioned(
      top: spacing,
      left: spacing,
      child: GestureDetector(
        onTap: widget.canControl ? destroyMedia : null,
        child: SizedBox(
          width: buttonSize.width,
          height: buttonSize.height,
          child: widget.closeIcon ??
              Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: buttonSize.width,
              ),
        ),
      ),
    );
  }

  Widget filePickButton() {
    return Positioned(
      top: spacing,
      right: spacing,
      child: GestureDetector(
        onTap: widget.canControl ? pickMediaToShare : null,
        child: SizedBox(
          width: buttonSize.width,
          height: buttonSize.height,
          child: widget.moreIcon ??
              Icon(
                Icons.more_vert,
                color: Colors.white,
                size: buttonSize.width,
              ),
        ),
      ),
    );
  }

  Future<void> destroyMedia() async {
    await ZegoUIKit().destroyMedia();
  }

  Future<void> pickMediaToShare() async {
    final files = await ZegoUIKit().pickMediaFile(
      allowedExtensions: allowedExtensions,
    );
    if (files.isEmpty) {
      ZegoLoggerService.logInfo(
        'files is empty',
        tag: 'uikit',
        subTag: 'media player',
      );
    } else {
      shareMedia(files.first.path ?? '');
    }
  }

  Future<void> shareMedia(String targetPathOrURL) async {
    if (!widget.canControl) {
      return;
    }

    if (targetPathOrURL.isEmpty) {
      return;
    }

    final shareResult = await ZegoUIKit().playMedia(
      filePathOrURL: targetPathOrURL,
      enableRepeat: widget.enableRepeat,
      autoStart: widget.autoStart,
    );
    if (0 != shareResult.errorCode) {
      ZegoLoggerService.logInfo(
        'share media failed:${shareResult.errorCode}',
        tag: 'uikit',
        subTag: 'media player',
      );
    }
  }

  void onPlayStateChanged() {
    final playState = ZegoUIKit().getMediaPlayStateNotifier().value;

    widget.onPlayStateChanged?.call(playState);

    if (ZegoUIKitMediaPlayState.playing == playState) {
      startHideSurfaceTimer();
    } else {
      hideSurfaceTimer?.cancel();
    }
  }

  void startHideSurfaceTimer() {
    hideSurfaceTimer?.cancel();

    if (!widget.autoHideSurface) {
      return;
    }

    hideSurfaceTimer = Timer.periodic(
      Duration(seconds: widget.hideSurfaceSecond),
      (timer) {
        hideSurfaceTimer?.cancel();

        surfaceVisibilityNotifier.value = false;
      },
    );
  }

  void onExpressEngineCreated() {
    final isCreated = ZegoUIKitCore.shared.expressEngineCreatedNotifier.value;
    ZegoLoggerService.logInfo(
      'express engine created:$isCreated',
      tag: 'uikit ',
      subTag: 'media player',
    );

    if (isCreated) {
      ZegoUIKitCore.shared.expressEngineCreatedNotifier
          .removeListener(onExpressEngineCreated);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        autoShareMedia();
      });
    }
  }

  void autoShareMedia() {
    ZegoLoggerService.logInfo(
      'auto share media:${widget.filePathOrURL}',
      tag: 'uikit',
      subTag: 'media player',
    );
    ZegoUIKit()
        .playMedia(
      filePathOrURL: widget.filePathOrURL!,
      enableRepeat: widget.enableRepeat,
      autoStart: widget.autoStart,
    )
        .then((shareResult) {
      ZegoLoggerService.logInfo(
        'auto share media result:${widget.filePathOrURL}',
        tag: 'uikit',
        subTag: 'media player',
      );
    });
  }
}
