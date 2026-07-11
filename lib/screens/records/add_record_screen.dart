// ignore_for_file: unused_field
import 'dart:ui';
import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/date_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../providers/record_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/animation_helper.dart';
import '../../core/utils/toast_helper.dart';
import '../../widgets/calculator_dialog.dart';

class AddRecordScreen extends StatefulWidget {
  final String cashbookName;

  const AddRecordScreen({super.key, this.cashbookName = 'TestBook'});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  bool isGiven = true;
  bool _isLoading = false;
  String? selectedReason;
  bool _showAdvancedOptions = false;
  String selectedPaymentMode = 'Cash';
  final List<String> paymentModes = [
    'Cash',
    'Online',
    'Bank Transfer',
    'Cheque',
    'Other',
  ];

  final List<String> givenReasons = [
    'Food / Dining',
    'Transportation',
    'Utilities / Bills',
    'Shopping',
    'Rent / EMI',
    'Supplier / Vendor Payment',
    'Groceries & Supplies',
    'Loan Given',
    'Health / Medical',
    'Maintenance & Repairs',
    'Entertainment',
    'Business',
    'Miscellaneous',
    'Other',
  ];

  final List<String> receivedReasons = [
    'Salary / Wages',
    'Sales / Business Income',
    'Freelance / Project Advance',
    'Rental Income',
    'Loan Repayment',
    'Cashback / Reward',
    'Sold Item',
    'Interest / Dividends',
    'Pocket Money',
    'Business',
    'Miscellaneous',
    'Other',
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food / Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Utilities / Bills':
        return Icons.receipt_long;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Rent / EMI':
        return Icons.home;
      case 'Salary / Wages':
        return Icons.account_balance_wallet;
      case 'Business':
        return Icons.business_center;
      case 'Health / Medical':
        return Icons.medical_services;
      case 'Entertainment':
        return Icons.movie;
      case 'Groceries & Supplies':
        return Icons.local_grocery_store;
      case 'Sales / Business Income':
        return Icons.storefront;
      default:
        return Icons.category;
    }
  }

  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final FocusNode _amountFocusNode = FocusNode();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _initialNoteText = '';

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        _initialNoteText = noteController.text;
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            if (_initialNoteText.trim().isEmpty) {
              noteController.text = val.recognizedWords;
            } else {
              noteController.text = '$_initialNoteText ${val.recognizedWords}'
                  .trim();
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _saveRecord() async {
    final String amountText = amountController.text.trim();
    final String note = noteController.text.trim();

    if (amountText.isEmpty) {
      ToastHelper.showToast(context, "Please enter an amount", isError: true);
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ToastHelper.showToast(
        context,
        "Please enter a valid amount greater than 0",
        isError: true,
      );
      return;
    }

    final recordProvider = Provider.of<RecordProvider>(context, listen: false);

    final cashbook = recordProvider.cashbooks.firstWhere(
      (c) => c.name == widget.cashbookName,
      orElse: () => recordProvider.cashbooks.isNotEmpty
          ? recordProvider.cashbooks.first
          : CashbookModel(
              id: '',
              name: widget.cashbookName,
              createdAt: DateTime.now(),
            ),
    );

    final String defaultTitle =
        selectedReason ?? (isGiven ? 'Expense' : 'Income');

    DateTime finalDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final record = RecordModel(
      id: '',
      cashbookId: cashbook.id,
      title: defaultTitle,
      amount: amount,
      type: isGiven ? 'expense' : 'income',
      category: selectedReason,
      paymentMethod: selectedPaymentMode,
      note: note,
      date: finalDateTime,
      cashbookName: widget.cashbookName,
    );

    setState(() {
      _isLoading = true;
    });
    await recordProvider.addRecord(record);
    if (mounted)
      setState(() {
        _isLoading = false;
      });

    if (!mounted) return;

    if (recordProvider.error != null) {
      ToastHelper.showToast(context, recordProvider.error!, isError: true);
      return;
    }

    ToastHelper.showToast(context, "Record saved successfully!");

    // Call emoji animation before popping
    AnimationHelper.showEmojiAnimation(
      context,
      isIncome: !isGiven,
      amount: amount,
    );

    Navigator.pop(context);
  }

  void _showCategoryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = isGiven ? givenReasons : receivedReasons;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Category",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = selectedReason == option;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedReason = option;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4143D5).withValues(alpha: 0.1)
                              : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFF5F2FE)),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF4143D5),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(option),
                              color: isSelected
                                  ? const Color(0xFF4143D5)
                                  : (isDark ? Colors.white54 : Colors.black54),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1B1B23),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF4143D5),
                              ),
                          ],
                        ),
                      ),
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

  void _showPaymentModePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Payment Mode",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30)),
                ),
              ),
              const SizedBox(height: 16),
              ...paymentModes.map((mode) {
                final isSelected = selectedPaymentMode == mode;
                return ListTile(
                  title: Text(
                    mode,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30)),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4143D5),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      selectedPaymentMode = mode;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final glassColor = isDark
        ? Theme.of(context).cardColor.withValues(alpha: 0.5)
        : Theme.of(context).cardColor.withValues(alpha: 0.9);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.5);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30));
    final textMuted = isDark ? Colors.white60 : const Color(0xFF464555);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: MediaQuery.of(context).padding.top + 64,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 8,
                right: 8,
              ),
              decoration: BoxDecoration(
                color: surfaceColor.withValues(alpha: 0.7),
                border: Border(bottom: BorderSide(color: glassBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFF4143D5),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    AppLocalizations.of(context)!.addRecord,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4143D5),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.calculate_outlined,
                      color: const Color(0xFF4143D5),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CalculatorDialog(
                          onResult: (result) {
                            if (result.isNotEmpty && result != '0') {
                              setState(() {
                                amountController.text = result;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF4143D5,
                ).withValues(alpha: isDark ? 0.1 : 0.05),
              ),
            ).animateBlur(),
          ),

          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              children: [
                // Amount Hero Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: isGiven
                          ? [const Color(0xFFFF6B6B), const Color(0xFFEE5253)]
                          : [const Color(0xFF34D399), const Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isGiven
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF059669))
                                .withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Total Amount",
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "₹",
                            style: GoogleFonts.manrope(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IntrinsicWidth(
                            child: TextField(
                              controller: amountController,
                              focusNode: _amountFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: "0",
                                hintStyle: GoogleFonts.manrope(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isGiven ? "Expense Mode" : "Income Mode",
                          style: GoogleFonts.hankenGrotesk(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Segmented Control (Neumorphic)
                Container(
                  height: 52,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E26)
                        : const Color(0xFFE9E6F3),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.white.withValues(alpha: 0.8),
                        blurRadius: 5,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: isGiven
                            ? 0
                            : (MediaQuery.of(context).size.width - 48 - 12) / 2,
                        width:
                            (MediaQuery.of(context).size.width - 48 - 12) / 2,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2D2D3A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                if (!isGiven) {
                                  setState(() {
                                    isGiven = true;
                                    selectedReason = null;
                                  });
                                }
                              },
                              child: Center(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isGiven ? 1.0 : 0.6,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("💸"),
                                      const SizedBox(width: 8),
                                      Text(
                                        "You Gave",
                                        style: GoogleFonts.hankenGrotesk(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                if (isGiven) {
                                  setState(() {
                                    isGiven = false;
                                    selectedReason = null;
                                  });
                                }
                              },
                              child: Center(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: !isGiven ? 1.0 : 0.6,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("💰"),
                                      const SizedBox(width: 8),
                                      Text(
                                        "You Received",
                                        style: GoogleFonts.hankenGrotesk(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Form Fields
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Categories
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: (isGiven ? givenReasons : receivedReasons)
                            .take(5)
                            .map((category) {
                              final isSelected = selectedReason == category;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    selectedReason = category;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF4143D5)
                                        : (isDark
                                              ? Colors.white10
                                              : const Color(0xFFE4E1ED)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(category),
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF464555)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        category.split(' ')[0], // Short name
                                        style: GoogleFonts.hankenGrotesk(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white70
                                                    : const Color(0xFF464555)),
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Picker
                    GestureDetector(
                      onTap: _showCategoryPicker,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: glassColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: glassBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2D2D3A)
                                    : const Color(0xFFE4E1ED),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                selectedReason != null
                                    ? _getCategoryIcon(selectedReason!)
                                    : Icons.category_rounded,
                                color: const Color(0xFF5B5FEF),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Category",
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textMuted,
                                    ),
                                  ),
                                  Text(
                                    selectedReason ?? "Select Category",
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              color: const Color(0xFF767586),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Mode Picker
                    GestureDetector(
                      onTap: _showPaymentModePicker,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: glassColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: glassBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2D2D3A)
                                    : const Color(0xFFE4E1ED),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFF008339),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Payment Method",
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textMuted,
                                    ),
                                  ),
                                  Text(
                                    selectedPaymentMode,
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              color: const Color(0xFF767586),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: glassColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: glassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Notes",
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                              GestureDetector(
                                onTap: _listen,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2D2D3A)
                                        : const Color(0xFFF5F2FE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isListening
                                        ? Icons.mic_off_rounded
                                        : Icons.mic_rounded,
                                    color: _isListening
                                        ? Colors.red
                                        : const Color(0xFF4143D5),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 2,
                            minLines: 1,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: "Add a note...",
                              hintStyle: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(
                                  0xFF767586,
                                ).withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030),
                              );
                              if (pickedDate != null) {
                                setState(() => selectedDate = pickedDate);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: glassColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: glassBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2D2D3A)
                                          : const Color(0xFFE4E1ED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFFB55700),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Date",
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: textMuted,
                                          ),
                                        ),
                                        Text(
                                          DateHelper.formatDate(selectedDate),
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (pickedTime != null) {
                                setState(() => selectedTime = pickedTime);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: glassColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: glassBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2D2D3A)
                                          : const Color(0xFFE4E1ED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.access_time_rounded,
                                      color: Color(0xFFB55700),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Time",
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: textMuted,
                                          ),
                                        ),
                                        Text(
                                          selectedTime.format(context),
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Bottom Fixed Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    bgColor.withValues(alpha: 0),
                    bgColor.withValues(alpha: 0.8),
                    bgColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: GestureDetector(
                onTap: _isLoading ? null : _saveRecord,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4143D5), Color(0xFF5B3CDD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4143D5).withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Save Transaction",
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension BackgroundExtension on Widget {
  Widget animateBlur() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: this,
    );
  }
}
