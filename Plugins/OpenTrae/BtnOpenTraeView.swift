import SwiftUI

struct BtnOpenTraeView: View {
    @EnvironmentObject var g: DataProvider
    
    static let shared = BtnOpenTraeView()
    
    private init() {}

    var body: some View {
        if let project = g.project {
            Button(action: {
                if let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Trae.app")) {
                    NSWorkspace.shared.open([project.url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                }
            }, label: {
                Label(
                    title: { Text("用 Trae 打开") },
                    icon: {
                        Image("Trae").resizable().scaledToFit().scaleEffect(0.9)
                    }
                )
            })
            .help("用 Trae 打开")
        }
    }
}
