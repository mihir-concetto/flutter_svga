part of 'player.dart';

class SVGAEasyPlayer extends StatefulWidget {
  final String? resUrl;
  final String? assetsName;
  final BoxFit fit;
  final VoidCallback onAnimationFinished;

  const SVGAEasyPlayer({
    super.key,
    this.resUrl,
    this.assetsName,
    this.fit = BoxFit.contain,
    required this.onAnimationFinished
  });

  @override
  State<StatefulWidget> createState() {
    return _SVGAEasyPlayerState();
  }
}

class _SVGAEasyPlayerState extends State<SVGAEasyPlayer>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? animationController;
  bool _hasFired = false;

  @override
  void initState() {
    super.initState();
    // animationController = SVGAAnimationController(vsync: this);
    _tryDecodeSvga();
    // animationController?.addListener(_animationListener);
  }

  // void _animationListener() {
  //   final animCtrl = animationController;
  //   final videoItem = animCtrl?.videoItem;
  //   // Only trigger if videoItem is loaded and animation is not repeating (or handle repeated callback)
  //   if (videoItem != null &&
  //       animCtrl!.currentFrame == videoItem.params.frames - 1/* &&
  //       // Optionally, you can check that the animation is not repeating
  //       animCtrl.isPlaying*/) {
  //     widget.onAnimationFinished();
  //     animCtrl.removeListener(_animationListener);
  //   }
  // }

  void _animationListener() {
    final animCtrl = animationController;
    final videoItem = animCtrl?.videoItem;
    if (!_hasFired &&
        videoItem != null &&
        animCtrl!.currentFrame == videoItem.params.frames - 1) {
      _hasFired = true;
      widget.onAnimationFinished();
      animCtrl.removeListener(_animationListener);
    }
  }


  @override
  void didUpdateWidget(covariant SVGAEasyPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resUrl != widget.resUrl ||
        oldWidget.assetsName != widget.assetsName) {
      _tryDecodeSvga();
    }
    // if (oldWidget.resUrl != widget.resUrl ||
    //     oldWidget.assetsName != widget.assetsName) {
    //   animationController?.removeListener(_animationListener); // Clean up previous
    //   _tryDecodeSvga();
    //   animationController?.addListener(_animationListener); // Add for new
    // }
  }

  @override
  Widget build(BuildContext context) {
    if (animationController == null) {
      return Container();
    }
    return SVGAImage(
      animationController!,
      fit: widget.fit,
    );
  }

  @override
  void dispose() {
    animationController?.removeListener(_animationListener);
    animationController?.dispose();
    animationController = null;
    super.dispose();
  }

  void _tryDecodeSvga() async {

    if (animationController != null) {
      animationController!.removeListener(_animationListener);
      animationController!.dispose();
      animationController = null;
    }

    MovieEntity decode;
    if (widget.resUrl != null) {
      decode = await SVGAParser.shared.decodeFromURL(widget.resUrl!);
    } else if (widget.assetsName != null) {
      decode = await SVGAParser.shared.decodeFromAssets(widget.assetsName!);
    } else {
      return;
    }

    try {
      MovieEntity videoItem = decode!;
      if (!mounted || animationController == null) {
        videoItem.dispose();
        return;
      }

      animationController!
        ..videoItem = videoItem;

      _hasFired = false;

      // Start playback from frame 0
      animationController!.forward(from: 0);

      // Add listener **after** starting playback
      animationController!.addListener(_animationListener);

      setState(() {});
    } catch (e, stack) {
      animationController!.removeListener(_animationListener);
      animationController!.dispose();
      animationController = null;
      widget.onAnimationFinished();
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'SVGAEasyPlayer',
        context: ErrorDescription('during _tryDecodeSvga()'),
        informationCollector: () => [
          if (widget.resUrl != null) StringProperty('resUrl', widget.resUrl),
          if (widget.assetsName != null) StringProperty('assetsName', widget.assetsName),
        ],
      ));
    }
  }

    // decode.then((videoItem) {
    //   if (mounted && animationController != null) {
    //     // Remove old listeners before adding a new one!
    //     animationController!
    //       ..removeListener(_animationListener)
    //       ..videoItem = videoItem;
    //
    //     animationController!.addListener(_animationListener);
    //     animationController!.forward(from: 0);
    //     // animationController!
    //     //   ..videoItem = videoItem
    //     //   ..forward(from: 0);
    //     //   // ..repeat();
    //
    //
    //
    //   } else {
    //     videoItem.dispose();
    //   }
    // }).catchError(
    //       (e, stack) {
    //     FlutterError.reportError(
    //       FlutterErrorDetails(
    //         exception: e,
    //         stack: stack,
    //         library: 'SVGAEasyPlayer',
    //         context: ErrorDescription('during _tryDecodeSvga'),
    //         informationCollector: () =>
    //         [
    //           if (widget.resUrl != null)
    //             StringProperty('resUrl', widget.resUrl),
    //           if (widget.assetsName != null)
    //             StringProperty('assetsName', widget.assetsName),
    //         ],
    //       ),
    //     );
    //   },
    // );
  // }
}
