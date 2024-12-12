import MagicKit
import SwiftUI

struct APIDetail: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var apiProvider: APIProvider
    
    var body: some View {
        if let project = g.project {
            if apiProvider.isEditing, var editingRequest = apiProvider.editingRequest {
                // 编辑模式
                RequestEditor(request: Binding(
                    get: { editingRequest },
                    set: { editingRequest = $0 }
                )) { savedRequest in
                    do {
                        try apiProvider.updateRequest(savedRequest)
                        m.toast("Request saved")
                        apiProvider.selectRequest(savedRequest)
                    } catch {
                        m.error(error)
                    }
                }
            } else if let selectedRequest = apiProvider.requests.first(where: { $0.id == apiProvider.selectedRequestId }) {
                // 详情模式
                VStack {
                    RequestDetailView(request: Binding(
                        get: { selectedRequest },
                        set: { newValue in
                            do {
                                try apiProvider.updateRequest(newValue)
                            } catch {
                                m.error(error)
                            }
                        }
                    ))
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

