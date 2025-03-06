import OSLog
import SwiftUI

struct ResponseBody: View {
    let response: APIResponse?

    @State private var viewMode: ViewMode = .pretty

    enum ViewMode {
        case pretty, raw, preview
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("", selection: $viewMode) {
                    Text("Raw").tag(ViewMode.raw)
                    Text("Pretty").tag(ViewMode.pretty)
                    Text("Preview").tag(ViewMode.preview)
                }
                .pickerStyle(.segmented)

                Spacer()
            }

            if let body = response?.body {
                switch viewMode {
                case .pretty:
                    ResponsePretty(content: body)
                case .raw:
                    ResponseRawView(content: body)
                case .preview:
                    ResponsePreview(content: body)
                }
            }
        }
    }
}
