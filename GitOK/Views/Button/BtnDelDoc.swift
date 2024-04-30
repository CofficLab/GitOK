import Foundation
import SwiftData
import SwiftUI

struct BtnDelDoc: View {
    @Environment(\.modelContext) var context: ModelContext
    @EnvironmentObject var app: AppManager
    
    @Query var tasks: [TaskModel]
    @Query var icons: [IconModel]
    @Query var banners: [BannerModel]
    
    var body: some View {
        SmartButton(
            title: "删除",
            systemImage: "trash",
            onTap: {
                let uuid = app.doc?.uuid
                app.doc = nil
                
                if let banner = banners.first(where: {
                    $0.uuid == uuid
                }) {
                    context.delete(banner)
                }
                
                if let icon = icons.first(where: {
                    $0.uuid == uuid
                }) {
                    context.delete(icon)
                }
            })
    }
}

#Preview {
    BannerPreview()
}
