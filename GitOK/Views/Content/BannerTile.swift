import SwiftUI

struct BannerTile: View {
    @State var banner: BannerModel
    @State var isPresented: Bool = false
    var selected: BannerModel

    var body: some View {
        Text(banner.title)
            .navigationDestination(isPresented: $isPresented, destination: {
                BannerHome(banner: $banner)
            })
            .onChange(of: selected) {
                ifPresented()
            }
            .onAppear(perform: ifPresented)
    }
    
    func ifPresented() {
        self.isPresented = banner.id == selected.id
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
