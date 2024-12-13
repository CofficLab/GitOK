import SwiftUI

struct APIList: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var apiProvider: APIProvider
    
    var body: some View {
        if let project = g.project {
            VStack {
                List(selection: Binding(
                    get: { apiProvider.selectedRequestId },
                    set: { newSelection in
                        if let requestId = newSelection {
                            let request = apiProvider.requests.first { $0.id == requestId }
                            if let request = request {
                                if apiProvider.isEditing {
                                    apiProvider.startEditing(request)
                                } else if apiProvider.selectedRequestId == request.id {
                                    apiProvider.startEditing(request)
                                } else {
                                    apiProvider.selectRequest(request)
                                }
                            }
                        }
                    }
                )) {
                    Section {
                        ForEach(apiProvider.requests) { request in
                            RequestListItem(request: request, isSelected: apiProvider.selectedRequestId == request.id)
                                .tag(request.id)
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
