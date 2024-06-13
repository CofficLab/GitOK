import SwiftUI

struct CommitDetail: View {
    var commit: GitCommit
    
    var body: some View {
        Text(commit.message)
    }
}

#Preview {
    AppPreview()
}
