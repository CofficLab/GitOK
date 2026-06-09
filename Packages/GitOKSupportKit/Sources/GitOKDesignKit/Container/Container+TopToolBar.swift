import GitOKFoundationKit
import SwiftUI

extension MagicContainer {
    var topToolBar: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            VStack(spacing: 0) {
                // Top row
                HStack(spacing: 4) {
                    Spacer()

                    xcodeIconButton

                    macAppStoreButton

                    iOSAppStoreButton

                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: height * 0.7)
                .frame(maxWidth: .infinity)

                // Bottom
                sizeInfoView
                    .frame(height: height * 0.3)
                    .frame(maxWidth: .infinity)
            }
            .infinite()
            .background(Color.secondary.opacity(0.1))
        }
        .frame(height: toolBarHeight)
        .infiniteWidth()
    }
}


