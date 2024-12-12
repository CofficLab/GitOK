import MagicKit
import SwiftUI

struct APIDetail: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var apiProvider: APIProvider
    
    var body: some View {
        if let project = g.project {
            if apiProvider.isEditing, let editingRequest = apiProvider.editingRequest {
                // 编辑模式
                RequestEditor(request: .constant(editingRequest)) { savedRequest in
                    apiProvider.saveRequest(savedRequest, to: project)
                }
            } else if let selectedRequest = apiProvider.requests.first(where: { $0.id == apiProvider.selectedRequestId }) {
                // 详情模式
                VStack {
                    RequestDetailView(request: .constant(selectedRequest))
                }
            } else {
                // 空状态
                VStack {
                    Spacer()
                    Text("Select a request")
                        .font(.headline)
                    Text("or create a new one")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Current project: \(g.project?.title ?? "None")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Current request id: \(apiProvider.selectedRequestId?.uuidString ?? "None")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Is editing: \(apiProvider.isEditing ? "Yes" : "No")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Editing request id: \(apiProvider.editingRequest?.id.uuidString ?? "None")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
        }
    }
}

