import SwiftUI

struct BtnMerge: View {
    @Binding var message: String

    var path: String
    var from: Branch
    var to: Branch

    var body: some View {
        Button("Merge", action: {
            message = try! Git.setBranch(to, path)
            message = try! Git.merge(from, path)
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
