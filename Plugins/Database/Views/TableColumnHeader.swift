import SwiftUI

struct TableColumnHeader: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
            
            Image(systemName: "arrow.up.arrow.down.square.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1, height: nil)
                .foregroundColor(Color(.separatorColor)),
            alignment: .trailing
        )
        .overlay(
            Rectangle()
                .frame(width: nil, height: 1)
                .foregroundColor(Color(.separatorColor)),
            alignment: .bottom
        )
    }
}
