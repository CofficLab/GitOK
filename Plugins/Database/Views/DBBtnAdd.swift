import SwiftUI

struct DBBtnAdd: View {
    @Binding var showingAddConfig: Bool

    var body: some View {
        TabBtn(title: "Add Config", imageName: "plus.circle", onTap: {
            showingAddConfig = true
        })
    }
}
