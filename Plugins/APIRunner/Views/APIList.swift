import SwiftUI

struct APIList: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var apiProvider: APIProvider
    @State private var requests: [APIRequest] = []
    
    var body: some View {
        if let project = g.project {
            List {
                Section {
                    ForEach(requests) { request in
                        RequestListItem(request: request, isSelected: apiProvider.selectedRequestId == request.id)
                            .tag(request)
                            .onTapGesture {
                                apiProvider.selectedRequestId = request.id
                            }
                    }
                }
                
                Section {
                    Button(action: createNewRequest) {
                        Label("New Request", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                loadConfig(project: project)
            }
        }
    }
    
    private func createNewRequest() {
        apiProvider.startEditing(APIRequest(name: "New Request", url: ""))
    }
    
    private func loadConfig(project: Project) {
        let config = APIConfig.load(from: project)
        requests = config.requests
    }
}

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