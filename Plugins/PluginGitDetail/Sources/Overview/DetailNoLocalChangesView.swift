import SwiftUI

struct DetailNoLocalChangesView: View {
    var body: some View {
        DetailGuideView(
            systemImage: "checkmark.circle",
            title: "没有本地更改",
            subtitle: "全部更改已提交到本地仓库"
        )
        .setIconColor(.green)
    }
}
