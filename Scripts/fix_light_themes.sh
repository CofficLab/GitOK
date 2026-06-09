#!/bin/bash

# 修复亮色主题的不透明度值

LIGHT_THEME_FILES=(
    "Plugins/ThemeSpringPlugin/Sources/SpringTheme.swift"
    "Plugins/ThemeSummerPlugin/Sources/SummerTheme.swift"
    "Plugins/ThemeWinterPlugin/Sources/WinterTheme.swift"
    "Plugins/ThemeXcodeLightPlugin/Sources/XcodeLightTheme.swift"
)

for file in "${LIGHT_THEME_FILES[@]}"; do
    echo "Fixing light theme: $file..."
    
    # 检查是否包含 appearanceKind: .light
    if grep -q "appearanceKind: .light" "$file"; then
        # 修复 glowColors
        sed -i '' 's/primary\.opacity(0\.12)/primary.opacity(0.08)/' "$file"
        sed -i '' 's/secondary\.opacity(0\.16)/secondary.opacity(0.10)/' "$file"
        sed -i '' 's/tertiary\.opacity(0\.18)/tertiary.opacity(0.12)/' "$file"
        
        # 修复 sidebarSelectionColor
        sed -i '' 's/primary\.opacity(0\.24)/primary.opacity(0.14)/' "$file"
        
        # 修复 sidebarSelectionTextColor
        sed -i '' 's/\.white/Color(hex: "111827")/' "$file"
        
        # 修复 makeGlobalBackground 中的不透明度
        sed -i '' '0,/primary\.opacity(0\.10)/{s/primary\.opacity(0\.10)/primary.opacity(0.05)/;}' "$file"
        sed -i '' '0,/secondary\.opacity(0\.08)/{s/secondary\.opacity(0\.08)/secondary.opacity(0.04)/;}' "$file"
        sed -i '' '0,/primary\.opacity(0\.08)/{s/primary\.opacity(0\.08)/primary.opacity(0.04)/;}' "$file"
        sed -i '' 's/tertiary\.opacity(0\.06)/tertiary.opacity(0.035)/' "$file"
        
        echo "✓ Fixed"
    else
        echo "⊘ Skipped (not a light theme)"
    fi
done

echo "Light themes fixed!"
