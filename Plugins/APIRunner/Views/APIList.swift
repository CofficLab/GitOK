import SwiftUI

struct APIList: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var apiProvider: APIProvider
    
    var body: some View {
        if let project = g.project {
            VStack {
                List {
                    Section {
                        ForEach(apiProvider.requests) { request in
                            RequestListItem(request: request, isSelected: apiProvider.selectedRequestId == request.id)
                                .tag(request)
                                .onTapGesture {
                                    if apiProvider.isEditing {
                                        // 如果正在编辑，直接切换到新的请求编辑
                                        apiProvider.startEditing(request)
                                    } else if apiProvider.selectedRequestId == request.id {
                                        // 双击已选中的请求进入编辑模式
                                        apiProvider.startEditing(request)
                                    } else {
                                        // 选择新的请求
                                        apiProvider.selectRequest(request)
                                    }
                                }
                        }
                    }
                }
                
                Spacer()
                
                Section {
                    Button(action: createNewRequest) {
                        Label("New Request", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                apiProvider.setCurrentProject(project)
            }
        }
    }

    private func createNewRequest() {
        let newRequest = apiProvider.createNewRequest()
        apiProvider.startEditing(newRequest)
    }
}

// 请求列表项组件
struct RequestListItem: View {
    let request: APIRequest
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(request.name)
            Spacer()
            Text(request.method.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}
