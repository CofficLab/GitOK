import SwiftUI

struct RequestBar: View {
    @EnvironmentObject var apiProvider: APIProvider
    
    @Binding var request: APIRequest

    @State var isHeadersExpanded = false

    var body: some View {
        GroupBox {
            HStack {
                Menu {
                    ForEach(APIRequest.HTTPMethod.allCases, id: \.self) { method in
                        Button(action: {
                            request.method = method
                        }) {
                            Text(method.rawValue)
                        }
                    }
                } label: {
                    Text(request.method.rawValue)
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                        .frame(width: 30)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }.frame(width: 80)

                TextField("URL", text: $request.url)
                    .textFieldStyle(.plain)
                    .font(.body)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: sendRequest) {
                        Text("Send")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    Button("Delete") {
                        // 删除逻辑
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
    }

    private func sendRequest() {
        Task {
            do {
                _ = try await apiProvider.sendRequest(request)
            } catch {
                print("Request failed: \(error)")
            }
        }
    }

}
