import SwiftUI

struct Backgrounds: View {
    @Binding var current: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<BackgroundGroup.all.count, id: \.self) { index in
                    let gradient = BackgroundGroup.all[index]
                    makeItem(gradient)
                        .frame(width: 50, height: 50)
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 70)
    }

    func makeItem(_ gradient: BackgroundGroup.GradientName) -> some View {
        Button(action: {
            current = gradient.rawValue
        }) {
            ZStack {
                BackgroundGroup(for: gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if current == gradient.rawValue {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Backgrounds") {
    RootView {
        Backgrounds(current: .constant("3"))
    }
}

#Preview("App") {
    AppPreview()
        .frame(width: 800, height: 800)
}
