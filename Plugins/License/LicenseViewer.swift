import MagicCore
import MagicUI
import OSLog
import SwiftUI

struct LicenseViewer: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    @Environment(\.dismiss) private var dismiss

    @State private var content: String = ""
    @State private var isLoading: Bool = true
    @State private var isSaving: Bool = false
    @State private var hasError: Bool = false
    @State private var statusMessage: String?
    @State private var pane: LicensePane = .current

    private let verbose = false

    var body: some View {
        VStack(spacing: 0) {
            LicenseHeader(
                isSaving: isSaving,
                isLoading: isLoading,
                statusMessage: statusMessage,
                onSave: { completion in
                    saveLicense(onComplete: completion)
                }
            )

            Divider()

            if isLoading {
                loadingView
            } else {
                HSplitView {
                    LicenseSidebar(pane: $pane)
                        .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)
                        .frame(maxHeight: .infinity)

                    contentPane
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear(perform: loadLicense)
        .onChange(of: data.project, loadLicense)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("正在加载 LICENSE ...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var contentPane: some View {
        switch pane {
        case .current:
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .background(Color(NSColor.textBackgroundColor))
        case .template(let template):
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(template.title) 模板")
                            .font(.headline)
                        Text(template.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    MagicButton.simple {
                        content = template.content
                        pane = .current
                        statusMessage = "已应用模板：\(template.title)"
                    }
                    .magicTitle("应用到当前")
                    .magicIcon(.iconCopy)
                    .magicSize(.auto)
                    .magicShape(.roundedRectangle)
                    .frame(width: 120)
                }
                .frame(height: 40)
                .padding()
                Divider()
                ScrollView {
                    Text(template.content)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }

    private func loadLicense() {
        guard let project = data.project else {
            content = ""
            isLoading = false
            hasError = true
            return
        }

        isLoading = true
        hasError = false
        statusMessage = nil

        Task {
            do {
                let text = try await project.getLicenseContent()
                await MainActor.run {
                    self.content = text
                    self.isLoading = false
                    self.hasError = false
                }
            } catch {
                await MainActor.run {
                    self.content = LicenseTemplate.mit.content
                    self.isLoading = false
                    self.hasError = true
                    self.statusMessage = "未找到 LICENSE，已加载模板 \(LicenseTemplate.mit.title)"
                }
                if verbose {
                    os_log(.info, "\(self.t)LICENSE not found: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveLicense(onComplete: @escaping () -> Void) {
        guard let project = data.project else { return }
        isSaving = true
        statusMessage = nil

        Task {
            do {
                try await project.saveLicenseContent(content)
                await MainActor.run {
                    self.isSaving = false
                    self.hasError = false
                    self.statusMessage = "已保存 LICENSE"
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.hasError = true
                    self.statusMessage = "保存失败：\(error.localizedDescription)"
                    onComplete()
                }
                if verbose {
                    os_log(.error, "\(self.t)Failed to save license: \(error.localizedDescription)")
                }
            }
        }
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

