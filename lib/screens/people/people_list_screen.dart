import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/record_provider.dart';
import '../records/cashbook_screen.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Helper to format currency
  String formatCurrencyNoDecimal(double amount) {
    final double absoluteAmount = amount.abs();
    String beforeDecimal = absoluteAmount.toStringAsFixed(0);
    
    if (beforeDecimal.length > 3) {
      String formatted = beforeDecimal.substring(beforeDecimal.length - 3);
      beforeDecimal = beforeDecimal.substring(0, beforeDecimal.length - 3);
      while (beforeDecimal.length > 2) {
        formatted = '${beforeDecimal.substring(beforeDecimal.length - 2)},$formatted';
        beforeDecimal = beforeDecimal.substring(0, beforeDecimal.length - 2);
      }
      formatted = '$beforeDecimal,$formatted';
      beforeDecimal = formatted;
    }
    return '₹ $beforeDecimal';
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = Provider.of<RecordProvider>(context);
    final cashbookList = recordProvider.cashbooks.where((book) {
      return book.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "All Books",
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search books...",
                  hintStyle: GoogleFonts.poppins(),
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Cashbook Cards
            Expanded(
              child: ListView.builder(
                itemCount: cashbookList.length,
                itemBuilder: (context, index) {
                  final cashbook = cashbookList[index];
                  final name = cashbook.name;
                  final date = "${cashbook.createdAt.day}/${cashbook.createdAt.month}/${cashbook.createdAt.year}";

                  // Calculate Balance
                  final records = recordProvider.records.where((r) => r.cashbookName == name);
                  final double received = records.where((r) => !r.isGiven).fold(0, (s, r) => s + r.amount);
                  final double given = records.where((r) => r.isGiven).fold(0, (s, r) => s + r.amount);
                  final double balance = received - given;
                  final bool isPositive = balance >= 0;

                  final String amountText = "${isPositive ? '+' : '-'} ${formatCurrencyNoDecimal(balance)}";

                  return _buildBookCard(
                    name: name,
                    date: date,
                    amount: amountText,
                    isPositive: isPositive,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard({
    required String name,
    required String date,
    required String amount,
    required bool isPositive,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CashbookScreen(cashbookName: name)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Created on $date",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}