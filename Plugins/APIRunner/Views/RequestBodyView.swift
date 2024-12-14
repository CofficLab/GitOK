import SwiftUI

struct RequestBodyView: View {
    @Binding var request: APIRequest
    
    @State var isHeadersExpanded = false 
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                Picker("Content-Type", selection: .constant(request.contentType)) {
                    ForEach(APIRequest.ContentType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                TextEditor(text: .constant(request.body ?? ""))
                    .font(.system(.body, design: .monospaced))
                    .frame(maxHeight: 300)
            }
        }    }
}
