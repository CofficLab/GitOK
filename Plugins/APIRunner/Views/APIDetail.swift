import MagicKit
import SwiftUI

struct APIDetail: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var apiProvider: APIProvider
    
    var body: some View {
        if let project = g.project {
            if apiProvider.isEditing {
                // 编辑模式
                if let editingRequest = apiProvider.editingRequest {
                    RequestEditor(request: .constant(editingRequest)) { savedRequest in
                        // 保存请求
                        var config = APIConfig.load(from: project)
                        if let index = config.requests.firstIndex(where: { $0.id == savedRequest.id }) {
                            config.requests[index] = savedRequest
                        } else {
                            config.requests.append(savedRequest)
                        }
                        try? config.save(to: project)
                        
                        // 更新状态
                        apiProvider.selectedRequestId = savedRequest.id
                        apiProvider.stopEditing()
                    }
                }
            } else if let selectedRequest = APIConfig.load(from: project)
                .requests.first(where: { $0.id == apiProvider.selectedRequestId }) {
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
                    Spacer()
                }
            }
        }
    }
}

