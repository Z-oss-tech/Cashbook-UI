import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/date_helper.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final RecordModel record;

  const TransactionDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCredit = !record.isGiven;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1B1B23)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          isCredit ? "Income Details" : "Expense Details",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F3255),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1F3255),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Amount Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D35) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isCredit ? Colors.green : Colors.red).withValues(
                      alpha: 0.1,
                    ),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 48,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "${isCredit ? '+' : '-'}₹${record.amount.toStringAsFixed(2)}",
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCredit
                  ? "Income successfully recorded"
                  : "Expense successfully recorded",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),

            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D35) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE4E1ED),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    "Category",
                    record.category?.isNotEmpty == true
                        ? record.category!
                        : 'General',
                    isDark,
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(
                    "Date",
                    DateHelper.formatDate(record.date),
                    isDark,
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(
                    "Time",
                    DateHelper.formatTime(record.date),
                    isDark,
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(
                    "Payment Mode",
                    record.paymentMethod ?? 'Cash',
                    isDark,
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(
                    "Cashbook",
                    record.cashbookName ?? 'General',
                    isDark,
                  ),
                  if (record.note.isNotEmpty) ...[
                    const Divider(height: 30),
                    _buildDetailRow("Note", record.note, isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F3255),
            ),
          ),
        ),
      ],
    );
  }
}
