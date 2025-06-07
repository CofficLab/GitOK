import SwiftUI

struct CommitCategoryPicker: View {
    @EnvironmentObject var app: AppProvider
    
    @State var branches: [String] = []
    @Binding var selection: CommitCategory
    
    var project: Project
    
    var body: some View {
        Picker("", selection: $selection, content: {
            ForEach(CommitCategory.allCases, id: \.self, content: {
                Text("\($0.emoji) \($0.title)")
                    .tag($0 as CommitCategory?)
            })
        })
        .frame(width: 135)
        .pickerStyle(.automatic)
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
