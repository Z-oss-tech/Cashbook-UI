import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Displays 1–3 emojis with a bounce animation and an overflow count badge.
class EmojiIndicator extends StatefulWidget {
  final List<String> emojis;
  final int totalCount;

  const EmojiIndicator({
    super.key,
    required this.emojis,
    required this.totalCount,
  });

  @override
  State<EmojiIndicator> createState() => _EmojiIndicatorState();
}

class _EmojiIndicatorState extends State<EmojiIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Play once on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayEmojis = widget.emojis.take(3).toList();
    final overflow = widget.totalCount - 3;

    return ScaleTransition(
      scale: _bounceAnim,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...displayEmojis.map(
            (e) => Text(e, style: const TextStyle(fontSize: 11)),
          ),
          if (overflow > 0) ...[
            const SizedBox(width: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+$overflow',
                style: GoogleFonts.inter(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
