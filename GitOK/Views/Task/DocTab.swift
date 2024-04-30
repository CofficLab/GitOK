import SwiftUI

struct DocTab: View {
    @EnvironmentObject var app: AppManager
    
    var doc: Doc
    var selected = false
    
    var background: some View {
        ZStack {
            if self.selected {
                Color.accentColor.opacity(0.5)
            } else {
                Color.clear
            }
        }
    }
    
    var body: some View {
        SmartButton(
            title: doc.title,
            systemImage: doc.image,
            selected: doc.uuid == app.doc?.uuid,
            onTap: {
                app.doc = doc
            })
    }
}

#Preview {
    BannerPreview()
        .frame(width: 800)
        .frame(height: 800)
}
