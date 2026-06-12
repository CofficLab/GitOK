import SwiftUI
import Testing
@testable import GitOKUI

struct AppStatusBarTileTests {
    @Test
    @MainActor
    func usesStatusBarMetrics() {
        let tile = AppStatusBarTile(systemImage: "gearshape") {
            EmptyView()
        }

        #expect(tile.height == 24)
        #expect(tile.horizontalPadding == 8)
        #expect(tile.cornerRadius == 4)
    }
}
