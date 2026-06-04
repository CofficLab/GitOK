import SwiftUI
import GitOKCoreKit


/// 图标网格项预览
struct IconTilePreview: View {
    let iconAsset: IconAsset

    @EnvironmentObject var iconProvider: IconProvider

    private var isSelected: Bool {
        iconProvider.selectedIconId == iconAsset.iconId
    }

    init(_ iconAsset: IconAsset) {
        self.iconAsset = iconAsset
    }

    var body: some View {
        AppSelectionTile(
            isSelected: isSelected,
            cornerRadius: 8,
            selectedBorderColor: Color.accentColor,
            selectedBorderWidth: 2,
            action: { iconProvider.selectIcon(iconAsset.iconId) }
        ) {
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
        }
        .frame(width: 48, height: 48)
    }
}
