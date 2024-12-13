import SwiftUI

struct TimingRow: View {
    let label: String
    let value: TimeInterval?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if let value = value {
                Text(String(format: "%.2fms", value * 1000))
                    .monospacedDigit()
            } else {
                Text("N/A")
                    .foregroundColor(.secondary)
            }
        }
    }
}
