import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../core/constants/app_colors.dart';
import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../people/people_list_screen.dart';
import '../records/cashbook_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/backup_restore_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate this week's volume
    double thisWeekAmount = 0.0;
    final now = DateTime.now();
    for (var record in recordProvider.records) {
      if (now.difference(record.date).inDays <= 7) {
        thisWeekAmount += record.amount;
      }
    }

    return Container(
      color: isDark ? const Color(0xFF191C1E) : const Color(0xFFF7F9FB),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildPremiumBalanceCard(
                        context,
                        recordProvider.balance,
                        recordProvider.totalReceived,
                        recordProvider.totalGiven,
                      ),
                      const SizedBox(height: 32),
                      _buildQuickStats(context, thisWeekAmount, recordProvider.cashbooks.length),
                      const SizedBox(height: 32),
                      _buildQuickActions(context),
                      const SizedBox(height: 32),
                      _buildCashbookListHeader(context),
                      const SizedBox(height: 16),
                      _buildCashbookList(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF464555);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (innerContext) => GestureDetector(
              onTap: () {
                Scaffold.of(innerContext).openDrawer();
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC0C1FF), width: 2),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: Center(
                      child: Consumer<SettingsProvider>(
                        builder: (context, settings, child) {
                          return Text(
                            settings.userAvatar,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_getGreeting(context)} 👋",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Consumer<SettingsProvider>(
                        builder: (context, settings, child) {
                          return Text(
                            settings.userName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Icon(Icons.search_rounded, color: subTextColor),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(Icons.notifications_rounded, color: subTextColor),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA1A1A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF191C1E) : const Color(0xFFF7F9FB), 
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBalanceCard(BuildContext context, double balance, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4143D5), // rgb(65, 67, 213)
            Color(0xFF7459F7), // rgb(116, 89, 247)
            Color(0xFF2C2CC3), // rgb(44, 44, 195)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4143D5).withOpacity(0.4),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "TOTAL BALANCE",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(balance),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Received",
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrencyShort(income),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Given",
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrencyShort(expense),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, double thisWeekAmount, int booksCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2D3133) : Colors.white;
    final borderColor = isDark ? const Color(0xFF464555) : const Color(0xFFE6E8EA);
    final textColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF464555);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4143D5).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.insights_rounded, color: Color(0xFF4143D5), size: 20),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Color(0xFF008339), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "12%",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF008339),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Weekly Summary",
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrencyShort(thisWeekAmount),
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B3CDD).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.book_rounded, color: Color(0xFF5B3CDD), size: 20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Cashbooks",
                    style: GoogleFonts.inter(
                      color: subTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$booksCount Active",
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF191C1E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              context,
              icon: Icons.library_add_rounded,
              label: "Add Book",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PeopleListScreen()));
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.cloud_upload_rounded,
              label: "Backup",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen()));
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.file_download_rounded,
              label: "Export",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.bar_chart_rounded,
              label: "Reports",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF464555);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D3133) : const Color(0xFFF2F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFF4143D5), size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashbookListHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF191C1E);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Recent Cashbooks",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
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
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4143D5),
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

    if (displayCashbooks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "No active cashbooks yet.",
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: displayCashbooks.map((cashbook) {
        final name = cashbook.name;
        final records = recordProvider.records.where((r) => r.cashbookName == name);
        final double received = records.where((r) => !r.isGiven).fold(0, (s, r) => s + r.amount);
        final double given = records.where((r) => r.isGiven).fold(0, (s, r) => s + r.amount);
        final double balance = received - given;
        final bool isPositive = balance >= 0;
        final String amountText = "${isPositive ? '+' : '-'} ${formatCurrencyNoDecimal(balance)}";

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

  Widget _buildCashbookTile({
    required BuildContext context,
    required CashbookModel cashbook,
    required String date,
    required String amount,
    required bool isPositive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2D3133) : Colors.white;
    final borderColor = isDark ? const Color(0xFF464555) : const Color(0xFFE6E8EA);
    final textColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF464555);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CashbookScreen(cashbookName: cashbook.name)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEF0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF5B5FEF),
                    size: 24,
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
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Created on $date",
                        style: GoogleFonts.inter(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: subTextColor),
                  onSelected: (value) {
                    if (value == 'edit') {
                      // Original edit logic would go here
                    } else if (value == 'delete') {
                      // Original delete logic would go here
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: textColor),
                          const SizedBox(width: 8),
                          Text('Edit', style: GoogleFonts.inter(color: textColor)),
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
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE6E8EA), height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Net Balance",
                      style: GoogleFonts.inter(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF008339),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "Details",
                    style: GoogleFonts.inter(
                      color: subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
