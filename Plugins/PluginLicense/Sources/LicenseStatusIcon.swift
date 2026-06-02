import SwiftUI

struct LicenseStatusIcon: View {
    let projectURL: URL

    @State private var isSheetPresented = false
    @State private var hasLicense = false

    init(projectURL: URL) {
        self.projectURL = projectURL
    }

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
        .sheet(isPresented: $isSheetPresented) {
            LicenseViewer(projectURL: projectURL)
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkLicenseExistence)
        .onChange(of: projectURL) {
            checkLicenseExistence()
        }
    }

    private func checkLicenseExistence() {
        hasLicense = LicenseDocument.exists(in: projectURL)
    }
}
