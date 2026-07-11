import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../providers/record_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/toast_helper.dart';
import 'add_record_screen.dart';
import 'transaction_details_screen.dart';
import '../reports/reports_screen.dart';
import '../../core/utils/date_helper.dart';
import 'package:flutter/services.dart';
import '../../core/utils/export_helper.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/theme_background_wrapper.dart';
import '../../core/theme/premium_themes.dart';
import '../../providers/settings_provider.dart';

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your Cashbooks",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            (isDark ? Colors.white : const Color(0xFF0B1C30)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.cancel_outlined,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            (isDark ? Colors.white : const Color(0xFF0B1C30)),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white24 : const Color(0xFFE0E0E0),
              ),

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
                            cashbook: cashbook,
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
    required CashbookModel cashbook,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.blueAccent : const Color(0xFF1F3255))
              : (isDark ? Colors.white10 : const Color(0xFFF5F7FA)),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
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
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    (isDark ? Colors.white : const Color(0xFF0B1C30)),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cashbook.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1F3255)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Created on: ${cashbook.createdAt}",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white70
                          : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF1F3255)),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCashbookDialog(context, cashbook);
                } else if (value == 'delete') {
                  _showDeleteCashbookDialog(context, cashbook);
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
                      const Icon(
                        Icons.delete_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCashbookDialog(BuildContext context, CashbookModel cashbook) {
    final TextEditingController nameController = TextEditingController(
      text: cashbook.name,
    );
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Edit Cashbook",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Cashbook Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  final provider = Provider.of<RecordProvider>(
                    context,
                    listen: false,
                  );
                  await provider.updateCashbook(cashbook.id, newName);
                  if (mounted) {
                    setState(() {
                      if (selectedCashbook == cashbook.name) {
                        selectedCashbook = newName;
                      }
                    });
                    Navigator.pop(dialogContext);
                    ToastHelper.showToast(context, "Cashbook updated!");
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B7FFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Save",
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCashbookDialog(BuildContext context, CashbookModel cashbook) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete Cashbook",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            "Are you sure you want to delete '${cashbook.name}'? This will delete all associated transactions.",
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = Provider.of<RecordProvider>(
                  context,
                  listen: false,
                );
                await provider.deleteCashbook(cashbook.id);
                if (mounted) {
                  setState(() {
                    if (selectedCashbook == cashbook.name) {
                      selectedCashbook = provider.cashbooks.isNotEmpty
                          ? provider.cashbooks.first.name
                          : '';
                    }
                  });
                  Navigator.pop(dialogContext);
                  ToastHelper.showToast(context, "Cashbook deleted!");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Delete",
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteRecordDialog(BuildContext context, RecordModel record) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete Record",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this transaction?",
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final recordProvider = Provider.of<RecordProvider>(
                  context,
                  listen: false,
                );
                await recordProvider.deleteRecord(record.id);
                if (mounted) {
                  Navigator.pop(dialogContext);
                  if (recordProvider.error != null) {
                    ToastHelper.showToast(
                      context,
                      recordProvider.error!,
                      isError: true,
                    );
                  } else {
                    ToastHelper.showToast(
                      context,
                      "Record deleted successfully!",
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Delete",
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditRecordDialog(BuildContext context, RecordModel record) {
    final TextEditingController amountController = TextEditingController(
      text: record.amount.toString(),
    );
    final TextEditingController noteController = TextEditingController(
      text: record.note,
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Edit Record",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newAmountText = amountController.text.trim();
                final newNote = noteController.text.trim();
                final newAmount = double.tryParse(newAmountText);

                if (newAmount != null && newAmount > 0) {
                  final recordProvider = Provider.of<RecordProvider>(
                    context,
                    listen: false,
                  );
                  await recordProvider.updateRecord(record.id, {
                    'amount': newAmount,
                    'note': newNote,
                  });
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    if (recordProvider.error != null) {
                      ToastHelper.showToast(
                        context,
                        recordProvider.error!,
                        isError: true,
                      );
                    } else {
                      ToastHelper.showToast(
                        context,
                        "Record updated successfully!",
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B7FFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Save",
                style: GoogleFonts.inter(color: Colors.white),
              ),
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
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF0B1C30));

    final settings = Provider.of<SettingsProvider>(context);
    final premiumTheme = PremiumThemes.getTheme(settings.appTheme);
    final isDefault = settings.appTheme == 'Default';
    final primaryGradient = isDefault
        ? const LinearGradient(
            colors: [Color(0xFF4143D5), Color(0xFF7459F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : premiumTheme.gradient;

    // Filter records for the currently selected cashbook
    final allRecords = recordProvider.records;
    var cashbookRecords = allRecords
        .where((r) => r.cashbookName == selectedCashbook)
        .toList();

    if (_filterDate != null) {
      cashbookRecords = cashbookRecords
          .where(
            (r) =>
                r.date.year == _filterDate!.year &&
                r.date.month == _filterDate!.month &&
                r.date.day == _filterDate!.day,
          )
          .toList();
    }

    // Calculate totals for this cashbook
    double totalReceived = cashbookRecords
        .where((r) => !r.isGiven)
        .fold(0, (s, r) => s + r.amount);
    double totalGiven = cashbookRecords
        .where((r) => r.isGiven)
        .fold(0, (s, r) => s + r.amount);
    double balance = totalReceived - totalGiven;

    return ThemeBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Theme.of(context).cardColor.withValues(alpha: 0.9),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: textColor,
                            ),
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showCashbooksBottomSheet(context),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      selectedCashbook,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF767586),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.share_rounded, color: textColor),
                          onPressed: () => ExportHelper.showExportOptions(
                            context,
                            cashbookName: selectedCashbook,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.analytics_rounded, color: textColor),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportsScreen(
                                  cashbookName: selectedCashbook,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _filterDate == null
                                ? Icons.calendar_today_rounded
                                : Icons.event_busy_rounded,
                            color: textColor,
                          ),
                          onPressed: () {
                            if (_filterDate != null) {
                              setState(() => _filterDate = null);
                              return;
                            }
                            final rawRecords = recordProvider.records
                                .where(
                                  (r) => r.cashbookName == selectedCashbook,
                                )
                                .toList();
                            _showCustomCalendarPicker(context, rawRecords);
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
            color: isDefault
                ? const Color(0xFF4143D5)
                : premiumTheme.primaryColor,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await Future.delayed(const Duration(milliseconds: 800));
              // Trigger rebuild
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                // Overview Card
                Builder(
                  builder: (context) {
                    final settings = Provider.of<SettingsProvider>(context);
                    final premiumTheme = PremiumThemes.getTheme(
                      settings.appTheme,
                    );
                    final isDefault = settings.appTheme == 'Default';
                    final gradient = isDefault
                        ? const LinearGradient(
                            colors: [Color(0xFF4143D5), Color(0xFF7459F7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : premiumTheme.gradient;

                    final isDarkGradient =
                        isDefault ||
                        premiumTheme.themeData.brightness == Brightness.dark;
                    final titleColor = isDarkGradient
                        ? Colors.white.withValues(alpha: 0.8)
                        : const Color(0xFF881337);
                    final borderColor = isDarkGradient
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black12;
                    final totalInColor = isDarkGradient
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF059669);
                    final totalOutColor = isDarkGradient
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFE11D48);
                    final balanceColor = isDarkGradient
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFF2563EB);
                    final totalEntryColor = isDarkGradient
                        ? Colors.white
                        : Colors.black87;

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: gradient,
                        boxShadow: [
                          BoxShadow(
                            color: isDefault
                                ? Colors.black.withValues(alpha: 0.05)
                                : premiumTheme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
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
                                      amount:
                                          "₹${totalReceived.toStringAsFixed(2)}",
                                      amountColor: totalInColor,
                                      titleColor: titleColor,
                                      borderColor: borderColor,
                                      borderRight: true,
                                      borderBottom: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildOverviewTile(
                                      title: "Total Out",
                                      amount:
                                          "₹${totalGiven.toStringAsFixed(2)}",
                                      amountColor: totalOutColor,
                                      titleColor: titleColor,
                                      borderColor: borderColor,
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
                                      amountColor: balanceColor,
                                      titleColor: titleColor,
                                      borderColor: borderColor,
                                      borderRight: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildOverviewTile(
                                      title: "Total Entry",
                                      amount: cashbookRecords.length.toString(),
                                      amountColor: totalEntryColor,
                                      titleColor: titleColor,
                                      borderColor: borderColor,
                                      alignRight: true,
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
                const SizedBox(height: 32),

                // Transactions List
                if (cashbookRecords.isNotEmpty)
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: cashbookRecords.length,
                    itemBuilder: (context, index) {
                      final record =
                          cashbookRecords[cashbookRecords.length -
                              1 -
                              index]; // reversed
                      final isCredit = !record.isGiven;

                      return FadeInRight(
                        delay: Duration(milliseconds: 50 * index),
                        duration: const Duration(milliseconds: 400),
                        child: Dismissible(
                          key: Key(record.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            HapticFeedback.heavyImpact();
                            bool confirm = false;
                            await showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  "Delete Record",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                content: Text(
                                  "Are you sure you want to delete this transaction?",
                                  style: GoogleFonts.inter(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      confirm = true;
                                      Navigator.pop(dialogContext);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Delete",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return confirm;
                          },
                          onDismissed: (direction) async {
                            final recordProvider = Provider.of<RecordProvider>(
                              context,
                              listen: false,
                            );
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
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GlassCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 20,
                              backgroundColor: isDefault
                                  ? (isDark
                                        ? const Color(0xFF2D2D35)
                                        : Colors.white)
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Category Tag & Date & More options
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.blue
                                                              .withValues(
                                                                alpha: 0.2,
                                                              )
                                                        : Colors.blue.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.blue
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                )
                                                          : Colors
                                                                .blue
                                                                .shade200,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    (record.category != null &&
                                                            record
                                                                .category!
                                                                .isNotEmpty)
                                                        ? record.category!
                                                        : 'General',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDark
                                                          ? Colors.blueAccent
                                                          : Colors
                                                                .blue
                                                                .shade700,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                DateHelper.formatDateTime(
                                                  record.date,
                                                ),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert_rounded,
                                              color: isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF464555),
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showEditRecordDialog(
                                                  context,
                                                  record,
                                                );
                                              } else if (value == 'delete') {
                                                _showDeleteRecordDialog(
                                                  context,
                                                  record,
                                                );
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) => [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.edit_rounded,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Edit',
                                                          style:
                                                              GoogleFonts.inter(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.delete_rounded,
                                                          color: Colors.red,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Delete',
                                                          style:
                                                              GoogleFonts.inter(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Type & Amount
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.title,
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isCredit ? 'Income' : 'Expense',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isCredit
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${isCredit ? '+' : '-'}₹${record.amount.toStringAsFixed(2)}",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: isCredit
                                                ? (isDark
                                                      ? const Color(0xFF86EFAC)
                                                      : const Color(0xFF008339))
                                                : (isDark
                                                      ? const Color(0xFFFCA5A5)
                                                      : const Color(
                                                          0xFFE53935,
                                                        )),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Details lines
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (record.note.isNotEmpty) ...[
                                          Text(
                                            "Note: ${record.note}",
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(
                                          "Payment: ${record.paymentMethod ?? 'Cash'}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Divider(
                                    height: 1,
                                    color: isDark
                                        ? Colors.white12
                                        : const Color(0xFFE4E1ED),
                                  ),

                                  // Details Button
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TransactionDetailsScreen(
                                                record: record,
                                              ),
                                        ),
                                      );
                                    },
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "View Details",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: isDefault
                                              ? const Color(0xFF4143D5)
                                              : premiumTheme.primaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
                              Icon(
                                Icons.military_tech,
                                size: 120,
                                color: const Color(
                                  0xFF5B7FFF,
                                ).withValues(alpha: 0.2),
                              ),
                              Icon(
                                Icons.military_tech,
                                size: 100,
                                color: const Color(0xFFE57373),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F3255),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF4DB6AC),
                                    width: 4,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.attach_money,
                                  color: Color(0xFF4DB6AC),
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Data Found",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F3255),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter Your First Transaction",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
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
              MaterialPageRoute(
                builder: (_) => AddRecordScreen(cashbookName: selectedCashbook),
              ),
            );
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.only(left: 20, right: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: isDefault
                      ? Colors.black.withValues(alpha: 0.05)
                      : premiumTheme.primaryColor.withValues(alpha: 0.4),
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
      ),
    );
  }

  Widget _buildOverviewTile({
    required String title,
    required String amount,
    required Color amountColor,
    required Color titleColor,
    required Color borderColor,
    bool alignRight = false,
    bool borderRight = false,
    bool borderBottom = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          right: borderRight ? BorderSide(color: borderColor) : BorderSide.none,
          bottom: borderBottom
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: titleColor,
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

  void _showCustomCalendarPicker(
    BuildContext context,
    List<RecordModel> records,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime focusedDay = _filterDate ?? DateTime.now();
    DateTime? selectedDay = _filterDate;

    // Get unique dates with transactions
    final transactionDates = records
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Date",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (selectedDay != null)
                          TextButton(
                            onPressed: () {
                              setState(() => _filterDate = null);
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Clear",
                              style: GoogleFonts.inter(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(selectedDay, day),
                          onDaySelected: (sDay, fDay) {
                            setState(() => _filterDate = sDay);
                            Navigator.pop(context);
                          },
                          calendarFormat: CalendarFormat.month,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left_rounded,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            weekendTextStyle: GoogleFonts.inter(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            outsideTextStyle: GoogleFonts.inter(
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF4143D5),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: const Color(
                                0xFF4143D5,
                              ).withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) {
                              final normalizedDay = DateTime(
                                day.year,
                                day.month,
                                day.day,
                              );
                              if (transactionDates.contains(normalizedDay)) {
                                return Positioned(
                                  bottom: 6,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF86EFAC)
                                          : const Color(0xFF008339),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
