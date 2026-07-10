Yimport os

def replace_in_file(path, old, new):
    if not os.path.exists(path):
        return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(old, new)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Updated {path}")

# app_drawer.dart
drawer_path = "lib/screens/bottom_nav/app_drawer.dart"
replace_in_file(drawer_path, "const Icon(\n                                      Icons.school_rounded,\n                                      color: AppColors.primary,", "Icon(\n                                      Icons.school_rounded,\n                                      color: Theme.of(context).primaryColor,")
replace_in_file(drawer_path, "color: AppColors.primary.withValues(alpha: 0.1)", "color: Theme.of(context).primaryColor.withValues(alpha: 0.1)")
replace_in_file(drawer_path, "Icon(icon, color: AppColors.primary, size: 24)", "Icon(icon, color: Theme.of(context).primaryColor, size: 24)")

# The context issue in app_drawer.dart: it lacks context. 
replace_in_file(drawer_path, "_buildTutorialStep(\n                                        icon: Icons.menu_book_rounded", "_buildTutorialStep(\n                                        context: context,\n                                        icon: Icons.menu_book_rounded")
replace_in_file(drawer_path, "_buildTutorialStep(\n                                        icon: Icons.add_circle_outline_rounded", "_buildTutorialStep(\n                                        context: context,\n                                        icon: Icons.add_circle_outline_rounded")
replace_in_file(drawer_path, "_buildTutorialStep(\n                                        icon: Icons.cloud_sync_rounded", "_buildTutorialStep(\n                                        context: context,\n                                        icon: Icons.cloud_sync_rounded")
replace_in_file(drawer_path, "_buildTutorialStep(\n                                        icon: Icons.bar_chart_rounded", "_buildTutorialStep(\n                                        context: context,\n                                        icon: Icons.bar_chart_rounded")
replace_in_file(drawer_path, "required bool isDark,\n  })", "required bool isDark,\n    required BuildContext context,\n  })")

# reports_screen.dart
reports_path = "lib/screens/reports/reports_screen.dart"
replace_in_file(reports_path, "const CircularProgressIndicator(\n                              valueColor: AlwaysStoppedAnimation(AppColors.primary),", "CircularProgressIndicator(\n                              valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),")
replace_in_file(reports_path, "_buildStatCard(\n                      'Total Income'", "_buildStatCard(\n                      context,\n                      'Total Income'")
replace_in_file(reports_path, "_buildStatCard(\n                      'Total Expense'", "_buildStatCard(\n                      context,\n                      'Total Expense'")
replace_in_file(reports_path, "_buildStatCard(\n                      'Net Balance'", "_buildStatCard(\n                      context,\n                      'Net Balance'")
replace_in_file(reports_path, "Widget _buildStatCard(String title, double amount, Color color)", "Widget _buildStatCard(BuildContext context, String title, double amount, Color color)")
# also fix AppColors.primary inside _buildStatCard if any? 
replace_in_file(reports_path, "color: AppColors.primary.withValues(alpha: 0.1),", "color: Theme.of(context).primaryColor.withValues(alpha: 0.1),")

# backup_restore_screen.dart
backup_path = "lib/screens/settings/backup_restore_screen.dart"
replace_in_file(backup_path, "const CircularProgressIndicator(\n                        valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),", "CircularProgressIndicator(\n                        valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),")

# help_support_screen.dart
help_path = "lib/screens/settings/help_support_screen.dart"
replace_in_file(help_path, "const Icon(\n                Icons.check_circle_outline_rounded,\n                color: Theme.of(context).primaryColor,", "Icon(\n                Icons.check_circle_outline_rounded,\n                color: Theme.of(context).primaryColor,")

