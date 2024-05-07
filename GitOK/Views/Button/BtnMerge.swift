import SwiftUI

struct BtnMerge: View {
    var path: String
    var from: Branch
    var to: Branch

    var body: some View {
        Button("Merge", action: {
            _ = try! Git.setBranch(to, path)
            try! Git.merge(from, path, message: CommitCategory.CI.text + "Merge \(from) by GitOK")
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
