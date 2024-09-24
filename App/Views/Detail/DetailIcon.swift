import SwiftUI

struct DetailIcon: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var i: IconProvider
    
    @State var icon: IconModel = .empty

    var body: some View {
        VStack {
            IconHome(icon: self.$icon)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            self.icon = i.icon
        }
        .onChange(of: i.icon, {
            self.icon = i.icon
        })
        .onChange(of: self.icon, {
            self.icon.save()
        })
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
