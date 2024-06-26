import SwiftUI

struct BtnFinder: View {
    var url: URL
    
    var body: some View {
        Button(action: {
            NSWorkspace.shared.open(url)
        }, label: {
            Label("在Finder中显示", systemImage: "doc.viewfinder.fill")
        })
    }
}

#Preview {
    AppPreview()
}
