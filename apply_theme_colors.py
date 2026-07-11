import os
import re

lib_dir = r"c:\Users\ZEENAT\StudioProjects\cashbook\lib\screens"

replacements = [
    # Card and Surface colors
    (r"color: isDark \? const Color\(.*?\) : Colors\.white", r"color: Theme.of(context).cardColor"),
    (r"backgroundColor: isDark \? const Color\(.*?\) : Colors\.white", r"backgroundColor: Theme.of(context).cardColor"),
    (r"final surfaceColor = isDark \? const Color\(.*?\) : Colors\.white;", r"final surfaceColor = Theme.of(context).cardColor;"),
    (r"final bgColor = isDark \? const Color\(.*?\) : Colors\.white;", r"final bgColor = Theme.of(context).cardColor;"),

    # Other inline colors
    (r"color: isDark \? Colors\.white : const Color\(.*?\)", r"color: Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0B1C30))"),
    (r"color: isDark \? Colors\.white70 : const Color\(.*?\)", r"color: Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : const Color(0xFF767586))"),
    
    # Fix settings screen GlassCard (this is important)
    (r"Colors\.white\.withOpacity\(0\.05\)", r"Theme.of(context).cardColor.withOpacity(0.5)"),
    (r"Colors\.white\.withOpacity\(0\.7\)", r"Theme.of(context).cardColor.withOpacity(0.9)"),
    
    (r"Colors\.white\.withValues\(alpha: 0\.05\)", r"Theme.of(context).cardColor.withValues(alpha: 0.5)"),
    (r"Colors\.white\.withValues\(alpha: 0\.7\)", r"Theme.of(context).cardColor.withValues(alpha: 0.9)"),
]

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart") and file != "theme_screen.dart":
            file_path = os.path.join(root, file)
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            new_content = content
            for old, new in replacements:
                new_content = re.sub(old, new, new_content)
            
            if content != new_content:
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Updated {file_path}")
