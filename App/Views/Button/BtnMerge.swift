import SwiftUI
import OSLog

struct BtnMerge: View, SuperEvent, SuperThread {
    @EnvironmentObject var app: AppProvider

    var path: String
    var from: Branch
    var to: Branch
    var git = Git()

    var body: some View {
        Button("Merge", action: merge)
    }
    
    func merge() {
        self.bg.async {
            do {
                try git.setBranch(to, path)
                try git.merge(from, path, message: CommitCategory.CI.text + "Merge \(from.name) by GitOK")
            } catch let error {
                os_log(.error, "\(error.localizedDescription)")

                self.app.setError(error)
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
