import SwiftUI
import GitOKCoreKit


struct IconListActions: View {
    var body: some View {
        HStack(spacing: 0) {
            BtnNewIcon()
        }
        .frame(height: 25)
        .labelStyle(.iconOnly)
    }
}
