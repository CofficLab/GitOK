import GitOKFoundationKit
import SwiftUI

extension MagicContainer {
    @ViewBuilder
    var iOSAppStoreButton: some View {
        let containerSize = CGSize(width: containerWidth, height: containerHeight)
        if containerSize.isPortrait {
            Button(action: captureAppStoreView) {
                HStack {
                    Image(systemName: "camera.aperture")
                    Text("iOS App Store 截图")
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
        }
    }
}



