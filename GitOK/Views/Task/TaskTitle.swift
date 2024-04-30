import SwiftData
import SwiftUI

struct TaskTitle: View {
    @EnvironmentObject var app: AppManager

    @State var title: String = ""
    @State var selection: String?
    @State var editing = false
    @State var hovered = false

    @Query var tasks: [TaskModel]

    var task: TaskModel? { app.currentTask }

    var body: some View {
        GroupBox {
            HStack {
                if let task = task {
                    if editing {
                        TextField("", text: $title, onEditingChanged: { editing in
                            self.editing = editing
                            if editing == false {
                                task.title = title
                            }
                        })
                        .font(.title2)
                        .onAppear {
                            self.title = task.title
                        }
                        .onSubmit {
                            editing = false
                            task.title = title
                        }
                    } else {
                        Text(task.title)
                            .font(.title2)
                            .onTapGesture {
                                editing = true
                            }
                    }
                }

                TaskList()
            }
        }
        .onHover(perform: { hovering in
            self.hovered = hovering
        })
        .onAppear {
            if let s = tasks.first(where: {
                $0.uuid == AppConfig.currentTaskUUID
            }) {
                app.setCurrentTask(s)
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 700)
}
