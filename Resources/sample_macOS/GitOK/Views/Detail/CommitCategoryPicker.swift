import SwiftUI

struct CommitCategoryPicker: View {
    @EnvironmentObject var app: AppManager
    
    @State var branches: [String] = []
    @Binding var selection: CommitCategory
    
    var project: Project
    
    var body: some View {
        Picker("", selection: $selection, content: {
            ForEach(CommitCategory.allCases, id: \.self, content: {
                Text("\($0.text) \($0.rawValue)")
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
