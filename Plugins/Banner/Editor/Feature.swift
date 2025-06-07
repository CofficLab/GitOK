import SwiftUI
import MagicCore

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
//        .background(BackgroundGroup(for: .green2blue_tl2br))
        .cornerRadius(48)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
