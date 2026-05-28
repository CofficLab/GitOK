import GitOKPluginKit
import SwiftUI

struct LicenseViewer: View {
    @Environment(\.gitOKProjectURL) private var projectURL
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var hasError = false
    @State private var statusMessage: String?
    @State private var selectedPane = LicensePane.current

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
                    Text(PluginLicenseLocalization.string("LICENSE"))
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let projectURL {
                        Text(projectURL.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                ProgressView()
                    .controlSize(.small)
            }

            Button(PluginLicenseLocalization.string("Save")) {
                saveLicense()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(isLoading || isSaving || projectURL == nil)

            Button(PluginLicenseLocalization.string("Close")) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(PluginLicenseLocalization.string("Loading LICENSE..."))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sidebar: some View {
        List(selection: $selectedPane) {
            Section {
                Label(PluginLicenseLocalization.string("Current"), systemImage: "doc.text")
                    .tag(LicensePane.current)
            }

            Section(PluginLicenseLocalization.string("Templates")) {
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
                        Text(String(format: PluginLicenseLocalization.string("%@ Template"), template.title))
                            .font(.headline)
                        Text(template.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(PluginLicenseLocalization.string("Apply to Current")) {
                        content = template.content
                        selectedPane = .current
                        statusMessage = String(format: PluginLicenseLocalization.string("Template applied: %@"), template.title)
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
        guard let projectURL else {
            content = ""
            isLoading = false
            hasError = true
            statusMessage = PluginLicenseLocalization.string("No project selected")
            return
        }

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
                    statusMessage = String(format: PluginLicenseLocalization.string("LICENSE not found, loaded template %@"), template.title)
                }
            }
        }
    }

    private func saveLicense() {
        guard let projectURL else { return }

        isSaving = true
        statusMessage = nil

        Task {
            do {
                try LicenseDocument.write(content, in: projectURL)
                await MainActor.run {
                    isSaving = false
                    hasError = false
                    statusMessage = PluginLicenseLocalization.string("LICENSE saved")
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    hasError = true
                    statusMessage = String(format: PluginLicenseLocalization.string("Save failed: %@"), error.localizedDescription)
                }
            }
        }
    }
}

private enum LicensePane: Hashable {
    case current
    case template(LicenseTemplate)
}
