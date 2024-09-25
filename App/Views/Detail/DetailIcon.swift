import OSLog
import SwiftUI

struct DetailIcon: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var i: IconProvider

    @State var icon: IconModel = .empty

    var body: some View {
        VStack {
            IconHome(icon: self.$icon)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            do {
                self.icon = try i.getIcon()
            } catch {
                os_log(.error, "Error getting icon: \(error)")
                app.setError(error)
            }
        }
        .onChange(of: i.iconURL, {
            do {
                self.icon = try i.getIcon()
            } catch {
                os_log(.error, "Error getting icon: \(error)")
                app.setError(error)
            }
        })
        .onChange(of: self.icon, {
            do {
                try self.icon.saveToDisk()
            } catch {
                self.app.setError(error)
            }

            if let path = self.icon.path {
                i.setIconURL(URL(filePath: path))
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
