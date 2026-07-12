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
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                (isDark ? Colors.white : const Color(0xFF0B1C30)),
          ),
        ),
        iconTheme: IconThemeData(
          color:
              Theme.of(context).textTheme.bodyLarge?.color ??
              (isDark ? Colors.white : const Color(0xFF0B1C30)),
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
                color: Theme.of(context).cardColor,
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
                color: Theme.of(context).dividerColor,
              ),
            ),
            const SizedBox(height: 40),

            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                    context,
                    "Category",
                    record.category?.isNotEmpty == true
                        ? record.category!
                        : 'General',
                    isDark,
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(
                    context,
                    "Date",
                    DateHelper.formatDate(record.date),
                    isDark,
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(
                    context,
                    "Time",
                    DateHelper.formatTime(record.date),
                    isDark,
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(
                    context,
                    "Payment Mode",
                    record.paymentMethod ?? 'Cash',
                    isDark,
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(
                    context,
                    "Cashbook",
                    record.cashbookName ?? 'General',
                    isDark,
                  ),
                  if (record.note.isNotEmpty) ...[
                    const Divider(height: 30),
                    _buildDetailRow(context, "Note", record.note, isDark),
                  ],
                  if (record.attachmentUrl != null && record.attachmentUrl!.isNotEmpty) ...[
                    const Divider(height: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Receipt / Attachment",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            record.attachmentUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: isDark ? Colors.white10 : Colors.black12,
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, size: 48, color: Theme.of(context).dividerColor),
                                    const SizedBox(height: 8),
                                    Text("Failed to load image", style: TextStyle(color: Theme.of(context).dividerColor)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).dividerColor,
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
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  (isDark ? Colors.white : const Color(0xFF0B1C30)),
            ),
          ),
        ),
      ],
    );
  }
}
