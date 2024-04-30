import SwiftData
import SwiftUI

struct TaskList: View {
    @EnvironmentObject var app: AppManager

    @State var selection: String?

    @Query var tasks: [TaskModel]

    var body: some View {
        VStack {
            List(tasks, id: \.uuid, selection: $selection) { task in
                Text(task.title)
            }
            
            Spacer()
            
            // 操作
            HStack {
                BtnAddTask()
            }
        }
        .onChange(of: selection) {
            if let s = tasks.first(where: {
                $0.uuid == selection
            }) {
                app.setCurrentTask(s)
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
