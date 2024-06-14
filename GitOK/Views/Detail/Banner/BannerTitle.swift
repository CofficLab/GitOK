import SwiftUI

struct BannerTitle: View {
    @State var isEditingTitle = false
    
    @Binding var banner: BannerModel
    
    var body: some View {
        if isEditingTitle {
            GeometryReader { geo in
                TextField("e", text: $banner.title)
                    .font(.system(size: 200))
                    .padding(.horizontal)
                    .frame(width: geo.size.width)
                    .onSubmit {
                        self.isEditingTitle = false
                    }
            }
        } else {
            Text(banner.title)
                .font(.system(size: 200))
                .onTapGesture {
                    self.isEditingTitle = true
                }
        }
    }
}

#Preview("App") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
