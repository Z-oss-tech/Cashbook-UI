import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/transaction_model.dart';
import '../../../providers/record_provider.dart';
import '../../../core/utils/emoji_mapper.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/toast_helper.dart';
import 'transaction_summary_widget.dart';

/// Full-featured bottom sheet for a selected calendar date.
void showTransactionBottomSheet({
  required BuildContext context,
  required DateTime date,
  required List<RecordModel> records,
  required Color primaryColor,
  required VoidCallback onAddRecord,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TransactionBottomSheet(
      date: date,
      records: records,
      primaryColor: primaryColor,
      onAddRecord: onAddRecord,
    ),
  );
}

class TransactionBottomSheet extends StatefulWidget {
  final DateTime date;
  final List<RecordModel> records;
  final Color primaryColor;
  final VoidCallback onAddRecord;

  const TransactionBottomSheet({
    super.key,
    required this.date,
    required this.records,
    required this.primaryColor,
    required this.onAddRecord,
  });

  @override
  State<TransactionBottomSheet> createState() => _TransactionBottomSheetState();
}

class _TransactionBottomSheetState extends State<TransactionBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnim;
  late Animation<double> _fadeAnim;
  late List<RecordModel> _records;

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.records);
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  double get _totalIncome =>
      _records.where((r) => r.type == 'income').fold(0, (a, r) => a + r.amount);
  double get _totalExpense =>
      _records.where((r) => r.type == 'expense').fold(0, (a, r) => a + r.amount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final sheetBg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final isToday = _isSameDay(widget.date, DateTime.now());

    return DraggableScrollableSheet(
      initialChildSize: _records.isEmpty ? 0.42 : 0.72,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.42, 0.72, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      // Date badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.primaryColor,
                              widget.primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEE').format(widget.date),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${widget.date.day}',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(widget.date),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '✅ Today',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF00C853),
                                  ),
                                ),
                              ),
                            Text(
                              DateFormat('EEEE, MMMM d').format(widget.date),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${_records.length} transaction${_records.length == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Add button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onAddRecord();
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.primaryColor,
                                widget.primaryColor.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Summary cards (only if there are records)
              if (_records.isNotEmpty) ...[
                TransactionSummaryWidget(
                  totalIncome: _totalIncome,
                  totalExpense: _totalExpense,
                  primaryColor: widget.primaryColor,
                ),
                const SizedBox(height: 12),
              ],

              // Divider
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.15),
              ),

              // Transaction list
              Expanded(
                child: _records.isEmpty
                    ? _EmptyState(
                        primaryColor: widget.primaryColor,
                        onAdd: () {
                          Navigator.pop(context);
                          widget.onAddRecord();
                        },
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          return _TransactionCard(
                            record: _records[index],
                            primaryColor: widget.primaryColor,
                            isDark: isDark,
                            onDelete: () => _deleteRecord(index),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteRecord(int index) async {
    final record = _records[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Transaction?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently remove this record.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<RecordProvider>(context, listen: false)
          .deleteRecord(record.id);
      setState(() => _records.removeAt(index));
      if (mounted) ToastHelper.showToast(context, 'Transaction deleted');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Transaction Card ───────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final RecordModel record;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.record,
    required this.primaryColor,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = record.type == 'income';
    final amountColor =
        isIncome ? const Color(0xFF00C853) : const Color(0xFFE53935);
    final emoji = EmojiMapper.getEmoji(record.category, record.type);
    final category = record.category ?? 'General';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: amountColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          record.title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  DateHelper.formatTime(record.date),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            if (record.note.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                record.note,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'}₹${_formatAmount(record.amount)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onAdd;

  const _EmptyState({required this.primaryColor, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📭', style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            'No transactions on this day',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to record one',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '+ Add Transaction',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
