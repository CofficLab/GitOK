import GitOKCoreKit
import SwiftUI

struct LicenseStatusIcon: View {
    let projectURL: URL

    @State private var isSheetPresented = false
    @State private var hasLicense = false

    init(projectURL: URL) {
        self.projectURL = projectURL
    }

    var body: some View {
        AppStatusBarTile(systemImage: "doc.plaintext", action: {
            isSheetPresented.toggle()
        })
        .help(hasLicense ? LicensePluginLocalization.string("View or edit LICENSE") : LicensePluginLocalization.string("LICENSE not found, click to create"))
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
