import SwiftData
import SwiftUI

struct IconList2: View {
    @EnvironmentObject var app: AppManager

    @State var icon: IconModel2?
    @State var icons: [IconModel2] = []

    var body: some View {
        VStack {
            List(icons, id: \.self, selection: $icon) { icon in
                Text(icon.title)
            }
            
            Spacer()
            
            // 操作
            HStack {
                BtnAddIcon2(callback: {
                    self.icons.append($0)
                })
            }
        }
        .onChange(of: icon) {
            app.icon = icon
        }
        .onAppear {
            if let project = app.project {
                self.icons = IconModel2.fromProject(project.path)
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
