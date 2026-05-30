import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../providers/record_provider.dart';
import '../../models/transaction_model.dart';
import 'toast_helper.dart';

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
                title: Text(AppLocalizations.of(context)!.csvExcel, style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _exportToCsv(context, records, cashbookName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.pdfDocument, style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _exportToPdf(context, records, cashbookName);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _exportToCsv(BuildContext context, List<RecordModel> records, String? cashbookName) async {
    try {
      List<List<dynamic>> csvData = [
        ['Date', 'Name', 'Type', 'Amount', 'Note']
      ];

      for (var record in records) {
        csvData.add([
          record.date.toIso8601String().split('T')[0],
          record.personName,
          record.isGiven ? 'Given' : 'Received',
          record.amount.toString(),
          record.note,
        ]);
      }

      String csvString = const CsvEncoder().convert(csvData);
      
      final directory = await getApplicationDocumentsDirectory();
      final prefix = cashbookName != null ? cashbookName.replaceAll(' ', '_').toLowerCase() : 'smartkhata';
      final path = '${directory.path}/${prefix}_records_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvString);
      
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(path)], text: cashbookName != null ? '$cashbookName Records (CSV)' : 'My SmartKhata Records (CSV)');
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showToast(context, 'Export failed: $e', isError: true);
      }
    }
  }

  static Future<void> _exportToPdf(BuildContext context, List<RecordModel> records, String? cashbookName) async {
    try {
      final pdf = pw.Document();
      final title = cashbookName != null ? "$cashbookName Records" : "SmartKhata Records";

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Generated on: ${DateTime.now().toString().split('.')[0]}"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Name', 'Type', 'Amount', 'Note'],
                data: records.map((record) {
                  return [
                    record.date.toIso8601String().split('T')[0],
                    record.personName,
                    record.isGiven ? 'Given' : 'Received',
                    record.amount.toStringAsFixed(2),
                    record.note,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final prefix = cashbookName != null ? cashbookName.replaceAll(' ', '_').toLowerCase() : 'smartkhata';
      final path = '${directory.path}/${prefix}_records_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(path)], text: cashbookName != null ? '$cashbookName Records (PDF)' : 'My SmartKhata Records (PDF)');
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showToast(context, 'PDF Export failed: $e', isError: true);
      }
    }
  }
}
