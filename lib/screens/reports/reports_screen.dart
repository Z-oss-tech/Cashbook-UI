import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/export_helper.dart';
import '../../core/theme/premium_themes.dart';
import '../../core/widgets/theme_background_wrapper.dart';
import '../../core/widgets/glass_card.dart';
import 'package:intl/intl.dart';
import 'cherry_reports_components.dart';

class ReportsScreen extends StatelessWidget {
  final String? cashbookName;

  const ReportsScreen({super.key, this.cashbookName});

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

  String formatCurrencyShort(double amount) {
    if (amount >= 1000) {
      return '₹ ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹ ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = Provider.of<RecordProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final premiumTheme = PremiumThemes.getTheme(settings.appTheme);
    final isDefault = settings.appTheme == 'Default';

    final allRecords = recordProvider.records;
    final records = cashbookName != null
        ? allRecords.where((r) => r.cashbookName == cashbookName).toList()
        : allRecords;

    final double totalReceived = records
        .where((r) => !r.isGiven)
        .fold(0, (s, r) => s + r.amount);
    final double totalGiven = records
        .where((r) => r.isGiven)
        .fold(0, (s, r) => s + r.amount);
    final double balance = totalReceived - totalGiven;

    // Weekly Analytics (Mon=0 to Sun=6)
    final List<double> weeklyData = List.filled(7, 0.0);
    final now = DateTime.now();
    for (var r in records) {
      if (now.difference(r.date).inDays <= 7) {
        weeklyData[r.date.weekday - 1] += r.amount;
      }
    }

    final monthName = DateFormat('MMMM yyyy').format(now);

    // Sort for recent events
    final sortedRecords = List<RecordModel>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentEvents = sortedRecords.take(3).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          cashbookName != null ? "$cashbookName Reports" : "Smart Analytics",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: isDefault
                  ? const LinearGradient(
                      colors: [Color(0xFF4143D5), Color(0xFF7459F7)],
                    )
                  : premiumTheme.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDefault
                              ? const Color(0xFF4143D5)
                              : premiumTheme.primaryColor)
                          .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ExportHelper.showExportOptions(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Export",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
      body: settings.appTheme == 'Cherry Blossom'
          ? FloatingPetalsBackground(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.2,
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCdfXLR2tCS9YpT8JQ0AdQEbU1Mis3pObtMYAs_qHXplGsSUIkBTeR7cA0zHiH8ICt3Qb00582xEbg1-FSc41m3B9XGiy85RUCzDEwvBWcoKvd2t45EvEFJOMOtxm_Kn-REdNzTwNjXsIdlHGCvAs4s4Cpfn9jk7UaVhpOxlagV4ynoVX1pv5dnElZfMwJh2HygLQF_vVWO63WJ6HA-3Me5iJWj9HAsRVGRaKepMZli11DXXjzIBJ5t',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CherryReportsComponents.buildSavingsCard(
                            context,
                            balance,
                            premiumTheme,
                          ),
                          const SizedBox(height: 24),
                          CherryReportsComponents.buildInsightsCard(
                            context,
                            weeklyData,
                            premiumTheme,
                          ),
                          const SizedBox(height: 24),
                          CherryReportsComponents.buildTopCategories(
                            context,
                            records,
                            premiumTheme,
                          ),
                          const SizedBox(height: 24),
                          CherryReportsComponents.buildRecentBloom(
                            context,
                            recentEvents,
                            premiumTheme,
                          ),
                          const SizedBox(height: 24),
                          // Keep existing cashflow mix card but styled inside a container if needed
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: premiumTheme.primaryColor.withValues(alpha: 
                                  0.1,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildCategoryMix(
                              context,
                              totalReceived,
                              totalGiven,
                              premiumTheme,
                              isDefault,
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ThemeBackgroundWrapper(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Titles
                      Text(
                        "Financial Bloom",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: isDefault
                              ? Colors.blueGrey
                              : premiumTheme.gradient.colors.last,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Monthly Analytics",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDefault
                              ? Colors.black87
                              : (premiumTheme.themeData.brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : premiumTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Month Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDefault
                                      ? Colors.grey
                                      : premiumTheme.primaryColor)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                (isDefault
                                        ? Colors.grey
                                        : premiumTheme.primaryColor)
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          monthName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDefault
                                ? Colors.black54
                                : (premiumTheme.themeData.brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : premiumTheme.gradient.colors.last),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 1. Summary Card
                      _buildSummaryCard(
                        context,
                        balance,
                        totalReceived,
                        totalGiven,
                        premiumTheme,
                        isDefault,
                      ),

                      const SizedBox(height: 20),

                      // 2. Spending Tendency (Bar Chart)
                      _buildSpendingTendency(
                        context,
                        weeklyData,
                        premiumTheme,
                        isDefault,
                      ),

                      const SizedBox(height: 20),

                      // 3. Category Mix (Donut Chart)
                      _buildCategoryMix(
                        context,
                        totalReceived,
                        totalGiven,
                        premiumTheme,
                        isDefault,
                      ),

                      const SizedBox(height: 20),

                      // 4. AI Insight Card
                      _buildInsightCard(
                        context,
                        totalReceived,
                        totalGiven,
                        balance,
                        premiumTheme,
                        isDefault,
                      ),

                      const SizedBox(height: 32),

                      // 5. Key Events
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Key Events",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDefault
                                  ? Colors.black87
                                  : (premiumTheme.themeData.brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : premiumTheme.primaryColor),
                            ),
                          ),
                          Text(
                            "View All",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDefault
                                  ? Colors.blue
                                  : premiumTheme.gradient.colors.last,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...recentEvents.map(
                        (r) => _buildEventTile(
                          context,
                          r,
                          premiumTheme,
                          isDefault,
                        ),
                      ),

                      const SizedBox(height: 100), // Bottom padding for Nav Bar
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double balance,
    double income,
    double expense,
    ThemeInfo premiumTheme,
    bool isDefault,
  ) {
    final secondaryTextColor = isDefault
        ? Colors.black54
        : (premiumTheme.themeData.brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54);
    final primaryColor = isDefault
        ? const Color(0xFF4143D5)
        : premiumTheme.primaryColor;
    final secondaryColor = isDefault
        ? const Color(0xFF7459F7)
        : premiumTheme.gradient.colors.last;

    final double total = income + expense;
    final double incomePercentage = total == 0 ? 0 : (income / total);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Net Balance",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Total Savings Growth",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  formatCurrency(balance),
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Progress Bar Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Income",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    formatCurrencyShort(income),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: secondaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: (incomePercentage * 100).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - incomePercentage) * 100).toInt(),
                      child: const SizedBox(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Expenses",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    formatCurrencyShort(expense),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
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

  Widget _buildSpendingTendency(
    BuildContext context,
    List<double> weeklyData,
    ThemeInfo premiumTheme,
    bool isDefault,
  ) {
    final primaryColor = isDefault
        ? const Color(0xFF4143D5)
        : premiumTheme.primaryColor;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Spending Tendency",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Amount",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                          "Sun",
                        ];
                        if (value >= 0 && value < 7) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < 7; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyData[i] == 0 ? 0.05 : weeklyData[i],
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.5),
                              primaryColor,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY:
                                weeklyData.reduce((a, b) => a > b ? a : b) *
                                    1.2 +
                                0.1,
                            color: primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMix(
    BuildContext context,
    double income,
    double expense,
    ThemeInfo premiumTheme,
    bool isDefault,
  ) {
    final primaryColor = isDefault
        ? const Color(0xFF4143D5)
        : premiumTheme.primaryColor;
    final secondaryColor = isDefault
        ? const Color(0xFF7459F7)
        : premiumTheme.gradient.colors.last;

    final double total = income + expense;
    final double incPct = total == 0 ? 50 : (income / total) * 100;
    final double expPct = total == 0 ? 50 : (expense / total) * 100;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "CASHFLOW MIX",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: primaryColor,
                        value: incPct,
                        title: '',
                        radius: 12,
                      ),
                      PieChartSectionData(
                        color: secondaryColor,
                        value: expPct,
                        title: '',
                        radius: 12,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: primaryColor,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                "Income",
                formatCurrencyShort(income),
                primaryColor,
              ),
              _buildLegendItem(
                "Expense",
                formatCurrencyShort(expense),
                secondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    double income,
    double expense,
    double balance,
    ThemeInfo premiumTheme,
    bool isDefault,
  ) {
    final primaryColor = isDefault
        ? const Color(0xFF4143D5)
        : premiumTheme.primaryColor;

    String insightText = "";
    if (balance > 0) {
      insightText =
          "You have a positive cashflow! You saved ${formatCurrencyShort(balance)} overall. Keeping this pace will help you reach your goals.";
    } else if (balance < 0) {
      insightText =
          "Your expenses are higher than income by ${formatCurrencyShort(balance.abs())}. Consider reviewing your recent expenditures to improve your savings.";
    } else {
      insightText =
          "Your income and expenses are perfectly balanced. Track your entries daily to maintain a healthy ledger.";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SmartKhata Insight",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insightText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: primaryColor.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        "View Details",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                      child: Text(
                        "Dismiss",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(
    BuildContext context,
    RecordModel record,
    ThemeInfo premiumTheme,
    bool isDefault,
  ) {
    final isExpense = record.isGiven;
    final amountColor = isExpense ? Colors.redAccent : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isExpense ? Colors.redAccent : Colors.green).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isExpense ? Icons.shopping_bag_rounded : Icons.payments_rounded,
                color: amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.personName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd').format(record.date) +
                        " • " +
                        (isExpense ? "Expense" : "Income"),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (isExpense ? "- " : "+ ") +
                      formatCurrencyShort(record.amount),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: amountColor,
                  ),
                ),
                if (record.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 80,
                    child: Text(
                      record.note,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
