import GitOKCoreKit
import GitOKUI
import SwiftUI

struct LicenseViewer: View {
    let projectURL: URL
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var hasError = false
    @State private var statusMessage: String?
    @State private var selectedPane = LicensePane.current

    init(projectURL: URL) {
        self.projectURL = projectURL
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if isLoading {
                loadingView
            } else {
                HSplitView {
                    sidebar
                        .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)
                        .frame(maxHeight: .infinity)

                    contentPane
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear(perform: loadLicense)
        .onChange(of: projectURL) {
            loadLicense()
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "doc.plaintext")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LicensePluginLocalization.string("LICENSE"))
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(projectURL.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(hasError ? .red : .secondary)
                    .lineLimit(1)
            }

            if isSaving {
                AppLoadingOverlay(size: .small)
                    .frame(width: 28, height: 28)
            }

            AppButton(
                LicensePluginLocalization.string("Save"),
                systemImage: "square.and.arrow.down",
                style: .secondary,
                size: .small,
                isLoading: isSaving
            ) {
                saveLicense()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(isLoading || isSaving)

            AppButton(
                LicensePluginLocalization.string("Close"),
                style: .secondary,
                size: .small
            ) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .gitOKUISurface(style: .toolbar, cornerRadius: 0)
    }

    private var loadingView: some View {
        AppLoadingOverlay(message: LicensePluginLocalization.string("Loading LICENSE..."), size: .large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sidebar: some View {
        List(selection: $selectedPane) {
            Section {
                Label(LicensePluginLocalization.string("Current"), systemImage: "doc.text")
                    .tag(LicensePane.current)
            }

            Section(LicensePluginLocalization.string("Templates")) {
                ForEach(LicenseTemplate.allCases) { template in
                    Label(template.title, systemImage: "doc.badge.plus")
                        .tag(LicensePane.template(template))
                }
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var contentPane: some View {
        switch selectedPane {
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
                        Text(String(format: LicensePluginLocalization.string("%@ Template"), template.title))
                            .font(.headline)
                        Text(template.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    AppButton(
                        LicensePluginLocalization.string("Apply to Current"),
                        systemImage: "arrow.down.doc",
                        style: .secondary,
                        size: .small
                    ) {
                        content = template.content
                        selectedPane = .current
                        statusMessage = String(format: LicensePluginLocalization.string("Template applied: %@"), template.title)
                        hasError = false
                    }
                }
                .frame(height: 44)
                .padding()

                Divider()

                ScrollView {
                    Text(template.content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }

    private func loadLicense() {
        isLoading = true
        hasError = false
        statusMessage = nil

        Task {
            do {
                let text = try LicenseDocument.read(in: projectURL)
                await MainActor.run {
                    content = text
                    isLoading = false
                    hasError = false
                }
            } catch {
                await MainActor.run {
                    let template = LicenseTemplate.mit
                    content = template.content
                    isLoading = false
                    hasError = false
                    statusMessage = String(format: LicensePluginLocalization.string("LICENSE not found, loaded template %@"), template.title)
                }
            }
        }
    }

    private func saveLicense() {
        isSaving = true
        statusMessage = nil

        Task {
            do {
                try LicenseDocument.write(content, in: projectURL)
                await MainActor.run {
                    isSaving = false
                    hasError = false
                    statusMessage = LicensePluginLocalization.string("LICENSE saved")
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    hasError = true
                    statusMessage = String(format: LicensePluginLocalization.string("Save failed: %@"), error.localizedDescription)
                }
            }
        }
    }
}

private enum LicensePane: Hashable {
    case current
    case template(LicenseTemplate)
}
