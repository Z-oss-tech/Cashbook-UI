import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../people/people_list_screen.dart';
import '../records/cashbook_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String formatCurrency(double amount) {
    final String sign = amount < 0 ? '-' : '';
    final double absoluteAmount = amount.abs();
    final List<String> parts = absoluteAmount.toStringAsFixed(2).split('.');
    String beforeDecimal = parts[0];
    final String afterDecimal = parts[1];
    
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
    return '$sign₹ $beforeDecimal.$afterDecimal';
  }

  String formatCurrencyNoDecimal(double amount) {
    final String sign = amount < 0 ? '-' : '';
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
    return '$sign₹ $beforeDecimal';
  }

  String formatCurrencyShort(double amount) {
    if (amount.abs() >= 1000) {
      final double kValue = amount / 1000;
      if (kValue == kValue.toInt().toDouble()) {
        return '₹ ${kValue.toInt()}K';
      } else {
        return '₹ ${kValue.toStringAsFixed(1)}K';
      }
    }
    return '₹ ${amount.toInt()}';
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      // Keep existing localization if possible, otherwise fallback
      try {
        return AppLocalizations.of(context)!.goodMorning;
      } catch (_) {
        return "Good Morning";
      }
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = Provider.of<RecordProvider>(context);

    // Calculate this week's volume
    double thisWeekAmount = 0.0;
    final now = DateTime.now();
    for (var record in recordProvider.records) {
      if (now.difference(record.date).inDays <= 7) {
        thisWeekAmount += record.amount;
      }
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildTopHeader(context),
                const SizedBox(height: 30),
                _buildMainBalanceCard(
                  context,
                  recordProvider.balance,
                  recordProvider.totalReceived,
                  recordProvider.totalGiven,
                ),
                const SizedBox(height: 28),
                _buildAnalyticsSection(
                  context,
                  thisWeekAmount,
                  recordProvider.cashbooks.length,
                ),
                const SizedBox(height: 30),
                _buildCashbookListHeader(context),
                const SizedBox(height: 18),
                _buildCashbookList(context),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (innerContext) => GestureDetector(
                onTap: () {
                  Scaffold.of(innerContext).openDrawer();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(context) + " 👋",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return Text(
                      settings.userName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainBalanceCard(BuildContext context, double balance, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.totalBalance,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(balance),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBalanceItem(
                    context: context,
                    title: AppLocalizations.of(context)!.totalReceived,
                    amount: formatCurrency(income),
                    icon: Icons.arrow_downward_rounded,
                    isIncome: true,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  _buildBalanceItem(
                    context: context,
                    title: AppLocalizations.of(context)!.totalGiven,
                    amount: formatCurrency(expense),
                    icon: Icons.arrow_upward_rounded,
                    isIncome: false,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    required BuildContext context,
    required String title,
    required String amount,
    required IconData icon,
    required bool isIncome,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, double thisWeekAmount, int booksCount) {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            context: context,
            title: AppLocalizations.of(context)!.thisWeek,
            value: formatCurrencyShort(thisWeekAmount),
            icon: Icons.access_time_rounded,
            color: const Color(0xFFFF9800),
            gradientColors: [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PeopleListScreen()),
              );
            },
            child: _buildAnalyticsCard(
              context: context,
              title: "Books",
              value: "$booksCount",
              icon: Icons.library_books_rounded,
              color: AppColors.success,
              gradientColors: [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.grey.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashbookListHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Your Cashbooks",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PeopleListScreen()),
            );
          },
          child: Text(
            "View All",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashbookList(BuildContext context) {
    final recordProvider = Provider.of<RecordProvider>(context);
    final allCashbooks = recordProvider.cashbooks;
    final displayCashbooks = allCashbooks.length > 5 ? allCashbooks.sublist(0, 5) : allCashbooks;

    // Helper to format currency
    String formatCurrencyNoDecimalLocal(double amount) {
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

    return Column(
      children: displayCashbooks.map((cashbook) {
        final name = cashbook.name;
        final records = recordProvider.records.where((r) => r.cashbookName == name);
        final double received = records.where((r) => !r.isGiven).fold(0, (s, r) => s + r.amount);
        final double given = records.where((r) => r.isGiven).fold(0, (s, r) => s + r.amount);
        final double balance = received - given;
        final bool isPositive = balance >= 0;
        final String amountText = "${isPositive ? '+' : '-'} ${formatCurrencyNoDecimalLocal(balance)}";

        return _buildCashbookTile(
          context: context,
          cashbook: cashbook,
          date: "${cashbook.createdAt.day}/${cashbook.createdAt.month}/${cashbook.createdAt.year}",
          amount: amountText,
          isPositive: isPositive,
        );
      }).toList(),
    );
  }

  void _showEditCashbookDialog(BuildContext context, CashbookModel cashbook) {
    final TextEditingController nameController = TextEditingController(text: cashbook.name);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Edit Cashbook", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'New name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != cashbook.name) {
                  Provider.of<RecordProvider>(context, listen: false).updateCashbook(cashbook.id, newName);
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Save", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCashbookDialog(BuildContext context, CashbookModel cashbook) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Delete Cashbook", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text("Are you sure you want to delete '${cashbook.name}'? This will permanently delete all records inside it.", style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<RecordProvider>(context, listen: false).deleteCashbook(cashbook.id);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Delete", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCashbookTile({
    required BuildContext context,
    required CashbookModel cashbook,
    required String date,
    required String amount,
    required bool isPositive,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CashbookScreen(cashbookName: cashbook.name)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
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
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Created on $date",
                    style: GoogleFonts.poppins(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') {
                  // Show edit dialog
                  _showEditCashbookDialog(context, cashbook);
                } else if (value == 'delete') {
                  // Show delete confirmation
                  _showDeleteCashbookDialog(context, cashbook);
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
          ],
        ),
      ),
    );
  }
}
