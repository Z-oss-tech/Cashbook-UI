import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../providers/record_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/toast_helper.dart';
import 'add_record_screen.dart';
import '../reports/reports_screen.dart';
import '../../core/utils/date_helper.dart';
import 'package:flutter/services.dart';
import '../../core/utils/export_helper.dart';

class CashbookScreen extends StatefulWidget {
  final String cashbookName;

  const CashbookScreen({super.key, this.cashbookName = 'TestBook'});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  late String selectedCashbook;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    selectedCashbook = widget.cashbookName;
  }

  void _showCashbooksBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your Cashbooks",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F3255),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.cancel_outlined, color: isDark ? Colors.white : const Color(0xFF1F3255)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: isDark ? Colors.white24 : const Color(0xFFE0E0E0)),
              
              // Cashbook List
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<RecordProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      children: provider.cashbooks.map((cashbook) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildCashbookListItem(
                            context: context,
                            title: cashbook.name,
                            date: cashbook.createdAt.toString(),
                            isSelected: selectedCashbook == cashbook.name,
                            onTap: () {
                              setState(() {
                                selectedCashbook = cashbook.name;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCashbookListItem({
    required BuildContext context,
    required String title,
    required String date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.blueAccent : const Color(0xFF1F3255)) : (isDark ? Colors.white10 : const Color(0xFFF5F7FA)),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: isDark ? Colors.white : const Color(0xFF1F3255),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1F3255)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Created on: $date",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_vert,
              color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1F3255)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteRecordDialog(BuildContext context, RecordModel record) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Delete Record", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text("Are you sure you want to delete this transaction?", style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final recordProvider = Provider.of<RecordProvider>(context, listen: false);
                await recordProvider.deleteRecord(record.id);
                if (mounted) {
                  Navigator.pop(dialogContext);
                  if (recordProvider.error != null) {
                    ToastHelper.showToast(context, recordProvider.error!, isError: true);
                  } else {
                    ToastHelper.showToast(context, "Record deleted successfully!");
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text("Delete", style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditRecordDialog(BuildContext context, RecordModel record) {
    final TextEditingController amountController = TextEditingController(text: record.amount.toString());
    final TextEditingController noteController = TextEditingController(text: record.note);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Edit Record", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newAmountText = amountController.text.trim();
                final newNote = noteController.text.trim();
                final newAmount = double.tryParse(newAmountText);

                if (newAmount != null && newAmount > 0) {
                  final recordProvider = Provider.of<RecordProvider>(context, listen: false);
                  await recordProvider.updateRecord(record.id, {
                    'amount': newAmount,
                    'note': newNote,
                  });
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    if (recordProvider.error != null) {
                      ToastHelper.showToast(context, recordProvider.error!, isError: true);
                    } else {
                      ToastHelper.showToast(context, "Record updated successfully!");
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B7FFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text("Save", style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = Provider.of<RecordProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B1B23) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF1B1B23);
    
    // Filter records for the currently selected cashbook
    final allRecords = recordProvider.records;
    var cashbookRecords = allRecords.where((r) => r.cashbookName == selectedCashbook).toList();

    if (_filterDate != null) {
      cashbookRecords = cashbookRecords.where((r) => r.date.year == _filterDate!.year && r.date.month == _filterDate!.month && r.date.day == _filterDate!.day).toList();
    }

    // Calculate totals for this cashbook
    double totalReceived = cashbookRecords.where((r) => !r.isGiven).fold(0, (s, r) => s + r.amount);
    double totalGiven = cashbookRecords.where((r) => r.isGiven).fold(0, (s, r) => s + r.amount);
    double balance = totalReceived - totalGiven;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).padding.top + 64,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.7),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: textColor),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showCashbooksBottomSheet(context),
                        child: Row(
                          children: [
                            Text(
                              selectedCashbook,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Icon(Icons.expand_more_rounded, color: isDark ? Colors.white54 : const Color(0xFF767586)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.share_rounded, color: textColor),
                        onPressed: () => ExportHelper.showExportOptions(context, cashbookName: selectedCashbook),
                      ),
                      IconButton(
                        icon: Icon(Icons.analytics_rounded, color: textColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReportsScreen(cashbookName: selectedCashbook)),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(_filterDate == null ? Icons.calendar_today_rounded : Icons.event_busy_rounded, color: textColor),
                        onPressed: () async {
                          if (_filterDate != null) {
                            setState(() => _filterDate = null);
                            return;
                          }
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setState(() => _filterDate = pickedDate);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF4143D5),
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await Future.delayed(const Duration(milliseconds: 800));
            // Trigger rebuild
            setState((){});
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            children: [
            // Overview Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4143D5), Color(0xFF7459F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 25,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildOverviewTile(
                              title: "Total IN",
                              amount: "₹${totalReceived.toStringAsFixed(2)}",
                              amountColor: const Color(0xFF86EFAC), // green-300
                              borderRight: true,
                              borderBottom: true,
                            ),
                          ),
                          Expanded(
                            child: _buildOverviewTile(
                              title: "Total Out",
                              amount: "₹${totalGiven.toStringAsFixed(2)}",
                              amountColor: const Color(0xFFFCA5A5), // red-300
                              alignRight: true,
                              borderBottom: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildOverviewTile(
                              title: "Balance",
                              amount: "₹${balance.toStringAsFixed(2)}",
                              amountColor: const Color(0xFFBFDBFE), // blue-200
                              borderRight: true,
                            ),
                          ),
                          Expanded(
                            child: _buildOverviewTile(
                              title: "Total Entry",
                              amount: cashbookRecords.length.toString(),
                              amountColor: Colors.white,
                              alignRight: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Transactions List Header
            if (cashbookRecords.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D35) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE4E1ED),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 25,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    children: [
                      Container(
                        color: isDark ? const Color(0xFF22222A) : const Color(0xFFF5F2FE),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "DATE & CATEGORY",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4143D5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "NOTES",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4143D5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "AMOUNT",
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white54 : const Color(0xFF767586),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE4E1ED).withOpacity(0.5)),
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: cashbookRecords.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE4E1ED).withOpacity(0.3)),
                        itemBuilder: (context, index) {
                          final record = cashbookRecords[cashbookRecords.length - 1 - index]; // reversed
                          final isCredit = !record.isGiven;
                          
                          return Dismissible(
                            key: Key(record.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              HapticFeedback.heavyImpact();
                              bool confirm = false;
                              await showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text("Delete Record", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
                                  content: Text("Are you sure you want to delete this transaction?", style: GoogleFonts.inter()),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                      },
                                      child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        confirm = true;
                                        Navigator.pop(dialogContext);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      child: Text("Delete", style: GoogleFonts.inter(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              return confirm;
                            },
                            onDismissed: (direction) async {
                              final recordProvider = Provider.of<RecordProvider>(context, listen: false);
                              await recordProvider.deleteRecord(record.id);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Transaction deleted"),
                                    action: SnackBarAction(
                                      label: "UNDO",
                                      textColor: Colors.blue,
                                      onPressed: () {
                                        // Simple undo logic
                                        recordProvider.addRecord(record);
                                      },
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  )
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateHelper.formatDateTime(record.date),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (record.category != null && record.category!.isNotEmpty) ? record.category! : record.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark ? Colors.white54 : const Color(0xFF464555).withOpacity(0.8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      record.note.isNotEmpty ? record.note : '-',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? Colors.white54 : const Color(0xFF464555).withOpacity(0.8),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${isCredit ? '+' : '-'}${record.amount.toStringAsFixed(2)}",
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isCredit 
                                            ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF008339)) 
                                            : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFE53935)),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 24,
                                    child: PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white54 : const Color(0xFF464555), size: 20),
                                      padding: EdgeInsets.zero,
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditRecordDialog(context, record);
                                        } else if (value == 'delete') {
                                          _showDeleteRecordDialog(context, record);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit_rounded, size: 18),
                                              const SizedBox(width: 8),
                                              Text('Edit', style: GoogleFonts.inter()),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                                              const SizedBox(width: 8),
                                              Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Empty State
            if (cashbookRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.military_tech, size: 120, color: const Color(0xFF5B7FFF).withOpacity(0.2)),
                          Icon(Icons.military_tech, size: 100, color: const Color(0xFFE57373)),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F3255),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF4DB6AC), width: 4),
                            ),
                            child: const Icon(Icons.attach_money, color: Color(0xFF4DB6AC), size: 30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Data Found",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1F3255),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter Your First Transaction",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddRecordScreen(cashbookName: selectedCashbook)),
          );
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.only(left: 20, right: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF4143D5), Color(0xFF7459F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                "Add Transaction",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTile({
    required String title,
    required String amount,
    required Color amountColor,
    bool alignRight = false,
    bool borderRight = false,
    bool borderBottom = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          right: borderRight ? BorderSide(color: Colors.white.withOpacity(0.1)) : BorderSide.none,
          bottom: borderBottom ? BorderSide(color: Colors.white.withOpacity(0.1)) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: amountColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
