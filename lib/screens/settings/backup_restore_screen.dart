import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/record_provider.dart';
import '../../core/utils/date_helper.dart';
import '../../services/backup_service.dart';
import '../../services/recovery_service.dart';
import '../../core/utils/toast_helper.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _recoveryItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
    _loadRecoveryItems();
  }

  Future<void> _loadRecoveryItems() async {
    final items = await RecoveryService.getRecoverableItems();
    if (mounted) {
      setState(() {
        _recoveryItems = items;
      });
    }
  }

  Future<void> _loadHistory() async {
    final history = await BackupService.getBackupHistory();
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Backup & Restore",
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.cloud_upload), text: "Backup"),
            Tab(icon: Icon(Icons.delete_outline), text: "Recovery"),
            Tab(icon: Icon(Icons.security), text: "Health"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBackupTab(isDark),
          _buildRecoveryTab(isDark),
          _buildHealthTab(isDark),
        ],
      ),
    );
  }

  Widget _buildBackupTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last Backup Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.withOpacity(0.15) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_done, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Last Backup",
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _history.isNotEmpty
                          ? DateHelper.formatDateTime(DateTime.parse(_history.first['timestamp']))
                          : "No backups yet",
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _exportBackup,
                  child: _buildActionCard(
                    isDark,
                    icon: Icons.cloud_upload,
                    title: "EXPORT BACKUP",
                    subtitle: "Save all data to file",
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _restoreBackup,
                  child: _buildActionCard(
                    isDark,
                    icon: Icons.restore,
                    title: "RESTORE",
                    subtitle: "Import from backup file",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pre-Migration Backup Button
          OutlinedButton.icon(
            onPressed: () => _exportBackup(isPreMigration: true),
            icon: const Icon(Icons.security, color: Colors.black),
            label: Text(
              "Pre-Migration Safety Backup",
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
          ),

          const SizedBox(height: 32),
          Text(
            "BACKUP HISTORY",
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text("No backup history found.", style: GoogleFonts.poppins(color: Colors.grey)),
              ),
            )
          else
            ..._history.map((item) => _buildHistoryItem(item, isDark)),
        ],
      ),
    );
  }

  Widget _buildActionCard(bool isDark, {required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cloud_upload, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['type'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  "${item['records']} records · ${item['size']}",
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  DateHelper.formatDateTime(DateTime.parse(item['timestamp'])),
                  style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryTab(bool isDark) {
    if (_recoveryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No recently deleted items",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Deleted records will appear here for 30 days\nbefore being permanently removed.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recoveryItems.length,
      itemBuilder: (context, index) {
        final item = _recoveryItems[index];
        final deletedAt = DateTime.parse(item['deletedAt']);
        final daysLeft = 30 - DateTime.now().difference(deletedAt).inDays;
        
        final isCashbook = item['recoveryType'] == 'cashbook';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isCashbook ? Icons.library_books : Icons.delete_sweep, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCashbook ? (item['name'] ?? 'Unknown Cashbook') : (item['title'] ?? 'Unknown Record'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      isCashbook 
                          ? "${(item['records'] as List).length} associated records"
                          : "₹${item['amount']} • ${item['type']}",
                      style: GoogleFonts.poppins(
                        color: isCashbook ? Colors.grey : (item['type'] == 'IN' ? Colors.green : Colors.red),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$daysLeft days left to recover",
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.restore, color: AppColors.primary),
                onPressed: () async {
                  setState(() => _isLoading = true);
                  final provider = Provider.of<RecordProvider>(context, listen: false);
                  final success = await RecoveryService.restoreItem(item, provider);
                  await _loadRecoveryItems();
                  setState(() => _isLoading = false);
                  
                  if (success && mounted) {
                    ToastHelper.showToast(context, '${isCashbook ? 'Cashbook' : 'Record'} restored successfully!');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: Text("Check Backup Health", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Backup System Healthy",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            _history.isNotEmpty
                                ? "${DateTime.now().difference(DateTime.parse(_history.first['timestamp'])).inDays} days since last backup"
                                : "No backups created yet",
                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Total Backups", _history.length.toString(), isDark),
                    _buildStatItem("Failed", "0", isDark),
                    _buildStatItem("Archived", "0", isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "RECOVERY STEPS",
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildStepItem("1", "Check Backup Health", "Run a health check to see backup status", isDark),
          _buildStepItem("2", "Export Backup", "Save your data to a JSON file", isDark),
          _buildStepItem("3", "Restore If Needed", "Import a backup file to restore data", isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String number, String title, String subtitle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
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
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
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

  void _exportBackup({bool isPreMigration = false}) async {
    setState(() => _isLoading = true);
    final provider = Provider.of<RecordProvider>(context, listen: false);
    final success = await BackupService.exportBackup(provider, isPreMigration: isPreMigration);
    setState(() => _isLoading = false);
    
    if (success) {
      _loadHistory();
      if (mounted) {
        ToastHelper.showToast(context, 'Backup exported successfully!');
      }
    } else {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to export backup.', isError: true);
      }
    }
  }

  void _restoreBackup() async {
    // Show Dialog exactly like the screenshot
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            "Restore Backup?",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This will OVERWRITE your current data with the backup data.",
                style: GoogleFonts.poppins(color: Colors.red.shade600, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                "Make sure you have a recent backup of your current data before proceeding.",
                style: GoogleFonts.poppins(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                "This action cannot be undone.",
                style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text("CANCEL", style: GoogleFonts.poppins(color: AppColors.primary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F), // Red button
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("RESTORE BACKUP", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final data = await BackupService.pickAndReadBackup();
      if (data != null && mounted) {
        setState(() => _isLoading = true);
        final provider = Provider.of<RecordProvider>(context, listen: false);
        final success = await BackupService.restoreBackup(data, provider);
        setState(() => _isLoading = false);

        if (success) {
          ToastHelper.showToast(context, 'Backup restored successfully!');
        } else {
          ToastHelper.showToast(context, 'Failed to restore backup. Invalid file format.', isError: true);
        }
      }
    }
  }
}
