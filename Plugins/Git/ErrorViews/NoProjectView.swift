import SwiftUI

struct NoProjectView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.open")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
    
            Text("请选择项目")
                .font(.headline)
                .padding()
    
            Text("请选择项目")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }
}
