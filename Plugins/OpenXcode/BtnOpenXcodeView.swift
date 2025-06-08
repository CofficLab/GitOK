import SwiftUI

struct BtnOpenXcodeView: View {
    @EnvironmentObject var g: DataProvider
    
    static let shared = BtnOpenXcodeView()
    
    private init() {}

    var body: some View {
        if let project = g.project {
            Button(action: {
                if let xcodeURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Xcode.app")) {
                    NSWorkspace.shared.open([project.url], withApplicationAt: xcodeURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                }
            }, label: {
                Label(
                    title: { Text("用Xcode打开") },
                    icon: {
                        Image("Xcode").resizable().scaledToFit().scaleEffect(0.85)
                    }
                )
            })
        }
    }
}
