import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/transaction_model.dart';
import '../../../core/utils/emoji_mapper.dart';
import 'emoji_indicator.dart';

/// A single day cell in the calendar grid.
class CalendarDayWidget extends StatelessWidget {
  final DateTime date;
  final List<RecordModel> records;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CalendarDayWidget({
    super.key,
    required this.date,
    required this.records,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasRecords = records.isNotEmpty;

    // Compute income and expense sums
    double totalIncome = 0;
    double totalExpense = 0;
    final List<String> emojis = [];

    for (final r in records) {
      if (r.type == 'income') {
        totalIncome += r.amount;
      } else {
        totalExpense += r.amount;
      }
      emojis.add(EmojiMapper.getEmoji(r.category, r.type));
    }

    // De-duplicate emojis for display (keep order but remove dups)
    final uniqueEmojis = emojis.toSet().toList();

    // Background & text colors
    Color bgColor;
    Color dayNumberColor;
    BoxBorder? border;

    if (isSelected) {
      bgColor = primaryColor;
      dayNumberColor = Colors.white;
      border = null;
    } else if (isToday) {
      bgColor = isDark
          ? primaryColor.withValues(alpha: 0.18)
          : primaryColor.withValues(alpha: 0.1);
      dayNumberColor = primaryColor;
      border = Border.all(color: primaryColor, width: 1.5);
    } else {
      bgColor = isDark
          ? const Color(0xFF1E1E2E)
          : Colors.white;
      dayNumberColor = isCurrentMonth
          ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
          : (isDark ? Colors.white30 : Colors.grey.shade400);
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.withValues(alpha: 0.12),
        width: 0.5,
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
          boxShadow: hasRecords && !isSelected && !isDark
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Day number
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: dayNumberColor,
                    height: 1,
                  ),
                ),
              ),

              if (hasRecords) ...[
                const SizedBox(height: 2),
                // Emoji row
                EmojiIndicator(
                  emojis: uniqueEmojis,
                  totalCount: records.length,
                ),
                const SizedBox(height: 2),
                // Amount summaries
                if (totalIncome > 0)
                  _buildAmountChip(
                    '+₹${_shortAmount(totalIncome)}',
                    isSelected ? Colors.greenAccent : const Color(0xFF00C853),
                  ),
                if (totalExpense > 0)
                  _buildAmountChip(
                    '-₹${_shortAmount(totalExpense)}',
                    isSelected ? Colors.redAccent.shade100 : const Color(0xFFE53935),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountChip(String text, Color color) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
      ),
    );
  }

  String _shortAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}
