import SwiftUI
import Testing
@testable import GitOKUI

struct AppSelectionTileTests {
    @Test
    @MainActor
    func selectedTileUsesConfiguredScale() {
        let tile = AppSelectionTile(isSelected: true, selectedScale: 1.1, action: {}) {
            Color.red
        }

        #expect(tile.resolvedScale == 1.1)
    }

    @Test
    @MainActor
    func unselectedTileDoesNotScale() {
        let tile = AppSelectionTile(isSelected: false, selectedScale: 1.1, action: {}) {
            Color.red
        }

        #expect(tile.resolvedScale == 1)
    }
}
