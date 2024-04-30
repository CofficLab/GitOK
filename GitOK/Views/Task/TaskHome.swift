import SwiftData
import SwiftUI

struct TaskHome: View {
    @EnvironmentObject var app: AppManager
    @Environment(\.modelContext) var context: ModelContext

    var task: TaskModel? { app.currentTask }
    
    @State var banner: BannerModel?
    @State var icon: IconModel?

    @Query var icons: [IconModel]
    @Query var banners: [BannerModel]
    
    var docs: [Doc] {
        icons.filter({
            $0.taskUUID == task?.uuid
        }).map({
            $0.toDoc()
        }) + banners.filter({
            $0.taskUUID == task?.uuid
        }).map({
            $0.toDoc()
        })
    }

    var body: some View {
        ZStack {
            if let task = task {
                VStack(alignment: .leading) {
                    GroupBox {
                        HStack {
                            BtnAddIcon(task: task)
                                .labelStyle(.iconOnly)

                            BtnAddBanner(task: task)
                                .labelStyle(.iconOnly)

                            DocTabs(docs: docs)
                                .padding(.horizontal)

                            Spacer()
                            BtnDelDoc()
                                .labelStyle(.iconOnly)
                        }
                        .frame(height: 15)
                    }

                    if banner != nil {
                        BannerHome(banner: $banner)
                    }

                    if icon != nil {
                        IconHome(icon: $icon)
                    }
                    
                    if icon == nil && banner == nil {
                        Spacer()
                    }
                }
                .onChange(of: app.doc?.uuid) {
                    self.banner = banners.first(where: {
                        $0.uuid == app.doc?.uuid
                    })

                    self.icon = icons.first(where: {
                        $0.uuid == app.doc?.uuid
                    })
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Message()
                }.padding(.trailing, 20)
                Spacer()
            }.padding(.top, 20)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 400)
}
