import Foundation
import SwiftData
import SwiftUI

struct BtnAddBanner: View {
    @Environment(\.modelContext) var context: ModelContext
    @EnvironmentObject var app: AppManager
    
    var callback: (_ banner: BannerModel) -> Void

    var body: some View {
        Button(action: {
            if let project = app.project {
                let banner = BannerModel.new(project)
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
