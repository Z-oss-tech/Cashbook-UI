import os
import re

lib_dir = r"c:\Users\ZEENAT\StudioProjects\cashbook\lib"

replacements = {
    r"AppColors\.primary": "Theme.of(context).primaryColor",
}

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            file_path = os.path.join(root, file)
            # Skip app_colors.dart and theme files
            if "app_colors.dart" in file or "theme" in file.lower():
                continue
            
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            new_content = content
            for old, new in replacements.items():
                new_content = re.sub(old, new, new_content)
            
            if content != new_content:
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Updated {file_path}")
