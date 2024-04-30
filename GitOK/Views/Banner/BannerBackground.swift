import SwiftUI
import SwiftData

struct BannerBackground: View {
    @EnvironmentObject var app: AppManager
    @Environment(\.modelContext) var context: ModelContext
    
    @State var bannerId: String = ""
    
    var banner: BannerModel
    
    var body: some View {
        Backgrounds(current: $bannerId)
            .padding(.vertical, 10)
            .onChange(of: bannerId, {
                updateBanner(bannerId)
            })
    }
    
    func updateBanner(_ id: String) {
        print("set banner background -> \(id)")
        banner.backgroundId = id
    }
}

#Preview {
    AppPreview()
}
