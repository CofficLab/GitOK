import SwiftUI

struct IconTile: View {
    @State var icon: IconModel
    @State var isPresented: Bool = false
    var selected: IconModel

    var body: some View {
        Text(icon.title)
            .navigationDestination(isPresented: $isPresented, destination: {
                IconHome(icon: $icon)
            })
            .onChange(of: selected) {
                ifPresented()
            }
            .onAppear(perform: ifPresented)
    }
    
    func ifPresented() {
        self.isPresented = icon.id == selected.id
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
