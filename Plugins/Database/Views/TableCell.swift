import SwiftUI

struct TableCell: View {
    let value: Any?
    
    var body: some View {
        Text(formatValue(value))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(getCellColor(value))
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                Rectangle()
                    .frame(width: 1, height: nil)
                    .foregroundColor(Color(.separatorColor)),
                alignment: .trailing
            )
            .contentShape(Rectangle())
            .contextMenu {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(formatValue(value), forType: .string)
                }
            }
    }
    
    private func formatValue(_ value: Any?) -> String {
        if let value = value {
            if value is NSNull {
                return "NULL"
            } else {
                return String(describing: value)
            }
        }
        return ""
    }
    
    private func getCellColor(_ value: Any?) -> Color {
        if value is NSNull {
            return .secondary
        } else if value is Int || value is Double {
            return .blue
        } else if let str = value as? String, str.lowercased() == "true" || str.lowercased() == "false" {
            return .green
        }
        return .primary
    }
}
