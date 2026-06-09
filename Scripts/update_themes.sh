#!/bin/bash

# 批量更新主题文件，移除 isDarkTheme 和 followsSystemAppearance，使用 appearanceKind

THEME_FILES=(
    "Plugins/ThemeDraculaPlugin/Sources/DraculaTheme.swift"
    "Plugins/ThemeEmberPlugin/Sources/EmberTheme.swift"
    "Plugins/ThemeGlacierPlugin/Sources/GlacierTheme.swift"
    "Plugins/ThemeGraphitePlugin/Sources/GraphiteTheme.swift"
    "Plugins/ThemeHarborPlugin/Sources/HarborTheme.swift"
    "Plugins/ThemeMatrixPlugin/Sources/MatrixTheme.swift"
    "Plugins/ThemeMidnightPlugin/Sources/MidnightTheme.swift"
    "Plugins/ThemeMountainPlugin/Sources/MountainTheme.swift"
    "Plugins/ThemeNebulaPlugin/Sources/NebulaTheme.swift"
    "Plugins/ThemeOneDarkPlugin/Sources/OneDarkTheme.swift"
    "Plugins/ThemeOrchardPlugin/Sources/OrchardTheme.swift"
    "Plugins/ThemeRiverPlugin/Sources/RiverTheme.swift"
    "Plugins/ThemeSpringPlugin/Sources/SpringTheme.swift"
    "Plugins/ThemeSummerPlugin/Sources/SummerTheme.swift"
    "Plugins/ThemeWinterPlugin/Sources/WinterTheme.swift"
    "Plugins/ThemeXcodeLightPlugin/Sources/XcodeLightTheme.swift"
)

for file in "${THEME_FILES[@]}"; do
    echo "Processing $file..."
    
    # 1. 替换结构体定义中的属性
    sed -i '' 's/let isDarkTheme: Bool/let appearanceKind: ThemeAppearanceKind/' "$file"
    sed -i '' '/let followsSystemAppearance: Bool/d' "$file"
    
    # 2. 替换静态实例中的属性（暗色主题）
    sed -i '' 's/isDarkTheme: true,/appearanceKind: .dark,/' "$file"
    sed -i '' '/followsSystemAppearance: false,/d' "$file"
    
    # 3. 替换静态实例中的属性（亮色主题）
    sed -i '' 's/isDarkTheme: false,/appearanceKind: .light,/' "$file"
    
    # 4. 简化 glowColors 中的条件表达式（暗色主题）
    sed -i '' 's/primary\.opacity(isDarkTheme ? 0\.12 : 0\.08)/primary.opacity(0.12)/' "$file"
    sed -i '' 's/secondary\.opacity(isDarkTheme ? 0\.16 : 0\.10)/secondary.opacity(0.16)/' "$file"
    sed -i '' 's/tertiary\.opacity(isDarkTheme ? 0\.18 : 0\.12)/tertiary.opacity(0.18)/' "$file"
    
    # 5. 简化 sidebarSelectionColor（暗色主题）
    sed -i '' 's/primary\.opacity(isDarkTheme ? 0\.24 : 0\.14)/primary.opacity(0.24)/' "$file"
    
    # 6. 简化 sidebarSelectionTextColor（暗色主题）
    sed -i '' 's/isDarkTheme ? \.white : Color(hex: "111827")/\.white/' "$file"
    
    # 7. 简化 makeGlobalBackground 中的不透明度（暗色主题）
    sed -i '' 's/primary\.opacity(isDarkTheme ? 0\.10 : 0\.05)/primary.opacity(0.10)/' "$file"
    sed -i '' 's/secondary\.opacity(isDarkTheme ? 0\.08 : 0\.04)/secondary.opacity(0.08)/' "$file"
    sed -i '' 's/primary\.opacity(isDarkTheme ? 0\.08 : 0\.04)/primary.opacity(0.08)/' "$file"
    sed -i '' 's/tertiary\.opacity(isDarkTheme ? 0\.06 : 0\.035)/tertiary.opacity(0.06)/' "$file"
    
    echo "✓ Done"
done

echo "All theme files updated!"
