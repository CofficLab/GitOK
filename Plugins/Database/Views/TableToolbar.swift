import SwiftUI

struct TableToolbar: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.down")
                }
                
                Menu {
                    Button("100 rows", action: {})
                    Button("500 rows", action: {})
                    Button("1000 rows", action: {})
                    Button("All rows", action: {})
                } label: {
                    Label("Limit", systemImage: "line.3.horizontal.decrease")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }
}
