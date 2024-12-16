import SwiftUI
import Foundation
import OSLog
import MagicKit

class DatabasePlugin: SuperPlugin, SuperLog {
    var emoji = "💾"
    var label: String = "DB"
    var icon: String = "database.fill"
    var isTab: Bool = true

    @Published var provider: DatabaseProvider?
    
    init() {
        self.provider = DatabaseProvider()
    }
    
    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }
    
    func addListView() -> AnyView {
        guard let provider = provider else {
            return AnyView(EmptyView())
        }
        
        return AnyView(DBList().environmentObject(provider))
    }
    
    func addDetailView() -> AnyView {
        guard let provider = provider else {
            return AnyView(EmptyView())
        }
        
        return AnyView(DBDetail().environmentObject(provider))
    }
    
    func addToolBarTrailingView() -> AnyView {
        AnyView(EmptyView())
    }
    
    func onInit() {
        os_log("\(self.t) onInit")
    }
    
    func onAppear(project: Project?) {
        os_log("\(self.t) onAppear")
        if let project = project {
            provider?.loadConfigs(from: project)
        }
    }
    
    func onDisappear() {
        os_log("\(self.t) onDisappear")
    }
    
    func onPlay() {
        os_log("\(self.t) onPlay")
    }
    
    func onPlayStateUpdate() {
        os_log("\(self.t) onPlayStateUpdate")
    }
    
    func onPlayAssetUpdate() {
        os_log("\(self.t) onPlayAssetUpdate")
    }
}

#Preview {
    DBDetail()
        .environmentObject(AppProvider())
        .environmentObject(GitProvider())
        .environmentObject(DatabaseProvider())
}
