import SwiftData
import SwiftUI

struct IconFields: View {
    @EnvironmentObject var app: AppManager
    @Environment(\.modelContext) var context: ModelContext

    @State var title = ""

    var icon: IconModel

    var body: some View {
        VStack {
            GroupBox {
                HStack {
                    Button("换图") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
//                            self.icon.updateImageURL(url)
                        }
                    }

                    Spacer()
                }
            }
        }
        .onAppear {
            self.title = icon.title
        }
        .onChange(of: icon, {
            self.title = icon.title
        })
    }

    func updateTitle(_ t: String) {
//        icon.title = t
    }

    func updateImage(_ image: URL) {
//        icon.imageURL = image
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
