import MagicCore
import OSLog
import SwiftUI

class ProjectPickerPlugin: SuperPlugin, SuperLog {
    let emoji = "📁"
    static var label: String = "ProjectPicker"
    var isTab: Bool = false
    static let shared = ProjectPickerPlugin()
    
    private init() {
        
    }

    func addToolBarLeadingView() -> AnyView {
        AnyView(ProjectPickerView())
    }
}
