import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/record_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/toast_helper.dart';
import 'add_record_screen.dart';
import '../reports/reports_screen.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
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
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F3255),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.cancel_outlined, color: Color(0xFF1F3255)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
              
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
    required String title,
    required String date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F3255) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: const Color(0xFF1F3255),
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
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.white : const Color(0xFF1F3255),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Created on: $date",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_vert,
              color: isSelected ? Colors.white : const Color(0xFF1F3255),
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
          title: Text("Delete Record", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text("Are you sure you want to delete this transaction?", style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
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
              child: Text("Delete", style: GoogleFonts.poppins(color: Colors.white)),
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
          title: Text("Edit Record", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
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
              child: Text("Save", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = Provider.of<RecordProvider>(context);
    
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
      backgroundColor: const Color(0xFFF1F5F9), // Light grayish background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3255), // Dark blue from screenshot
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: GestureDetector(
          onTap: () => _showCashbooksBottomSheet(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  selectedCashbook,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            onPressed: () {
              ExportHelper.showExportOptions(context, cashbookName: selectedCashbook);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportsScreen(cashbookName: selectedCashbook)),
              );
            },
          ),
          IconButton(
            icon: Icon(_filterDate == null ? Icons.calendar_month : Icons.event_busy, color: Colors.white),
            onPressed: () async {
              if (_filterDate != null) {
                setState(() {
                  _filterDate = null;
                });
                return;
              }
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (pickedDate != null) {
                setState(() {
                  _filterDate = pickedDate;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // The Summary Card
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryBox(
                          title: "Total IN",
                          amount: totalReceived.toStringAsFixed(2),
                          amountColor: const Color(0xFF4DB6AC), // Teal
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                      Expanded(
                        child: _buildSummaryBox(
                          title: "Total Out",
                          amount: totalGiven.toStringAsFixed(2),
                          amountColor: const Color(0xFFE57373), // Red
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryBox(
                          title: "Balance",
                          amount: balance.toStringAsFixed(2),
                          amountColor: const Color(0xFF9575CD), // Purple
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                      Expanded(
                        child: _buildSummaryBox(
                          title: "Total Entry",
                          amount: cashbookRecords.length.toString(),
                          amountColor: const Color(0xFF2196F3), // Blue
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // The Headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "DATE",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF512DA8),
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "CREDIT",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4DB6AC),
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "DEBIT",
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE57373),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 32), // Placeholder to align with the PopupMenuButton
              ],
            ),
          ),
          
          // Empty State or List
          Expanded(
            child: cashbookRecords.isEmpty
              ? Center(
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
                          color: const Color(0xFF1F3255),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter Your First Transaction",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 60), // Space for bottom nav
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80), // Space for bottom nav
                  itemCount: cashbookRecords.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = cashbookRecords[cashbookRecords.length - 1 - index]; // reversed
                    final isCredit = !record.isGiven;
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${record.date.day}/${record.date.month}/${record.date.year}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: const Color(0xFF1F3255),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  record.note.isNotEmpty ? record.note : record.personName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              isCredit ? record.amount.toStringAsFixed(2) : "-",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: isCredit ? const Color(0xFF4DB6AC) : Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              !isCredit ? record.amount.toStringAsFixed(2) : "-",
                              textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: !isCredit ? const Color(0xFFE57373) : Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                              padding: EdgeInsets.zero,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditRecordDialog(context, record);
                                } else if (value == 'delete') {
                                  _showDeleteRecordDialog(context, record);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red, size: 18),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddRecordScreen(cashbookName: selectedCashbook)),
          );
        },
        backgroundColor: const Color(0xFF5B7FFF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Add Record",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryBox({
    required String title,
    required String amount,
    required Color amountColor,
    bool alignRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F3255),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
