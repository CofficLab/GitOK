import SwiftUI

struct APIList: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var apiProvider: APIProvider
    
    @State private var selection: UUID?
    
    var body: some View {
        if let project = g.project {
            VStack {
                List(selection: $selection) {
                    Section {
                        ForEach(apiProvider.requests) { request in
                            RequestListItem(request: request, isSelected: apiProvider.selectedRequestId == request.id)
                                .tag(request.id)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let request = apiProvider.requests[index]
                                try? apiProvider.deleteRequest(request)
                            }
                        }
                    }
                }
                .onChange(of: selection) {
                    apiProvider.selectRequestById(selection)
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
                apiProvider.selectRequest(apiProvider.requests.first)
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

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
