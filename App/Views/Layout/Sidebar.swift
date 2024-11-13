import OSLog
import SwiftData
import SwiftUI
import MagicKit

struct Sidebar: View, SuperThread, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Projects()
            .toolbar(content: {
                ToolbarItem {
                    BtnAdd()
                }
            })
    }
}
