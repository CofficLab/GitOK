import SwiftUI
import OSLog
import MagicKit

struct BtnMerge: View, SuperEvent, SuperThread {
    @EnvironmentObject var m: MessageProvider


    var path: String
    var from: Branch
    var to: Branch
    var git = Git()

    @State private var isHovering = false

    var body: some View {
        Button("Merge", action: merge)
            .padding()
            .cornerRadius(8)
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
    
    func merge() {
        self.bg.async {
            do {
                try git.setBranch(to, path)
                try git.merge(from, path, message: CommitCategory.CI.text + "Merge \(from.name) by GitOK")
            } catch let error {
                os_log(.error, "\(error.localizedDescription)")

                m.setError(error)
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
