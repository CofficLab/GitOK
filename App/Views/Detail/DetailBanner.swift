import SwiftUI

struct DetailBanner: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var b: BannerProvider

    @State var banner: BannerModel = .empty

    var body: some View {
        VSplitView {
            BannerHome(banner: self.$banner)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            do {
                self.banner = try b.getBanner()
            } catch {
                app.setError(error)
            }
        }
        .onChange(of: b.bannerURL, {
            do {
                self.banner = try b.getBanner()
            } catch {
                app.setError(error)
            }
        })
        .onChange(of: self.banner, {
            do {
                try self.banner.saveToDisk()
            } catch {
                self.app.setError(error)
            }

            b.setBannerURL(URL(filePath: self.banner.path!))
        })
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
