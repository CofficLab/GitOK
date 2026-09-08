import SwiftUI
import LumiUI

/// 协作者设置插件的 About 页面。
struct CoAuthorSettingsAboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(CoAuthorSettingsLocalization.string("Co-Authors", bundle: .module))
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(CoAuthorSettingsLocalization.string("Manage co-authors that can be added to commit trailers as Co-authored-by lines.", bundle: .module))
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text(CoAuthorSettingsLocalization.string("Features", bundle: .module))
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Label(CoAuthorSettingsLocalization.string("Add, edit, and delete co-authors", bundle: .module), systemImage: "person.2")
                        Label(CoAuthorSettingsLocalization.string("Co-authors are stored locally and persisted across sessions", bundle: .module), systemImage: "internaldrive")
                        Label(CoAuthorSettingsLocalization.string("Select co-authors in the commit form to add Co-authored-by trailers", bundle: .module), systemImage: "checkmark.circle")
                    }
                    .font(.body)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
