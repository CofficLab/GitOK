import SwiftUI

struct APIList: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var apiProvider: APIProvider
    
    var body: some View {
        if let project = g.project {
            List {
                Section {
                    ForEach(apiProvider.requests) { request in
                        RequestListItem(request: request, isSelected: apiProvider.selectedRequestId == request.id)
                            .tag(request)
                            .onTapGesture {
                                if apiProvider.selectedRequestId == request.id {
                                    apiProvider.startEditing(request)
                                } else {
                                    apiProvider.selectRequest(request)
                                }
                            }
                            .contextMenu {
                                Button("Edit") {
                                    apiProvider.startEditing(request)
                                }
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
                apiProvider.loadRequests(from: project)
            }
        }
    }
    
    private func createNewRequest() {
        let newRequest = APIRequest(name: "New Request", url: "")
        apiProvider.startEditing(newRequest)
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