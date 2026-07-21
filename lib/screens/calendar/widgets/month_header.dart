import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Month/year header with animated left/right navigation and swipe hint.
class MonthHeader extends StatelessWidget {
  final DateTime displayedMonth;
  final Color primaryColor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthHeader({
    super.key,
    required this.displayedMonth,
    required this.primaryColor,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor = isDark ? Colors.white54 : Colors.grey.shade500;

    final isCurrentMonth = DateTime.now().month == displayedMonth.month &&
        DateTime.now().year == displayedMonth.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Month + year text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      DateFormat('MMMM').format(displayedMonth),
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy').format(displayedMonth),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                if (isCurrentMonth)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Current Month',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Navigation arrows
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrevious,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              // Today button (jump back to current month if browsing elsewhere)
              if (!isCurrentMonth)
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Today',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  'swipe →',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: subColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(width: 8),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
    );
  }
}
