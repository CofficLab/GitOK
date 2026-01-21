import SwiftUI


/// 图标网格项预览
struct IconTilePreview: View {
    let iconAsset: IconAsset

    @EnvironmentObject var iconProvider: IconProvider
    @State private var isHovered = false

    private var isSelected: Bool {
        iconProvider.selectedIconId == iconAsset.iconId
    }

    init(_ iconAsset: IconAsset) {
        self.iconAsset = iconAsset
    }

    var body: some View {
        ZStack {
            if let model = iconProvider.currentData {
                IconPreview(iconData: model, iconAsset: iconAsset)
            } else {
                // 退化占位
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 48, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture { iconProvider.selectIcon(iconAsset.iconId) }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}


