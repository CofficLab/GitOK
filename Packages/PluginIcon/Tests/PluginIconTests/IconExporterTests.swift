import AppKit
import Foundation
import Testing
@testable import PluginIcon

@Suite("IconExporter")
struct IconExporterTests {
    @Test("default AppIcon slots include the universal 1024px source")
    func defaultSlotsContainSourceSize() {
        #expect(IconExporter.defaultSlots.contains { $0.pixelSize == 1024 })
        #expect(IconExporter.defaultSlots.last?.filename == "icon-1024.png")
    }
}
