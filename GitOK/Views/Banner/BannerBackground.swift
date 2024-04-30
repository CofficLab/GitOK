import SwiftUI
import SwiftData

struct BannerBackground: View {
    @EnvironmentObject var app: AppManager
    @Environment(\.modelContext) var context: ModelContext
    
    @State var bannerId: String = ""
    
    var banner: BannerModel2
    
    var body: some View {
        Backgrounds(current: $bannerId)
            .padding(.vertical, 10)
            .onChange(of: bannerId, {
//                updateBanner(bannerId)
            })
    }
    
    mutating func updateBanner(_ id: String) {
        print("set banner background -> \(id)")
        banner.updateBackgroundId(id)
    }
}

#Preview {
    AppPreview()
}
