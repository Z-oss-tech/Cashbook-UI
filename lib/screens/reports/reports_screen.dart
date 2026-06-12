import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

import 'package:provider/provider.dart';
import '../../providers/record_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/export_helper.dart';
import 'package:flutter/services.dart';

class ReportsScreen extends StatelessWidget {
  final String? cashbookName;
  
  const ReportsScreen({super.key, this.cashbookName});

  // Helper to format currency
  String formatCurrencyShort(double amount) {
    if (amount >= 1000) {
      return '₹ ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹ ${amount.toStringAsFixed(0)}';
  }

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

  @override
  Widget build(BuildContext context) {
    final recordProvider = Provider.of<RecordProvider>(context);
    final allRecords = recordProvider.records;
    final records = cashbookName != null 
        ? allRecords.where((r) => r.cashbookName == cashbookName).toList() 
        : allRecords;
        
    final double totalReceived = records.where((r) => !r.isGiven).fold(0, (s, r) => s + r.amount);
    final double totalGiven = records.where((r) => r.isGiven).fold(0, (s, r) => s + r.amount);
    final double balance = totalReceived - totalGiven;

    // 1. Weekly Analytics (Mon=1 to Sun=7)
    final List<double> weeklyData = List.filled(7, 0.0);
    final now = DateTime.now();
    for (var r in records) {
      // only consider records from the last 7 days to show in the week chart
      if (now.difference(r.date).inDays <= 7) {
         weeklyData[r.date.weekday - 1] += r.amount;
      }
    }

    // 2. Highest Insights
    RecordModel? highestReceived;
    RecordModel? highestGiven;
    for (var r in records) {
       if (!r.isGiven) {
          if (highestReceived == null || r.amount > highestReceived.amount) highestReceived = r;
       } else {
          if (highestGiven == null || r.amount > highestGiven.amount) highestGiven = r;
       }
    }

    // 3. Stats Data
    final double thisWeekAmount = records
        .where((r) => now.difference(r.date).inDays <= 7)
        .fold(0.0, (s, r) => s + r.amount);
        
    final double avgTransaction = records.isNotEmpty ? (totalGiven + totalReceived) / records.length : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: Text(
          cashbookName != null ? "$cashbookName Reports" : "Reports & Insights",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              ExportHelper.showExportOptions(context);
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildMainBalanceCard(
                 context,
                 balance,
                 totalReceived,
                 totalGiven,
               ),
               
               const SizedBox(height: 30),

               Text(
                 "Weekly Volume",
                 style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 20),
               Container(
                 height: 260,
                 padding: const EdgeInsets.all(18),
                 decoration: BoxDecoration(
                   color: Theme.of(context).cardColor,
                   borderRadius: BorderRadius.circular(28),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.04),
                       blurRadius: 10,
                       offset: const Offset(0, 4),
                     ),
                   ],
                 ),
                 child: BarChart(
                   BarChartData(
                     alignment: BarChartAlignment.spaceAround,
                     borderData: FlBorderData(show: false),
                     gridData: FlGridData(show: false),
                     titlesData: FlTitlesData(
                       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       bottomTitles: AxisTitles(
                         sideTitles: SideTitles(
                           showTitles: true,
                           getTitlesWidget: (value, meta) {
                             const days = ["M", "T", "W", "T", "F", "S", "S"];
                             if (value >= 0 && value < 7) {
                               return Padding(
                                 padding: const EdgeInsets.only(top: 10),
                                 child: Text(
                                   days[value.toInt()],
                                   style: GoogleFonts.poppins(fontSize: 12),
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
                         _buildBar(i, weeklyData[i]),
                     ],
                   ),
                 ),
               ),

               const SizedBox(height: 30),

               Text(
                 "Smart Insights",
                 style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 18),
               
               if (highestReceived != null)
                 _buildInsightCard(
                   context: context,
                   icon: Icons.trending_up,
                   title: "Highest Received",
                   subtitle: "You received ₹${highestReceived.amount.toStringAsFixed(0)} for '${highestReceived.personName}'.",
                   color: Colors.green,
                 ),
                 
               if (highestGiven != null)
                 _buildInsightCard(
                   context: context,
                   icon: Icons.warning_rounded,
                   title: "Highest Expense",
                   subtitle: "You spent ₹${highestGiven.amount.toStringAsFixed(0)} for '${highestGiven.personName}'.",
                   color: Colors.orange,
                 ),
                 
               if (records.isNotEmpty)
                 _buildInsightCard(
                   context: context,
                   icon: Icons.auto_awesome,
                   title: "Net Position",
                   subtitle: balance >= 0 
                      ? "Great job! You are positive by ₹${balance.toStringAsFixed(0)}."
                      : "Careful! You have spent ₹${balance.abs().toStringAsFixed(0)} more than you received.",
                   color: Colors.purple,
                 ),
                 
               if (records.isEmpty)
                 Center(
                   child: Text(
                     "No data available for insights yet.",
                     style: GoogleFonts.poppins(color: Colors.grey),
                   ),
                 ),

               const SizedBox(height: 30),

               Row(
                 children: [
                   Expanded(
                     child: _buildStatsCard(
                       context: context,
                       title: "Total Records",
                       value: "${records.length}",
                       color: Colors.blue,
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _buildStatsCard(
                       context: context,
                       title: "Avg Entry",
                       value: formatCurrencyShort(avgTransaction),
                       color: Colors.green,
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(
                     child: _buildStatsCard(
                       context: context,
                       title: AppLocalizations.of(context)!.thisWeek,
                       value: formatCurrencyShort(thisWeekAmount),
                       color: Colors.orange,
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _buildStatsCard(
                       context: context,
                       title: "Net Balance",
                       value: formatCurrencyShort(balance),
                       color: balance >= 0 ? Colors.purple : Colors.red,
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard(BuildContext context, double balance, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6), // Vibrant premium blue
            Color(0xFF1D4ED8), // Deep blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Abstract geometric shapes for a modern look
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.0)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.15)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -10,
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.totalBalance,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(balance),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildBalanceItem(
                        context: context,
                        title: AppLocalizations.of(context)!.totalReceived,
                        amount: formatCurrencyShort(income),
                        icon: Icons.south_west_rounded,
                        isIncome: true,
                        iconColor: const Color(0xFF68D391), // Soft Green
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: _buildBalanceItem(
                          context: context,
                          title: AppLocalizations.of(context)!.totalGiven,
                          amount: formatCurrencyShort(expense),
                          icon: Icons.north_east_rounded,
                          isIncome: false,
                          iconColor: const Color(0xFFFC8181), // Soft Red
                        ),
                      ),
                    ),
                  ],
                ),
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
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    // Ensure bar height is visible even if small, but proportional
    // For very small relative values, fl_chart handles scale.
    // If y is 0, give it a tiny height so it renders a flat line.
    final displayY = y == 0 ? 0.05 : y; 
    
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: displayY,
          width: 18,
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
    );
  }
}
