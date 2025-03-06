import SwiftUI

struct TimelineView: View {
    let response: APIResponse?

    var body: some View {
        GroupBox("Request Timeline") {
            // 这里可以添加一个可视化的时间轴
            Text("Timeline visualization coming soon")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
}


