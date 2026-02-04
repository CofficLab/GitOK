import SwiftUI

struct LicenseHeader: View {
    @EnvironmentObject var data: DataProvider
    @Environment(\.dismiss) private var dismiss

    let isSaving: Bool
    let isLoading: Bool
    let statusMessage: String?
    let onSave: (@escaping () -> Void) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.plaintext")
                .foregroundColor(.blue)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("LICENSE")
                    .font(.headline)
                    .fontWeight(.semibold)

                if let project = data.project {
                    Text(project.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let status = statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image.upload.inButtonWithAction {
                onSave {
                }
            }
            .frame(width: 120)
            .disabled(isSaving || isLoading)

            Image.close.inButtonWithAction {
                dismiss()
            }
            .frame(width: 120)
            .keyboardShortcut(.cancelAction)
        }
        .frame(height: 40)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
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
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

