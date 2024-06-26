import SwiftUI
import SwiftData

struct BannerFields: View {
    @EnvironmentObject var app: AppManager
    @Environment(\.modelContext) var context: ModelContext

    @State var title = ""
    @State var subTitle = ""
    @State var features: [String] = []
    
    @Binding var banner: BannerModel?

    var body: some View {
        if let banner = banner {
            VStack {
                GroupBox {
                    TextField("title", text: $title)
                        .onChange(of: title) {
                            self.banner?.updateTitle(title)
                        }
                    TextField("subTitle", text: $subTitle)
                        .onChange(of: subTitle) {
                            self.banner?.updateSubTitle(subTitle)
                        }
                }

                GroupBox {
                    ForEach(0 ..< features.count, id: \.self) { index in
                        HStack {
                            Button(action: {
                                features.remove(at: index)
                            }) {
                                Label("减少", systemImage: "minus.circle")
                            }.labelStyle(.iconOnly)
                            TextField("Enter text", text: $features[index])
                        }
                    }

                    HStack {
                        Button(action: {
                            features.append("新特性")
                        }) {
                            Label("增加新特性", systemImage: "plus.rectangle")
                        }
                            .onChange(of: features) {
                                self.banner?.updateFeatures(features)
                            }
                        Spacer()
                    }
                }

                GroupBox {
                    HStack {
                        Button("换图") {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = false
                            if panel.runModal() == .OK, let url = panel.url {
                                let ext = url.pathExtension
                                let storeURL = AppConfig.imagesDir.appendingPathComponent("\(TimeHelper.getTimeString()).\(ext)")
                                do {
                                    try FileManager.default.copyItem(at: url, to: storeURL)
                                    self.banner?.updateImage(storeURL)
                                } catch let e {
                                    print(e)
                                }
                            }
                        }
                        Text("iPad mini 截屏")
                        Spacer()
                    }
                }
            }
            .onAppear {
                self.title = banner.title
                self.subTitle = banner.subTitle
                self.features = banner.features
            }
            .onChange(of: banner, {
                self.title = banner.title
                self.subTitle = banner.subTitle
                self.features = banner.features
            })
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
