import SwiftUI

struct Backgrounds: View {
    @Binding var current: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(BackgroundGroup.all.sorted(by: { $0.key < $1.key }), id: \.key) { x, value in
                    makeItem(x, view: value)
                        .frame(width: 50)
                }
                Divider()
            }
            .frame(height: 40)
        }
    }

    func makeItem(_ id: String, view: some View) -> some View {
        ZStack(alignment: .leading) {
            view

//            Text(id).padding(.leading, 10)
        }
        .border(current == id ? .red : .clear)
        .onTapGesture {
            current = id
        }
    }
}

#Preview("Backgrounds") {
    RootView {
        Backgrounds(current: .constant("3"))
    }
}

#Preview("App") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
