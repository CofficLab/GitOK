import SwiftUI

struct Tabs: View {
    @Binding var tab: ActionTab
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(ActionTab.allCases, id: \.self) { t in
                    GroupBox {
                        HStack {
                            Image(systemName: t.imageName)
                            Text(t.rawValue)
                        }
                        .foregroundStyle(tab == t ? .primary : .secondary)
                        .onTapGesture { self.tab = t }
                    }
                }
            }.padding(.vertical, 2)
            
            if self.tab == .Git {
                History()
            } else if self.tab == .Banner {
                BannerList()
            } else if self.tab == .Icon {
                IconList()
            } else {
                Spacer()
            }
        }
    }
}

#Preview {
    AppPreview()
}
