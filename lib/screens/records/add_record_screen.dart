import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/record_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/animation_helper.dart';
import '../../core/utils/toast_helper.dart';
import '../../widgets/calculator_dialog.dart';

class AddRecordScreen extends StatefulWidget {
  final String cashbookName;

  const AddRecordScreen({super.key, this.cashbookName = 'TestBook'});

  @override
  State<AddRecordScreen> createState() =>
      _AddRecordScreenState();
}

class _AddRecordScreenState
    extends State<AddRecordScreen> {

  bool isGiven = true;
  bool _isLoading = false;
  String? selectedReason;

  final List<String> givenReasons = [
    'Supplier / Vendor Payment',
    'Groceries & Supplies',
    'Rent / EMI',
    'Utilities / Bills',
    'Transportation',
    'Food / Dining',
    'Loan Given',
    'Health / Medical',
    'Maintenance & Repairs',
    'Entertainment',
    'Other'
  ];

  final List<String> receivedReasons = [
    'Sales / Business Income',
    'Salary / Wages',
    'Freelance / Project Advance',
    'Loan Repayment',
    'Rental Income',
    'Cashback / Reward',
    'Sold Item',
    'Interest / Dividends',
    'Pocket Money',
    'Other'
  ];

  final TextEditingController amountController =
  TextEditingController();

  final TextEditingController noteController =
  TextEditingController();

  DateTime selectedDate = DateTime.now();

  void _saveRecord() async {
    final String amountText = amountController.text.trim();
    final String note = noteController.text.trim();

    if (amountText.isEmpty) {
      ToastHelper.showToast(context, "Please enter an amount", isError: true);
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ToastHelper.showToast(context, "Please enter a valid amount greater than 0", isError: true);
      return;
    }

    final recordProvider = Provider.of<RecordProvider>(context, listen: false);

    final cashbook = recordProvider.cashbooks.firstWhere(
      (c) => c.name == widget.cashbookName, 
      orElse: () => recordProvider.cashbooks.isNotEmpty 
          ? recordProvider.cashbooks.first 
          : CashbookModel(id: '', name: widget.cashbookName, createdAt: DateTime.now())
    );

    final String defaultTitle = selectedReason ?? (isGiven ? 'Expense' : 'Income');
    final String finalTitle = note.isEmpty ? defaultTitle : note;
    
    final record = RecordModel(
      id: '',
      cashbookId: cashbook.id,
      title: finalTitle,
      amount: amount,
      type: isGiven ? 'expense' : 'income',
      category: selectedReason,
      note: note.isEmpty ? defaultTitle : note,
      date: selectedDate,
      cashbookName: widget.cashbookName,
    );

    setState(() { _isLoading = true; });
    await recordProvider.addRecord(record);
    if (mounted) setState(() { _isLoading = false; });

    if (!mounted) return;

    if (recordProvider.error != null) {
      ToastHelper.showToast(context, recordProvider.error!, isError: true);
      return;
    }

    ToastHelper.showToast(context, "Record saved successfully!");

    // Call emoji animation before popping
    // isGiven represents Expense/Gave, so !isGiven is Income/Received
    AnimationHelper.showEmojiAnimation(context, isIncome: !isGiven, amount: amount);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: Text(
          AppLocalizations.of(context)!.addRecord,
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 28),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CalculatorDialog(
                  onResult: (result) {
                    if (result.isNotEmpty && result != '0') {
                      amountController.text = result;
                    }
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const SizedBox(height: 10),

            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 30,
              ),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),

                gradient: LinearGradient(
                  colors: isGiven
                      ? [
                    Colors.red.shade400,
                    Colors.red.shade600,
                  ]
                      : [
                    Colors.green.shade400,
                    Colors.green.shade600,
                  ],
                ),

                boxShadow: [
                  BoxShadow(
                    color: (isGiven
                        ? Colors.red
                        : Colors.green)
                        .withOpacity(0.25),

                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Column(
                children: [

                  Text(
                    isGiven
                        ? "You Gave"
                        : "You Received",

                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,

                    textAlign: TextAlign.center,

                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),

                    decoration: InputDecoration(
                      border: InputBorder.none,

                      hintText: "₹ 0",

                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Toggle Buttons
            Row(
              children: [

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!isGiven) {
                        setState(() {
                          isGiven = true;
                          selectedReason = null;
                        });
                      }
                    },

                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 250),

                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      decoration: BoxDecoration(
                        color: isGiven
                            ? Colors.red
                            : Colors.white,

                        borderRadius:
                        BorderRadius.circular(18),
                      ),

                      child: Center(
                        child: Text(
                          "📤 You Gave",

                          style: GoogleFonts.poppins(
                            color: isGiven
                                ? Colors.white
                                : Colors.black,

                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isGiven) {
                        setState(() {
                          isGiven = false;
                          selectedReason = null;
                        });
                      }
                    },

                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 250),

                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      decoration: BoxDecoration(
                        color: !isGiven
                            ? Colors.green
                            : Colors.white,

                        borderRadius:
                        BorderRadius.circular(18),
                      ),

                      child: Center(
                        child: Text(
                          "📥 You Received",

                          style: GoogleFonts.poppins(
                            color: !isGiven
                                ? Colors.white
                                : Colors.black,

                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Category Dropdown
            _buildLabel("Category / Reason"),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedReason,
                  hint: Text(
                    "Select a reason",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                  items: (isGiven ? givenReasons : receivedReasons).map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedReason = newValue;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Note
            _buildLabel(AppLocalizations.of(context)!.note),

            const SizedBox(height: 10),

            _buildTextField(
              controller: noteController,
              hint: "Add a note",
              icon: Icons.notes_rounded,
            ),

            const SizedBox(height: 24),

            // Date Picker
            _buildLabel(AppLocalizations.of(context)!.date),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: () async {

                DateTime? pickedDate =
                await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                );

                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),

                decoration: BoxDecoration(
color: Theme.of(context).cardColor,
                  borderRadius:
                  BorderRadius.circular(18),
                ),

                child: Row(
                  children: [

                    const Icon(
                      Icons.calendar_month_rounded,
                    ),

                    const SizedBox(width: 14),

                    Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",

                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                ),

                onPressed: _isLoading ? null : _saveRecord,

                child: _isLoading 
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        "Save Record",

                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Text(
      title,

      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),

      child: TextField(
        controller: controller,

        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(),

          icon: Icon(icon),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}