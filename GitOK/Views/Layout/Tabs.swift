import SwiftUI

struct Tabs: View {
    @Binding var tab: ActionTab

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ActionTab.allCases, id: \.self) { t in
                    TabBtn(
                        tab: t,
                        selected: tab == t,
                        onTap: {
                            self.tab = t
                        }
                    )
                }
            }
            .frame(height: 30)
            .labelStyle(.iconOnly)

            ZStack {
                if self.tab == .Git {
                    History()
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
}
