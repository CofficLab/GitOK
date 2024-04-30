import Foundation
import SwiftData
import SwiftUI

struct BtnAddIcon2: View {
    @Environment(\.modelContext) var context: ModelContext
    @EnvironmentObject var app: AppManager
    
    var callback: (_ icon: IconModel2) -> Void

    var body: some View {
        Button(action: {
            if let project = app.project {
                let icon = IconModel2.new(project)
                callback(icon)
            }
        }, label: {
            Label("添加Icon", systemImage: "plus.circle")
        })
    }
}

#Preview {
    AppPreview()
}
