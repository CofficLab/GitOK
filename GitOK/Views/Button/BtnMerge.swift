import SwiftUI

struct BtnMerge: View {
    var path: String
    var from: Branch
    var to: Branch

    var body: some View {
        Button("Merge", action: {
            _ = try! Git.setBranch(to, path)
            _ = try! Git.merge(from, path)
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
