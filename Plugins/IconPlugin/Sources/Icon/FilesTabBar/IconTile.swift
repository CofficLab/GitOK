
import SwiftUI
import GitOKCoreKit
import GitOKUI

struct IconTile: View {
    var icon: IconData

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(4)
                    .gitOKUISurface(style: .subtle, cornerRadius: 4)

                Text(icon.title).font(.title3)
                Spacer()
            }
        }
    }
}
