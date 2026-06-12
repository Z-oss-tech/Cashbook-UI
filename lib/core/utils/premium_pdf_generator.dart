import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_model.dart';
import '../../providers/settings_provider.dart';
import 'toast_helper.dart';
import 'date_helper.dart';

class PremiumPdfGenerator {
  static final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static String _formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static Future<void> generateAndSharePdf(BuildContext context, List<RecordModel> records, String? cashbookName) async {
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final userName = settings.userName;

      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

      final pdf = pw.Document(theme: theme);
      final isGlobal = cashbookName == null;
      final title = isGlobal ? "All Cashbooks Financial Report" : "$cashbookName Report";
      final subtitle = "AI Powered Financial Analysis Report";

      // --- STATISTICS CALCULATION ---
      final sortedRecords = List<RecordModel>.from(records)..sort((a, b) => a.date.compareTo(b.date));
      
      double totalIncome = 0;
      double totalExpense = 0;
      RecordModel? highestIncome;
      RecordModel? highestExpense;
      RecordModel? lowestIncome;
      RecordModel? lowestExpense;
      DateTime? firstDate;
      DateTime? lastDate;

      Map<String, double> categoryIncome = {};
      Map<String, double> categoryExpense = {};
      Map<String, int> categoryCount = {};
      Map<String, RecordModel> catHighestTxn = {};
      Map<String, RecordModel> catLowestTxn = {};
      
      Map<String, double> monthlyIncome = {};
      Map<String, double> monthlyExpense = {};
      Map<String, int> monthlyCount = {};
      
      Map<String, double> dailyIncome = {};
      Map<String, double> dailyExpense = {};

      List<RecordModel> incomeRecords = [];
      List<RecordModel> expenseRecords = [];

      for (var r in sortedRecords) {
        if (firstDate == null || r.date.isBefore(firstDate!)) firstDate = r.date;
        if (lastDate == null || r.date.isAfter(lastDate!)) lastDate = r.date;

        String cat = (r.category != null && r.category!.isNotEmpty) ? r.category! : 'General';
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
        
        if (catHighestTxn[cat] == null || r.amount > catHighestTxn[cat]!.amount) catHighestTxn[cat] = r;
        if (catLowestTxn[cat] == null || r.amount < catLowestTxn[cat]!.amount) catLowestTxn[cat] = r;

        String monthKey = DateFormat('MMM yyyy').format(r.date);
        String dayKey = DateFormat('dd MMM').format(r.date);
        
        monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;

        if (r.isGiven) {
          totalExpense += r.amount;
          categoryExpense[cat] = (categoryExpense[cat] ?? 0) + r.amount;
          monthlyExpense[monthKey] = (monthlyExpense[monthKey] ?? 0) + r.amount;
          dailyExpense[dayKey] = (dailyExpense[dayKey] ?? 0) + r.amount;
          expenseRecords.add(r);
          if (highestExpense == null || r.amount > highestExpense!.amount) highestExpense = r;
          if (lowestExpense == null || r.amount < lowestExpense!.amount) lowestExpense = r;
        } else {
          totalIncome += r.amount;
          categoryIncome[cat] = (categoryIncome[cat] ?? 0) + r.amount;
          monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + r.amount;
          dailyIncome[dayKey] = (dailyIncome[dayKey] ?? 0) + r.amount;
          incomeRecords.add(r);
          if (highestIncome == null || r.amount > highestIncome!.amount) highestIncome = r;
          if (lowestIncome == null || r.amount < lowestIncome!.amount) lowestIncome = r;
        }
      }

      double netBalance = totalIncome - totalExpense;
      int totalTransactions = sortedRecords.length;
      double avgTransaction = totalTransactions > 0 ? (totalIncome + totalExpense) / totalTransactions : 0;
      double avgIncome = incomeRecords.isNotEmpty ? totalIncome / incomeRecords.length : 0;
      double avgExpense = expenseRecords.isNotEmpty ? totalExpense / expenseRecords.length : 0;
      
      double expenseToIncomeRatio = totalIncome > 0 ? (totalExpense / totalIncome) * 100 : 0;
      double netProfitPct = totalIncome > 0 ? (netBalance / totalIncome) * 100 : 0;

      // Medians
      double medianTxn = 0;
      if (sortedRecords.isNotEmpty) {
        final amounts = sortedRecords.map((r) => r.amount).toList()..sort();
        if (amounts.length % 2 == 1) {
          medianTxn = amounts[amounts.length ~/ 2];
        } else {
          medianTxn = (amounts[(amounts.length ~/ 2) - 1] + amounts[amounts.length ~/ 2]) / 2.0;
        }
      }

      String largestCategory = "None";
      int maxCatCount = 0;
      categoryCount.forEach((key, value) {
        if (value > maxCatCount) {
          maxCatCount = value;
          largestCategory = key;
        }
      });

      // Compute Health Score
      int score = 100;
      if (totalIncome == 0 && totalExpense > 0) score = 20;
      else if (totalIncome > 0) {
        double savingRate = netBalance / totalIncome;
        if (savingRate < 0) score -= 40;
        else if (savingRate < 0.1) score -= 20;
        else if (savingRate < 0.2) score -= 10;
      }
      if (expenseRecords.length > incomeRecords.length * 5) score -= 10;
      score = score.clamp(0, 100);

      String grade = score >= 90 ? "A+" : (score >= 80 ? "A" : (score >= 60 ? "B" : (score >= 40 ? "C" : "D")));
      String scoreText = score >= 80 ? "Excellent" : (score >= 60 ? "Good" : (score >= 40 ? "Fair" : "Needs Improvement"));
      PdfColor scoreColor = score >= 60 ? PdfColor.fromHex('#008339') : (score >= 40 ? PdfColor.fromHex('#F57F17') : PdfColor.fromHex('#E53935'));
      
      String aiRecommendation = score >= 80 
          ? "Your finances are extremely healthy with well-controlled expenses and positive cash flow. Keep up the great work!"
          : (score >= 60 
            ? "Your finances are stable. However, identifying and reducing unnecessary expenses could help improve your savings rate further."
            : "Action required. Your expenses are disproportionately high. It is highly recommended to review large expenditures immediately.");

      // Generate 10+ Smart Insights
      List<String> insights = [];
      if (highestExpense != null) insights.add("Largest Expense: Your highest single expense was ${_formatCurrency(highestExpense!.amount)} for '${highestExpense!.personName}'.");
      if (highestIncome != null) insights.add("Top Income Source: Your highest income source provided ${_formatCurrency(highestIncome!.amount)} ('${highestIncome!.personName}').");
      insights.add("Most Active Category: You used '$largestCategory' the most, with $maxCatCount transactions.");
      
      String highestVolumeDay = "None";
      double maxDayVol = 0;
      final dailyVols = <String, double>{};
      for (var r in sortedRecords) {
        String d = DateFormat('EEEE').format(r.date);
        dailyVols[d] = (dailyVols[d] ?? 0) + 1;
      }
      dailyVols.forEach((k, v) { if (v > maxDayVol) { maxDayVol = v; highestVolumeDay = k; }});
      if (maxDayVol > 0) insights.add("Most Active Day: You tend to record the most transactions on ${highestVolumeDay}s.");

      if (netBalance > 0) insights.add("Cash Flow Analysis: Great job! You maintained a positive cash flow with net savings of ${_formatCurrency(netBalance)}.");
      else if (netBalance < 0) insights.add("Overspending Warning: Your expenses have exceeded your income by ${_formatCurrency(netBalance.abs())}. Please review your budget.");
      
      insights.add("Expense Ratio: Your expenses represent ${expenseToIncomeRatio.toStringAsFixed(1)}% of your total income.");
      
      if (totalIncome > 0) {
        if (netProfitPct > 20) insights.add("Savings Recommendation: Your savings rate is excellent at ${netProfitPct.toStringAsFixed(1)}%. Consider investing the surplus.");
        else if (netProfitPct > 0) insights.add("Savings Recommendation: Your savings rate is ${netProfitPct.toStringAsFixed(1)}%. Try to aim for the standard 20% rule.");
      }
      
      String topExpenseCat = "";
      double topExpenseAmount = 0;
      categoryExpense.forEach((k, v) { if (v > topExpenseAmount) { topExpenseAmount = v; topExpenseCat = k; }});
      if (topExpenseCat.isNotEmpty && totalExpense > 0) {
        double pct = (topExpenseAmount / totalExpense) * 100;
        insights.add("Spending Trend: '$topExpenseCat' consumes ${pct.toStringAsFixed(1)}% of your expenses. This is your primary cost driver.");
      }

      if (incomeRecords.isEmpty && expenseRecords.isNotEmpty) insights.add("Income Trend: No income recorded. Ensure all your inflows are being properly logged to maintain accurate analytics.");
      insights.add("Average Transaction: Across all records, your average transaction size is ${_formatCurrency(avgTransaction)}.");
      
      // Ensure we have at least 10
      if (insights.length < 10) {
        insights.add("Transaction Volume: You have recorded a total of $totalTransactions transactions in this period.");
        insights.add("Expense Frequency: You have ${expenseRecords.length} outgoing transactions compared to ${incomeRecords.length} incoming.");
      }

      // --- PDF GENERATION ---
      
      // 1. Cover Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(40),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [PdfColor.fromHex('#4143D5'), PdfColor.fromHex('#7459F7')],
                      begin: pw.Alignment.topLeft,
                      end: pw.Alignment.bottomRight,
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(20),
                          decoration: const pw.BoxDecoration(
                            color: PdfColor(1, 1, 1, 0.1),
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Text("SK", style: pw.TextStyle(color: PdfColors.white, fontSize: 60, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(height: 40),
                        pw.Text("SmartKhata", style: pw.TextStyle(color: PdfColors.white, fontSize: 24, letterSpacing: 2)),
                        pw.SizedBox(height: 20),
                        pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 38, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        pw.SizedBox(height: 10),
                        pw.Text(subtitle, style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.9), fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 60),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(20),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(16),
                          ),
                          child: pw.Column(
                            children: [
                              _buildCoverRow("User Name:", userName), 
                              _buildCoverRow("Cashbook Name:", isGlobal ? "All Cashbooks" : cashbookName!),
                              _buildCoverRow("Date Range:", "${firstDate != null ? DateHelper.formatDate(firstDate!) : '-'} to ${lastDate != null ? DateHelper.formatDate(lastDate!) : '-'}"),
                              if (isGlobal) _buildCoverRow("Total Cashbooks Included:", records.map((e) => e.cashbookName).toSet().length.toString()),
                              _buildCoverRow("Total Categories Used:", "${categoryCount.length}"),
                              _buildCoverRow("Generated On:", "${DateHelper.formatDate(DateTime.now())} ${DateHelper.formatTime(DateTime.now())}"),
                              _buildCoverRow("Export Version:", "2.0 (Premium)"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Positioned(
                  bottom: -50,
                  right: -50,
                  child: pw.Opacity(
                    opacity: 0.05,
                    child: pw.Text("SmartKhata", style: pw.TextStyle(fontSize: 150, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                )
              ]
            );
          },
        ),
      );

      // 2. Executive Summary & Health
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(marginTop: 40, marginBottom: 40, marginLeft: 40, marginRight: 40),
          header: _buildPageHeader(title),
          footer: _buildPageFooter,
          build: (pw.Context context) {
            return [
              pw.Text("Executive Summary", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
              pw.SizedBox(height: 20),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard("Total Income", _formatCurrency(totalIncome), PdfColor.fromHex('#008339')),
                  _buildSummaryCard("Total Expense", _formatCurrency(totalExpense), PdfColor.fromHex('#E53935')),
                  _buildSummaryCard("Net Balance", _formatCurrency(netBalance), netBalance >= 0 ? PdfColor.fromHex('#4143D5') : PdfColor.fromHex('#E53935')),
                ],
              ),
              pw.SizedBox(height: 16),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Opening Balance", _formatCurrency(0)), // Mocking opening
                        _buildStatItem("Closing Balance", _formatCurrency(netBalance)),
                        if (isGlobal) _buildStatItem("Total Cashbooks", records.map((e) => e.cashbookName).toSet().length.toString()),
                        _buildStatItem("Income Txns", "${incomeRecords.length}"),
                        _buildStatItem("Expense Txns", "${expenseRecords.length}"),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Avg Income", _formatCurrency(avgIncome)),
                        _buildStatItem("Avg Expense", _formatCurrency(avgExpense)),
                        _buildStatItem("Largest Income", highestIncome != null ? _formatCurrency(highestIncome!.amount) : "-"),
                        _buildStatItem("Largest Expense", highestExpense != null ? _formatCurrency(highestExpense!.amount) : "-"),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Expense/Income Ratio", "${expenseToIncomeRatio.toStringAsFixed(1)}%"),
                        _buildStatItem("Net Profit %", "${netProfitPct.toStringAsFixed(1)}%"),
                        _buildStatItem("Most Active Cat", largestCategory),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Financial Health Score
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor(scoreColor.red, scoreColor.green, scoreColor.blue, 0.05),
                  border: pw.Border.all(color: scoreColor, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 60,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            color: scoreColor,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text("$score", style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                          )
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Financial Health Score: $scoreText", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: scoreColor)),
                              pw.SizedBox(height: 4),
                              pw.Text("Score: $score/100", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                            ]
                          )
                        )
                      ]
                    ),
                    pw.SizedBox(height: 16),
                    // Visual Progress Bar
                    pw.Container(
                      height: 10,
                      width: double.infinity,
                      decoration: pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.circular(5)),
                      child: pw.Row(
                        children: [
                          if (score > 0)
                            pw.Expanded(
                              flex: score,
                              child: pw.Container(
                                decoration: pw.BoxDecoration(color: scoreColor, borderRadius: pw.BorderRadius.circular(5)),
                              ),
                            ),
                          if (score < 100)
                            pw.Expanded(
                              flex: 100 - score,
                              child: pw.Container(),
                            ),
                        ]
                      )
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(aiRecommendation, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800, fontStyle: pw.FontStyle.italic)),
                  ]
                )
              ),
              pw.SizedBox(height: 30),

              // Smart Insights
              pw.Text("Smart Insights", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#4143D5'), width: 1.5),
                  borderRadius: pw.BorderRadius.circular(12),
                  color: PdfColor.fromHex('#F0F0FF'),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: insights.map((insight) => _buildInsightRow(PdfColors.purple, insight)).toList(),
                ),
              ),
            ];
          },
        ),
      );

      // 3. Category & Distribution Analysis
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(marginTop: 40, marginBottom: 40, marginLeft: 40, marginRight: 40),
          header: _buildPageHeader(title),
          footer: _buildPageFooter,
          build: (pw.Context context) {
            return [
              pw.Text("Category Analysis", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
              pw.SizedBox(height: 20),
              _buildCategoryTableDetailed(categoryIncome, categoryExpense, categoryCount, catHighestTxn, catLowestTxn, totalIncome, totalExpense),
              
            ];
          }
        )
      );

      // 4. Visual Analytics (Charts)
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(marginTop: 40, marginBottom: 40, marginLeft: 40, marginRight: 40),
          header: _buildPageHeader(title),
          footer: _buildPageFooter,
          build: (pw.Context context) {
            return [
              pw.Text("Visual Analytics", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
              pw.SizedBox(height: 20),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColors.grey200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Expense Distribution", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
                    pw.SizedBox(height: 20),
                    if (totalExpense > 0) 
                      _buildChartWithLegend(categoryExpense, totalExpense)
                    else pw.Text("No expenses recorded.", style: const pw.TextStyle(color: PdfColors.grey500)),
                  ]
                )
              ),
              
              pw.SizedBox(height: 30),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColors.grey200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Income Distribution", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
                    pw.SizedBox(height: 20),
                    if (totalIncome > 0) 
                      _buildChartWithLegend(categoryIncome, totalIncome)
                    else pw.Text("No income recorded.", style: const pw.TextStyle(color: PdfColors.grey500)),
                  ]
                )
              ),
              
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColors.grey200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Income vs Expense Comparison", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
                    pw.SizedBox(height: 20),
                    if (totalIncome > 0 || totalExpense > 0)
                      _buildComparisonChart(totalIncome, totalExpense)
                  ]
                )
              )
            ];
          }
        )
      );

      // 5. Monthly & Top Categories
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(marginTop: 40, marginBottom: 40, marginLeft: 40, marginRight: 40),
          header: _buildPageHeader(title),
          footer: _buildPageFooter,
          build: (pw.Context context) {
            
            List<List<String>> monthlyData = [];
            final allMonths = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList();
            for (int i = 0; i < allMonths.length; i++) {
              String m = allMonths[i];
              double inc = monthlyIncome[m] ?? 0;
              double exp = monthlyExpense[m] ?? 0;
              int count = monthlyCount[m] ?? 0;
              double net = inc - exp;
              
              double growth = 0;
              if (i > 0) {
                double prevInc = monthlyIncome[allMonths[i-1]] ?? 0;
                if (prevInc > 0) growth = ((inc - prevInc) / prevInc) * 100;
              }

              monthlyData.add([
                m, 
                "$count", 
                _formatCurrency(inc), 
                _formatCurrency(exp), 
                _formatCurrency(net),
                i > 0 ? "${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%" : "-"
              ]);
            }

            return [
              pw.Text("Monthly Summary", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
              pw.SizedBox(height: 20),
              if (allMonths.isNotEmpty)
                pw.TableHelper.fromTextArray(
                  headers: ['Month', 'Txns', 'Income', 'Expense', 'Savings', 'Growth %'],
                  data: monthlyData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#4143D5')),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                )
              else pw.Text("Not enough data.", style: const pw.TextStyle(color: PdfColors.grey500)),
              
              pw.SizedBox(height: 40),
              pw.Text("Top Categories", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
              pw.SizedBox(height: 20),
              
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Top 5 Expense Categories", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                        pw.SizedBox(height: 10),
                        pw.TableHelper.fromTextArray(
                          headers: ['Category', 'Amount', '%'],
                          data: (categoryExpense.entries.toList()
                            ..sort((a,b) => b.value.compareTo(a.value)))
                            .take(5).map((e) => [e.key, _formatCurrency(e.value), "${((e.value/totalExpense)*100).toStringAsFixed(1)}%"]).toList(),
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.red700),
                          cellStyle: const pw.TextStyle(fontSize: 8),
                        )
                      ]
                    )
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Top 5 Income Categories", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                        pw.SizedBox(height: 10),
                        pw.TableHelper.fromTextArray(
                          headers: ['Category', 'Amount', '%'],
                          data: (categoryIncome.entries.toList()
                            ..sort((a,b) => b.value.compareTo(a.value)))
                            .take(5).map((e) => [e.key, _formatCurrency(e.value), totalIncome > 0 ? "${((e.value/totalIncome)*100).toStringAsFixed(1)}%" : "0%"]).toList(),
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
                          cellStyle: const pw.TextStyle(fontSize: 8),
                        )
                      ]
                    )
                  ),
                ]
              ),
              
              pw.SizedBox(height: 40),
              pw.Text("Transaction Statistics", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(12)),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Total Records", "$totalTransactions"),
                        _buildStatItem("Income Records", "${incomeRecords.length}"),
                        _buildStatItem("Expense Records", "${expenseRecords.length}"),
                        _buildStatItem("Median Txn", _formatCurrency(medianTxn)),
                      ]
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Largest Txn", highestIncome != null || highestExpense != null ? _formatCurrency([if(highestIncome!=null) highestIncome.amount, if(highestExpense!=null) highestExpense.amount].reduce((a,b)=>a>b?a:b)) : "-"),
                        _buildStatItem("Smallest Txn", lowestIncome != null || lowestExpense != null ? _formatCurrency([if(lowestIncome!=null) lowestIncome.amount, if(lowestExpense!=null) lowestExpense.amount].reduce((a,b)=>a<b?a:b)) : "-"),
                        _buildStatItem("Most Frequent", largestCategory),
                      ]
                    ),
                  ]
                )
              )
            ];
          }
        )
      );

      // 6. Detailed Transaction History
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(marginTop: 40, marginBottom: 40, marginLeft: 40, marginRight: 40),
          header: _buildPageHeader(title),
          footer: _buildPageFooter,
          build: (pw.Context context) {
            
            final List<List<String>> tableData = [];
            List<String> headers = ['Date', 'Time'];
            if (isGlobal) headers.add('Book');
            headers.addAll(['ID/Mode', 'Category', 'Description', 'Type', 'Amount', 'Balance']);

            double runningBalance = 0;

            for (var record in sortedRecords) {
              if (record.isGiven) {
                runningBalance -= record.amount;
              } else {
                runningBalance += record.amount;
              }

              List<String> row = [
                DateHelper.formatDate(record.date),
                DateHelper.formatTime(record.date),
              ];
              
              if (isGlobal) row.add(record.cashbookName ?? '-');
              
              row.addAll([
                "${record.id.substring(0, 4)} / ${record.paymentMethod ?? 'Cash'}",
                record.category ?? 'General',
                record.personName,
                record.isGiven ? 'Expense' : 'Income',
                _formatCurrency(record.amount),
                _formatCurrency(runningBalance),
              ]);
              
              tableData.add(row);
            }

            return [
              pw.Text("Detailed Transaction History", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: tableData.reversed.toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#4143D5')),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                cellPadding: const pw.EdgeInsets.all(6),
              ),
            ];
          },
        ),
      );

      // 6. Final Summary Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text("Final Summary", style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4143D5'))),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(30),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0F0FF'),
                      borderRadius: pw.BorderRadius.circular(20),
                      border: pw.Border.all(color: PdfColor.fromHex('#4143D5'), width: 2),
                    ),
                    child: pw.Column(
                      children: [
                        _buildCoverRow("Total Income:", _formatCurrency(totalIncome)),
                        pw.Divider(color: PdfColors.grey300),
                        _buildCoverRow("Total Expense:", _formatCurrency(totalExpense)),
                        pw.Divider(color: PdfColors.grey300),
                        _buildCoverRow("Net Balance:", _formatCurrency(netBalance)),
                        pw.Divider(color: PdfColors.grey300),
                        _buildCoverRow("Financial Grade:", grade),
                        pw.Divider(color: PdfColors.grey300),
                        _buildCoverRow("Overall Health Score:", "$score / 100"),
                        pw.Divider(color: PdfColors.grey300),
                        _buildCoverRow("Net Profit %:", "${netProfitPct.toStringAsFixed(1)}%"),
                        pw.SizedBox(height: 20),
                        pw.Text("Final Recommendation", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          aiRecommendation,
                          style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic, color: PdfColor.fromHex('#4143D5')),
                          textAlign: pw.TextAlign.center,
                        )
                      ]
                    )
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text("AI-Generated Recommendations", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(12)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (expenseToIncomeRatio > 80) _buildInsightRow(PdfColors.orange, "Critical: Reduce spending immediately. You are consuming over 80% of your income.")
                        else if (expenseToIncomeRatio < 50) _buildInsightRow(PdfColors.green, "Excellent: You are saving over 50% of your income. Consider diversifying investments."),
                        if (topExpenseCat.isNotEmpty) _buildInsightRow(PdfColors.blue, "Focus on reducing expenses in your primary cost driver: '$topExpenseCat'."),
                        if (categoryCount.length < 3) _buildInsightRow(PdfColors.purple, "Consider categorizing your transactions more thoroughly to gain better insights."),
                        _buildInsightRow(PdfColors.grey700, "Maintain a consistent record-keeping habit to ensure accurate end-of-month projections."),
                      ]
                    )
                  ),
                  pw.Spacer(),
                  _buildPageFooter(context),
                ]
              )
            );
          }
        )
      );

      final directory = await getApplicationDocumentsDirectory();
      final prefix = cashbookName != null ? cashbookName.replaceAll(' ', '_').toLowerCase() : 'smartkhata_global';
      final path = '${directory.path}/${prefix}_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(path)], text: 'Financial Report: $title');
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showToast(context, 'PDF Generation failed: $e', isError: true);
      }
    }
  }

  // --- Helpers ---

  static final List<String> _colorPalette = [
    '#4143D5', '#F57F17', '#008339', '#E53935', '#8E24AA', '#00ACC1', '#FDD835', '#D81B60', '#3949AB', '#43A047', '#FFB300', '#F06292', '#4DD0E1', '#81C784', '#FF8A65'
  ];

  static String _getColorForCategory(String category) {
    int index = category.hashCode.abs() % _colorPalette.length;
    return _colorPalette[index];
  }

  static pw.Widget _buildCoverRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, color: PdfColor.fromHex('#191C1E'))),
        ],
      ),
    );
  }

  static pw.Widget Function(pw.Context) _buildPageHeader(String title) {
    return (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4143D5'))),
              pw.Text("SmartKhata Financial Report", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 20),
        ],
      );
    };
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Generated Automatically by SmartKhata", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            pw.Text("Confidential Report", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold)),
            pw.Text("Page ${context.pageNumber} of ${context.pagesCount}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          ],
        ),
      ]
    );
  }

  static pw.Widget _buildSummaryCard(String title, String amount, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
          pw.Text(amount, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color), maxLines: 1),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#191C1E'))),
      ],
    );
  }

  static pw.Widget _buildInsightRow(PdfColor color, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 6,
            height: 6,
            decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800))),
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryTableDetailed(
    Map<String, double> income, 
    Map<String, double> expense, 
    Map<String, int> count,
    Map<String, RecordModel> catHighestTxn,
    Map<String, RecordModel> catLowestTxn,
    double totalIncome,
    double totalExpense,
  ) {
    final List<List<String>> data = [];
    final allCategories = {...income.keys, ...expense.keys}.toList();
    
    // Sort by descending total value
    allCategories.sort((a, b) {
      double valA = (income[a] ?? 0) + (expense[a] ?? 0);
      double valB = (income[b] ?? 0) + (expense[b] ?? 0);
      return valB.compareTo(valA);
    });

    for (var cat in allCategories) {
      double inc = income[cat] ?? 0;
      double exp = expense[cat] ?? 0;
      int cnt = count[cat] ?? 0;
      double avg = cnt > 0 ? (inc + exp) / cnt : 0;
      double pctInc = totalIncome > 0 ? (inc / totalIncome) * 100 : 0;
      double pctExp = totalExpense > 0 ? (exp / totalExpense) * 100 : 0;
      
      String highest = catHighestTxn[cat] != null ? _formatCurrency(catHighestTxn[cat]!.amount) : "-";
      String lowest = catLowestTxn[cat] != null ? _formatCurrency(catLowestTxn[cat]!.amount) : "-";

      data.add([
        cat,
        _formatCurrency(inc),
        _formatCurrency(exp),
        _formatCurrency(avg),
        "${pctInc.toStringAsFixed(1)}%",
        "${pctExp.toStringAsFixed(1)}%",
        highest,
        lowest,
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Category', 'Income', 'Expense', 'Average', '% of Inc', '% of Exp', 'Highest', 'Lowest'],
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
    );
  }

  static pw.Widget _buildChartWithLegend(Map<String, double> data, double total) {
    final sortedData = data.entries.where((e) => e.value > 0).toList()..sort((a,b) => b.value.compareTo(a.value));
    final topData = sortedData.take(8).toList();
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 180,
          height: 180,
          child: pw.Chart(
            grid: pw.PieGrid(),
            datasets: topData.map((e) {
              return pw.PieDataSet(
                value: e.value,
                color: PdfColor.fromHex(_getColorForCategory(e.key)),
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: topData.map((e) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(margin: const pw.EdgeInsets.only(top: 2), width: 12, height: 12, color: PdfColor.fromHex(_getColorForCategory(e.key))),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text('${e.key} (${((e.value/total)*100).toStringAsFixed(1)}%)\n${_formatCurrency(e.value)}', 
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))
                    ),
                  ]
                )
              );
            }).toList()
          )
        )
      ]
    );
  }

  static pw.Widget _buildComparisonChart(double totalIncome, double totalExpense) {
    double total = totalIncome + totalExpense;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 180,
          height: 180,
          child: pw.Chart(
            grid: pw.PieGrid(),
            datasets: [
              if (totalIncome > 0) pw.PieDataSet(value: totalIncome, color: PdfColors.green),
              if (totalExpense > 0) pw.PieDataSet(value: totalExpense, color: PdfColors.red),
            ]
          )
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (totalIncome > 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(margin: const pw.EdgeInsets.only(top: 2), width: 12, height: 12, color: PdfColors.green),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text('Income (${((totalIncome/total)*100).toStringAsFixed(1)}%)\n${_formatCurrency(totalIncome)}', 
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))
                      ),
                    ]
                  )
                ),
              if (totalExpense > 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(margin: const pw.EdgeInsets.only(top: 2), width: 12, height: 12, color: PdfColors.red),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text('Expense (${((totalExpense/total)*100).toStringAsFixed(1)}%)\n${_formatCurrency(totalExpense)}', 
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))
                      ),
                    ]
                  )
                ),
            ]
          )
        )
      ]
    );
  }
}
