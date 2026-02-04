import SwiftUI

struct LicenseSidebar: View {
    @Binding var pane: LicensePane

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前")
                .font(.caption)
                .foregroundColor(.secondary)

            SidebarRow(
                title: "LICENSE",
                icon: "doc.plaintext",
                isSelected: pane == .current
            ) {
                pane = .current
            }

            Divider()

            Text("模板")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(LicenseTemplate.allCases) { template in
                SidebarRow(
                    title: template.title,
                    icon: "doc.text",
                    isSelected: pane == .template(template)
                ) {
                    pane = .template(template)
                }
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SidebarRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .accentColor : .secondary)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
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

