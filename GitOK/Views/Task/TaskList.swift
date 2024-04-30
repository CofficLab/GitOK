import SwiftData
import SwiftUI

struct TaskList: View {
    @EnvironmentObject var app: AppManager

    @State var selection: String?
    @State var popover = false

    @Query var tasks: [TaskModel]

    var body: some View {
        ZStack {
            Button(action: {
                popover.toggle()
            }, label: {
                Label("更多", systemImage: "chevron.down")
                    .font(.subheadline)
            })
        }
        .popover(isPresented: $popover, content: {
            List(tasks, id: \.uuid, selection: $selection) { task in
                Text(task.title)
            }
        })
        .onChange(of: selection) {
            popover = false
            if let s = tasks.first(where: {
                $0.uuid == selection
            }) {
                app.setCurrentTask(s)
            }
        }
        .onChange(of: popover, {
            self.selection = app.currentTask?.uuid
        })
    }
}

#Preview {
    BannerPreview()
        .frame(width: 800)
        .frame(height: 800)
}
