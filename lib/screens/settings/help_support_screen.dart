import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/toast_helper.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@smartkhata.com',
      query: 'subject=SmartKhata Support Request', // Add subject
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          ToastHelper.showToast(context, 'No email app found on your device.', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showToast(context, 'Could not launch email app.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Help & Support",
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            Text(
              "How to use Smart Khata",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Master your finances in a few simple steps.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Detailed Steps
            _buildDetailSection(
              context: context,
              icon: Icons.menu_book_rounded,
              title: "1. Understanding Cashbooks",
              content: "A Cashbook acts as an individual ledger. You can create multiple Cashbooks to separate your personal expenses from your business finances, or even track specific projects individually. From the Dashboard, simply click the '+' icon to create a new Cashbook. You can name it whatever you like (e.g., 'Groceries', 'Office Expenses').",
            ),
            _buildDetailSection(
              context: context,
              icon: Icons.add_circle_outline_rounded,
              title: "2. Adding Records",
              content: "Once inside a Cashbook, you can add records. A record represents a single transaction. Tap 'Add Record' and choose whether 'You Gave' (Expense/Credit) or 'You Received' (Income/Debit). Add the exact amount, a custom note to remember what the transaction was for, and choose the correct date. It will immediately reflect in your overall balance.",
            ),
            _buildDetailSection(
              context: context,
              icon: Icons.cloud_sync_rounded,
              title: "3. Auto-Sync & Security",
              content: "Your data is strictly secured and encrypted. Every time you add a record, it is automatically synchronized to your personalized cloud database. If you lose your phone or log in on a new device, your data will instantly be restored—no manual backup required!",
            ),
            _buildDetailSection(
              context: context,
              icon: Icons.bar_chart_rounded,
              title: "4. Reports & Analytics",
              content: "Tracking your money is only half the battle. Click on the Reports icon at the top of your Cashbook to view a graphical breakdown of your spending habits. You can also generate and download comprehensive PDF reports to share with accountants, partners, or for your own personal records.",
            ),
            
            const SizedBox(height: 40),
            
            // FAQs
            Text(
              "Frequently Asked Questions",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFaqItem(
              context: context,
              question: "Is my financial data secure?",
              answer: "Absolutely. Your data is synced securely to a private database using military-grade encryption. Only you can access your ledgers using your Google Account.",
            ),
            _buildFaqItem(
              context: context,
              question: "Can I use the app offline?",
              answer: "Yes! If you add a record while offline, it is saved safely on your device. As soon as you connect to the internet, it will seamlessly synchronize with the cloud.",
            ),
            _buildFaqItem(
              context: context,
              question: "How do I edit or delete a record?",
              answer: "Simply find the record inside your Cashbook, tap the three dots (⋮) next to it, and choose 'Edit' or 'Delete'. The balances will recalculate automatically.",
            ),
            _buildFaqItem(
              context: context,
              question: "What if I accidentally delete a Cashbook?",
              answer: "If you delete a Cashbook, all records inside it are also moved to the trash. Please be very careful when deleting an entire ledger as it affects your total balance.",
            ),
            
            const SizedBox(height: 40),
            
            // Contact Support
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Still need help?",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Contact our support team directly.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _launchEmail(context),
                    icon: const Icon(Icons.email_outlined, color: Colors.white),
                    label: Text(
                      "Email Support",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({required BuildContext context, required IconData icon, required String title, required String content}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: isDark ? Colors.white : AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F3255),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required BuildContext context, required String question, required String answer}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: isDark ? Colors.white : AppColors.primary,
          collapsedIconColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1F3255),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
