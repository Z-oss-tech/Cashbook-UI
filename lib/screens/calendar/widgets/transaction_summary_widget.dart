import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact income/expense/net balance summary card used in the bottom sheet.
class TransactionSummaryWidget extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final Color primaryColor;

  const TransactionSummaryWidget({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = totalIncome - totalExpense;
    final netColor = net >= 0 ? const Color(0xFF00C853) : const Color(0xFFE53935);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Income',
            value: totalIncome,
            color: const Color(0xFF00C853),
            icon: '📈',
          ),
          _Divider(isDark: isDark),
          _SummaryItem(
            label: 'Expense',
            value: totalExpense,
            color: const Color(0xFFE53935),
            icon: '📉',
          ),
          _Divider(isDark: isDark),
          _SummaryItem(
            label: 'Net',
            value: net,
            color: netColor,
            icon: net >= 0 ? '✅' : '⚠️',
            signed: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String icon;
  final bool signed;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.signed = false,
  });

  String _format(double v) {
    final abs = v.abs();
    String formatted;
    if (abs >= 100000) {
      formatted = '₹${(abs / 100000).toStringAsFixed(1)}L';
    } else if (abs >= 1000) {
      formatted = '₹${(abs / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = '₹${abs.toStringAsFixed(0)}';
    }
    if (signed && v < 0) formatted = '-$formatted';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            _format(value),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.2),
    );
  }
}
