import SwiftUI

struct Feature: View {
    @State var isEditing = false
    
    @Binding var title: String

    var body: some View {
        ZStack {
            if isEditing {
                TextField("", text: $title)
                    .onSubmit {
                        self.isEditing = false
                    }
            } else {
                Text(title)
                    .onTapGesture {
                        self.isEditing = true
                    }
            }
        }
        .padding(40)
        .font(.system(size: 80))
        .background(BackgroundGroup.green2blue_tl2br)
        .cornerRadius(48)
    }
}

#Preview("APP") {
    AppPreview()
        .frame(height: 1200)
        .frame(width: 1200)
}
