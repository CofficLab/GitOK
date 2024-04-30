import Foundation
import SwiftData
import SwiftUI

struct BtnAddTask: View {
    @Environment(\.modelContext) var context: ModelContext
    @EnvironmentObject var app: AppManager

    var body: some View {
        Button(action: {
            if let project = app.project {
                let task = TaskModel.makeSample(project.path)
                context.insert(task)
                
                app.setCurrentTask(task)
            }
        }, label: {
            Label("添加", systemImage: "plus.circle")
        })
    }
}

#Preview {
    AppPreview()
}
