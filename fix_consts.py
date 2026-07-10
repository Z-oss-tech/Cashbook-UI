import re
import sys

errors = [
    (r"lib\core\widgets\lock_screen_wrapper.dart", 90),
    (r"lib\screens\auth\login_screen.dart", 158),
    (r"lib\screens\bottom_nav\app_drawer.dart", 246),
    (r"lib\screens\bottom_nav\app_drawer.dart", 467),
    (r"lib\screens\dashboard\dashboard_screen.dart", 553),
    (r"lib\screens\people\add_people_screen.dart", 118),
    (r"lib\screens\reports\reports_screen.dart", 646),
    (r"lib\screens\settings\backup_restore_screen.dart", 312),
    (r"lib\screens\settings\backup_restore_screen.dart", 456),
    (r"lib\screens\settings\help_support_screen.dart", 80),
    (r"lib\screens\splash\splash_screen.dart", 191),
]

for file_path, line_num in errors:
    full_path = "c:\\Users\\ZEENAT\\StudioProjects\\cashbook\\" + file_path
    with open(full_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    idx = line_num - 1
    # Remove 'const ' on that line
    if 'const ' in lines[idx]:
        lines[idx] = lines[idx].replace('const ', '')
        with open(full_path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(f"Fixed const on {file_path}:{line_num}")
    else:
        # Check previous line
        if 'const ' in lines[idx-1]:
            lines[idx-1] = lines[idx-1].replace('const ', '')
            with open(full_path, "w", encoding="utf-8") as f:
                f.writelines(lines)
            print(f"Fixed const on {file_path}:{line_num-1}")
        else:
            print(f"Could not find const near {file_path}:{line_num}")
