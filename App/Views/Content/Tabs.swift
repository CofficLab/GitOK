import SwiftUI

struct Tabs: View {
    @Binding var tab: ActionTab

    var body: some View {
        VStack(spacing: 0) {
//            HStack(spacing: 0) {
//                ForEach(ActionTab.allCases, id: \.self) { t in
//                    TabBtn(
//                        title: t.rawValue,
//                        imageName: t.imageName,
//                        selected: tab == t,
//                        onTap: {
//                            self.tab = t
//                        }
//                    )
//                }
//            }
//            .frame(height: 25)
//            .labelStyle(.iconOnly)

            ZStack {
                if self.tab == .Git {
                    CommitList()
                } else if self.tab == .Banner {
                    BannerList()
                } else if self.tab == .Icon {
                    IconList()
                } else {
                    Spacer()
                }
            }.frame(maxHeight: .infinity)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
