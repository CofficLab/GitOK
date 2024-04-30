import Foundation
import SwiftData
import SwiftUI

struct BtnAddBanner2: View {
    @Environment(\.modelContext) var context: ModelContext
    @EnvironmentObject var app: AppManager
    
    var callback: (_ banner: BannerModel2) -> Void

    var body: some View {
        Button(action: {
            if let project = app.project {
                let banner = BannerModel2.new(project)
                callback(banner)
            }
        }, label: {
            Label("添加Banner", systemImage: "plus.circle")
        })
    }
}

#Preview {
    AppPreview()
}
