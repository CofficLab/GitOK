import GitOKPluginKit
import SwiftUI

struct LicenseStatusIcon: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    @State private var isSheetPresented = false
    @State private var hasLicense = false

    var body: some View {
        Button {
            isSheetPresented.toggle()
        } label: {
            Image(systemName: "doc.plaintext")
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(hasLicense ? PluginLicenseLocalization.string("View or edit LICENSE") : PluginLicenseLocalization.string("LICENSE not found, click to create"))
        .disabled(projectURL == nil)
        .sheet(isPresented: $isSheetPresented) {
            LicenseViewer()
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkLicenseExistence)
        .onChange(of: projectURL) {
            checkLicenseExistence()
        }
    }

    private func checkLicenseExistence() {
        guard let projectURL else {
            hasLicense = false
            return
        }

        hasLicense = LicenseDocument.exists(in: projectURL)
    }
}
