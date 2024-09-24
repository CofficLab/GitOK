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

#Preview {
    AppPreview()
        .frame(width: 800)
}
