import SwiftUI

struct DocTabs: View {
    @EnvironmentObject var app: AppManager

    var docs: [Doc]

    var body: some View {
        HStack {
            ForEach(docs, id: \.uuid) { doc in
                Divider()
                DocTab(doc: doc, selected: doc.uuid == app.doc?.uuid)
            }
        }
        .onAppear {
            app.doc = docs.first
        }
        .onChange(of: docs, {
            app.doc = docs.first
        })
    }
}

#Preview {
    BannerPreview()
        .frame(width: 800)
        .frame(height: 800)
}
