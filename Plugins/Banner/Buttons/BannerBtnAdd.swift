import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct BannerBtnAdd: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MessageProvider

    var body: some View {
        if let project = g.project {
            TabBtn(title: "新建 Banner", imageName: "plus.circle", onTap: {
                b.appendBanner(BannerModel.new(project))
            })
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
