import SwiftUI

struct BannerSubTitle: View {
    @State var isEditing = false
    
    @Binding var banner: BannerModel
    
    var body: some View {
        if isEditing {
            GeometryReader { geo in
                TextField("副标题", text: $banner.subTitle)
                    .font(.system(size: 100))
                    .padding(.horizontal)
                    .frame(width: geo.size.width)
                    .onSubmit {
                        self.isEditing = false
                    }
            }
        } else {
            Text(banner.subTitle.isEmpty ? "副标题" : banner.subTitle)
                .font(.system(size: 100))
                .onTapGesture {
                    self.isEditing = true
                }
        }
    }
}

#Preview("App") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
