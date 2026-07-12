import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/transaction_model.dart';
import 'toast_helper.dart';
import 'premium_pdf_generator.dart';
import 'date_helper.dart';
import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../theme/premium_themes.dart';

class ExportHelper {
  static void showExportOptions(BuildContext context, {String? cashbookName}) {
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);
    final allRecords = recordProvider.records;
    final records = cashbookName != null
        ? allRecords.where((r) => r.cashbookName == cashbookName).toList()
        : allRecords;

    if (records.isEmpty) {
      ToastHelper.showToast(context, 'No records to export!', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  AppLocalizations.of(context)!.exportAs,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: Text(
                  AppLocalizations.of(context)!.csvExcel,
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportToCsv(context, records, cashbookName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                title: Text(
                  "Simple PDF",
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportToPdf(context, records, cashbookName, isDetailed: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(
                  "Detailed PDF",
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportToPdf(context, records, cashbookName, isDetailed: true);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _exportToCsv(
    BuildContext context,
    List<RecordModel> records,
    String? cashbookName,
  ) async {
    try {
      List<List<dynamic>> csvData = [
        [
          'Date',
          'Time',
          'Cashbook',
          'Payment Mode',
          'Category',
          'Title',
          'Type',
          'Amount',
          'Note',
        ],
      ];

      for (var record in records) {
        csvData.add([
          DateHelper.formatDate(record.date),
          DateHelper.formatTime(record.date),
          record.cashbookName ?? 'General',
          record.paymentMethod ?? 'Cash',
          record.category ?? 'General',
          record.title,
          record.type == 'expense' ? 'Expense' : 'Income',
          record.amount.toStringAsFixed(2),
          record.note,
        ]);
      }

      String csvString = const CsvEncoder().convert(csvData);

      final directory = await getTemporaryDirectory();
      final prefix = cashbookName != null
          ? cashbookName.replaceAll(' ', '_').toLowerCase()
          : 'smartkhata';
      final path =
          '${directory.path}/${prefix}_records_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(path)],
        text: cashbookName != null
            ? '$cashbookName Records (CSV)'
            : 'My SmartKhata Records (CSV)',
      );
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showToast(context, 'Export failed: $e', isError: true);
      }
    }
  }

  static Future<void> _exportToPdf(
    BuildContext context,
    List<RecordModel> records,
    String? cashbookName, {
    bool isDetailed = true,
  }) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDefault = settings.appTheme == 'Default';
    final primary = isDefault 
        ? const Color(0xFF4143D5) 
        : PremiumThemes.getTheme(settings.appTheme).primaryColor;
        
    // Note: PdfColor.fromInt expects ARGB format which matches Flutter Color.value
    final pdfColor = PdfColor.fromInt(primary.toARGB32());

    await PremiumPdfGenerator.generateAndSharePdf(
      context,
      records,
      cashbookName,
      isDetailed: isDetailed,
      themeColor: pdfColor,
    );
  }
}
