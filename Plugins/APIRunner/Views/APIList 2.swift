import SwiftUI

struct APIList: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var apiProvider: APIProvider
    @State private var requests: [APIRequest] = []
    @State private var selectedRequest: APIRequest? {
        willSet {
            apiProvider.setSelectedRequestId(newValue?.id)
        }
    }

    @State private var isEditing = false
    @State private var editingRequest = APIRequest(name: "New Request", url: "")

    var body: some View {
        if let project = g.project {
            VStack {
                List {
                    Section {
                        ForEach(requests) { request in
                            RequestListItem(request: request, isSelected: selectedRequest?.id == request.id)
                                .tag(request)
                                .onTapGesture {
                                    if selectedRequest?.id == request.id {
                                        // 再次点击已选中的请求进入编辑模式
                                        editingRequest = request
                                        isEditing = true
                                    } else {
                                        selectedRequest = request
                                        isEditing = false
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
                loadConfig(project: project)
                if let selectedId = apiProvider.selectedRequestId {
                    selectedRequest = requests.first { $0.id == selectedId }
                }
            }
        }
    }

    private func createNewRequest() {
        selectedRequest = nil // 清除选中状态
        editingRequest = APIRequest(name: "New Request", url: "")
        isEditing = true
    }

    private func loadConfig(project: Project) {
        let config = APIConfig.load(from: project)
        requests = config.requests
        apiProvider.setRequests(requests)
    }

    private func saveConfig(project: Project) {
        let config = APIConfig(requests: requests)
        try? config.save(to: project)
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
