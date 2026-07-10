import 'package:flutter/material.dart';

class AnimationHelper {
  static void showEmojiAnimation(
    BuildContext context, {
    required bool isIncome,
    required double amount,
  }) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _EmojiAnimationWidget(
          isIncome: isIncome,
          amount: amount,
          onComplete: () {
            overlayEntry.remove();
          },
        );
      },
    );

    overlay.insert(overlayEntry);
  }
}

class _EmojiAnimationWidget extends StatefulWidget {
  final bool isIncome;
  final double amount;
  final VoidCallback onComplete;

  const _EmojiAnimationWidget({
    required this.isIncome,
    required this.amount,
    required this.onComplete,
  });

  @override
  State<_EmojiAnimationWidget> createState() => _EmojiAnimationWidgetState();
}

class _EmojiAnimationWidgetState extends State<_EmojiAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.5, end: 1.5), weight: 30),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.5,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _positionAnimation = Tween<double>(
      begin: 50.0,
      end: -50.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the emoji based on income/expense and amount
    String emoji = "";
    final bool isBigAmount = widget.amount >= 2000;

    if (widget.isIncome) {
      emoji = isBigAmount ? "🥳🎉" : "😊";
    } else {
      emoji = isBigAmount ? "😭💸" : "😢";
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _positionAnimation.value),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 80,
                        fontFamily: 'Apple Color Emoji',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
