import SwiftUI

struct DetailBanner: View {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var b: BannerProvider

    @State var banner: BannerModel?

    var body: some View {
        VSplitView {
            if let banner = Binding(self.$banner) {
                BannerHome(banner: banner)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            do {
                self.banner = try b.getBanner()
            } catch {
                m.setError(error)
            }
        }
        .onChange(of: b.bannerURL, {
            do {
                self.banner = try b.getBanner()
            } catch {
                m.setError(error)
            }
        })
        .onChange(of: self.banner, {
            guard let banner = self.banner else {
                return
            }
            
            do {
                try banner.saveToDisk()
            } catch {
                m.setError(error)
            }

            b.setBannerURL(URL(filePath: banner.path!))
        })
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
