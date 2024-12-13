import MagicKit
import SwiftUI

struct APIDetail: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var apiProvider: APIProvider

    var body: some View {
        if let project = g.project {
            if let selectedRequest = apiProvider.requests.first(where: { $0.id == apiProvider.selectedRequestId }) {
                // 详情模式
                VStack {
                    RequestDetailView(request: Binding(
                        get: { selectedRequest },
                        set: { newValue in
                            do {
                                try apiProvider.updateRequest(newValue, reason: "Update")
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

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
