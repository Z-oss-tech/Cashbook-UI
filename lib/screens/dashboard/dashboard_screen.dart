import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../people/people_list_screen.dart';
import '../records/cashbook_screen.dart';
import '../reports/reports_screen.dart';
import '../../core/utils/export_helper.dart';
import '../../core/utils/date_helper.dart';
import 'package:flutter/services.dart';

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
        formatted =
            '${beforeDecimal.substring(beforeDecimal.length - 2)},$formatted';
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
        formatted =
            '${beforeDecimal.substring(beforeDecimal.length - 2)},$formatted';
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

  void _showCreateCashbookDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isCreating = false;

    int selectedIconIndex = 0;
    int selectedColorIndex = 0;

    final List<IconData> icons = [
      Icons.account_balance_wallet,
      Icons.business,
      Icons.home,
      Icons.shopping_bag,
      Icons.directions_car,
    ];
    final List<Color> colors = [
      const Color(0xFF4143D5),
      const Color(0xFFFF6B6B),
      const Color(0xFF34D399),
      const Color(0xFFFBBF24),
      const Color(0xFFA855F7),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Create Cashbook",
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF191C1E),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(dialogContext),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFF5F2FE),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF4143D5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE4E1ED),
                      ),
                      // Body
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cashbook Name",
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF464555),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF191C1E),
                              ),
                              decoration: InputDecoration(
                                hintText: 'E.g. Office Expenses',
                                hintStyle: GoogleFonts.manrope(
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                                    : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              "Description (Optional)",
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF464555),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: descController,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF191C1E),
                              ),
                              decoration: InputDecoration(
                                hintText: 'What is this cashbook for?',
                                hintStyle: GoogleFonts.manrope(
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                                    : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              "Select Icon",
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF464555),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(icons.length, (index) {
                                final isSelected = selectedIconIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => selectedIconIndex = index);
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colors[selectedColorIndex]
                                                .withValues(alpha: 0.15)
                                          : (isDark
                                                ? Colors.white10
                                                : const Color(0xFFF5F2FE)),
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: colors[selectedColorIndex],
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Icon(
                                      icons[index],
                                      color: isSelected
                                          ? colors[selectedColorIndex]
                                          : (isDark
                                                ? Colors.white54
                                                : const Color(0xFF464555)),
                                      size: 24,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              "Select Color",
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF464555),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(colors.length, (index) {
                                final isSelected = selectedColorIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => selectedColorIndex = index);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colors[index],
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            )
                                          : null,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: colors[index].withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isCreating
                                    ? null
                                    : () async {
                                        HapticFeedback.mediumImpact();
                                        final cashbookName =
                                            nameController.text.trim().isEmpty
                                            ? "New Cashbook"
                                            : nameController.text.trim();

                                        setState(() => isCreating = true);
                                        await Provider.of<RecordProvider>(
                                          context,
                                          listen: false,
                                        ).addCashbook(cashbookName);
                                        setState(() => isCreating = false);

                                        if (context.mounted) {
                                          Navigator.pop(
                                            dialogContext,
                                          ); // Close dialog
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CashbookScreen(
                                                cashbookName: cashbookName,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors[selectedColorIndex],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: colors[selectedColorIndex]
                                      .withValues(alpha: 0.5),
                                ),
                                child: isCreating
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        "CREATE CASHBOOK",
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4143D5),
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  // Simulate refresh or re-fetch logic if any
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
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
                        _buildQuickStats(
                          context,
                          thisWeekAmount,
                          recordProvider.cashbooks.length,
                          recordProvider.records.length,
                        ),
                        const SizedBox(height: 32),
                        _buildProductivitySection(context),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30));
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
                  Icon(Icons.menu_rounded, color: textColor, size: 28),
                  const SizedBox(width: 16),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC0C1FF),
                        width: 2,
                      ),
                      gradient: LinearGradient(
                        colors: [Theme.of(context).primaryColor, AppColors.secondary],
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
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPremiumBalanceCard(
    BuildContext context,
    double balance,
    double income,
    double expense,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
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
              color: const Color(0xFF4143D5).withValues(alpha: 0.4),
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
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "TOTAL BALANCE",
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
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
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Received",
                              style: GoogleFonts.inter(
                                color: Theme.of(context).cardColor.withValues(alpha: 0.9),
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
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Given",
                              style: GoogleFonts.inter(
                                color: Theme.of(context).cardColor.withValues(alpha: 0.9),
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
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    double thisWeekAmount,
    int booksCount,
    int totalTxns,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF464555)
        : const Color(0xFFE6E8EA);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30));
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF464555);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildStatCard(
            context,
            title: "Weekly Summary",
            value: formatCurrencyShort(thisWeekAmount),
            icon: Icons.insights_rounded,
            color: const Color(0xFF4143D5),
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            context,
            title: "Active Cashbooks",
            value: "$booksCount",
            icon: Icons.book_rounded,
            color: const Color(0xFF5B3CDD),
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PeopleListScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            context,
            title: "Total Transactions",
            value: "$totalTxns",
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF008339),
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                color: subTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivitySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30));
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Productivity",
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildProductivityCard(
                context,
                title: "Continue Last Book",
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFF4143D5),
                onTap: () {
                  if (recordProvider.cashbooks.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CashbookScreen(
                          cashbookName: recordProvider.cashbooks.first.name,
                        ),
                      ),
                    );
                  } else {
                    _showCreateCashbookDialog(context);
                  }
                },
              ),
              const SizedBox(width: 16),
              _buildProductivityCard(
                context,
                title: "Smart Insights",
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF008339),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildProductivityCard(
                context,
                title: "Export",
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFE53935),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ExportHelper.showExportOptions(context);
                },
              ),
              const SizedBox(width: 16),
              _buildProductivityCard(
                context,
                title: "Pending Sync",
                icon: Icons.cloud_upload_rounded,
                color: const Color(0xFF5B3CDD),
                onTap: () {
                  recordProvider.syncOfflineQueue();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manual sync triggered')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF464555)
        : const Color(0xFFE6E8EA);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashbookListHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30));

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
    final displayCashbooks = allCashbooks.length > 5
        ? allCashbooks.sublist(0, 5)
        : allCashbooks;

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
        final records = recordProvider.records.where(
          (r) => r.cashbookName == name,
        );
        final double received = records
            .where((r) => !r.isGiven)
            .fold(0, (s, r) => s + r.amount);
        final double given = records
            .where((r) => r.isGiven)
            .fold(0, (s, r) => s + r.amount);
        final double balance = received - given;
        final bool isPositive = balance >= 0;
        final String amountText =
            "${isPositive ? '+' : '-'} ${formatCurrencyNoDecimal(balance)}";

        return _buildCashbookTile(
          context: context,
          cashbook: cashbook,
          date: DateHelper.formatDateTime(cashbook.createdAt),
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
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF464555)
        : const Color(0xFFE6E8EA);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30));
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF464555);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CashbookScreen(cashbookName: cashbook.name),
          ),
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
              color: Colors.black.withValues(alpha: 0.02),
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
                      _showEditDialog(context, cashbook.id, cashbook.name);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, cashbook.id, cashbook.name);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: textColor),
                          const SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: GoogleFonts.inter(color: textColor),
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
            const SizedBox(height: 16),
            Divider(color: borderColor, height: 1),
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
                        color: isPositive
                            ? (isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF008339))
                            : (isDark
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFE53935)),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "Details",
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : subTextColor,
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

  void _showEditDialog(BuildContext context, String id, String currentName) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Edit Cashbook",
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Cashbook Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4143D5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  Provider.of<RecordProvider>(
                    context,
                    listen: false,
                  ).updateCashbook(id, newName);
                }
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete Cashbook",
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to delete '$name'? This action can be undone via Recovery Bin within 30 days.",
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Provider.of<RecordProvider>(
                  context,
                  listen: false,
                ).deleteCashbook(id);
                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
