import SwiftUI
import UniformTypeIdentifiers
import MagicCore

struct Snapshot<Content>: View where Content: View {
    private let mark: String
    private let content: Content

    var onMessage: (_ message: String) -> Void
    var buttonOnToolbar: Bool = true

    init(mark: String = "", onMessage: @escaping (_ message: String) -> Void, @ViewBuilder content: () -> Content) {
        self.mark = mark
        self.content = content()
        self.onMessage = onMessage
    }

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                // MARK: 操作栏
                makeActionBar(geo)

                HStack {
                    Spacer()
                    MagicImage.makeImage(content)
                        .resizable()
                        .scaledToFit()
//                        .overlay { MagicImage.dashedBorder }
                    Spacer()
                }

                Spacer()
            }
            .frame(
                width: getContainerWidth(geo),
                height: getContainerHeight(geo))
        }
    }

    private func getContainerWidth(_ geo: GeometryProxy) -> CGFloat {
        max(geo.size.width, 100)
    }

    private func getContainerHeight(_ geo: GeometryProxy) -> CGFloat {
        max(geo.size.height, 100)
    }

    @MainActor private func makeActionBar(_ geo: GeometryProxy) -> some View {
        HStack {
            Spacer()
            if !mark.isEmpty {
                Text(mark)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
            }

            Operator("\(MagicImage.getViewWidth(content)) X \(MagicImage.getViewHeigth(content))")
            
            Spacer()
        }
        .foregroundStyle(.white)
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}

