import MagicKit
import SwiftUI

struct BtnGitCloneView: View, SuperLog {
    nonisolated static let emoji = "📥"
    nonisolated static let verbose = false

    @State private var showCloneSheet = false

    static let shared = BtnGitCloneView()

    private init() {}

    var body: some View {
        Image(systemName: "square.and.arrow.down")
            .resizable()
            .scaledToFit()
            .frame(height: 18)
            .frame(width: 18)
            .inButtonWithAction {
                showCloneSheet = true
            }
            .toolbarButtonStyle()
            .sheet(isPresented: $showCloneSheet) {
                CloneRepositorySheet()
            }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
