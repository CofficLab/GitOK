import Foundation
import SwiftUI
import SwiftData

struct BtnDel: View {
    @Environment(\.modelContext) var context: ModelContext
    @EnvironmentObject var app: AppManager
    @Query var tasks: [TaskModel]
    
    var task: TaskModel
    
    var body: some View {
        Button(action: {
            task.delete(context)
            
            if let first = tasks.first {
                app.currentTask = first
            }
        }, label: {
            Label("删除", systemImage: "trash")
        })
    }
}

#Preview {
    BannerPreview()
}
