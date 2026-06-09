import GitOKFoundationKit
import SwiftUI

extension MagicContainer {
    @ViewBuilder
    var macAppStoreButton: some View {
        let containerSize = CGSize(width: containerWidth, height: containerHeight)
        if containerSize.isLandscape {
            Button(action: captureMacAppStoreView) {
                HStack {
                    Image(systemName: "laptopcomputer")
                    Text("macOS App Store 截图")
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
        }
    }
}


