import SwiftUI

struct BtnMerge: View {
    var path: String
    var from: Branch
    var to: Branch
    var git = Git()

    var body: some View {
        Button("Merge", action: {
            _ = try! git.setBranch(to, path)
            try! git.merge(from, path, message: CommitCategory.CI.text + "Merge \(from) by GitOK")
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
