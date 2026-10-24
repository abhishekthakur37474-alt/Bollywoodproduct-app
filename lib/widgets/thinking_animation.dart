import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable Lottie animation: "two people thinking".
///
/// Defaults to looping indefinitely. Pass [animate] false to freeze on the
/// first frame, or [repeat] false to play once.
class ThinkingAnimation extends StatelessWidget {
  const ThinkingAnimation({
    super.key,
    this.size,
    this.animate = true,
    this.repeat = true,
    this.fit = BoxFit.contain,
  });

  /// Size applied to both width and height. When null, the animation uses its
  /// intrinsic aspect ratio within the available space.
  final double? size;
  final bool animate;
  final bool repeat;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/two-people-thinking.json',
        animate: animate,
        repeat: repeat,
        fit: fit,
      ),
    );
  }
}
