import Foundation
import Combine
import SwiftUI
import Testing
@testable import ProviderRailView

@Suite("ProviderRailView sections")
@MainActor
struct ProviderRailViewSectionsTests {

    @Test("registerSections stores sorted sections")
    func registerSections() {
        let provider = DefaultRailViewProviding()
        let sections = [
            RailSectionItem(id: "b", order: 200) { Text("b") },
            RailSectionItem(id: "a", order: 100) { Text("a") },
        ]
        provider.registerSections(sections)
        #expect(provider.sections.map(\.id) == ["a", "b"])
        #expect(provider.hasVisibleSections)
    }

    @Test("addSections merges without duplicates")
    func addSectionsMerges() {
        let provider = DefaultRailViewProviding()
        provider.registerSections([RailSectionItem(id: "a", order: 100) { Text("a") }])
        provider.addSections([
            RailSectionItem(id: "a", order: 100) { Text("a2") },
            RailSectionItem(id: "b", order: 200) { Text("b") },
        ])
        #expect(provider.sections.map(\.id) == ["a", "b"])
    }

    @Test("removeSections filters by ids")
    func removeSections() {
        let provider = DefaultRailViewProviding()
        provider.registerSections([
            RailSectionItem(id: "a", order: 100) { Text("a") },
            RailSectionItem(id: "b", order: 200) { Text("b") },
        ])
        provider.removeSections(ids: ["a"])
        #expect(provider.sections.map(\.id) == ["b"])
    }

    @Test("setVisibleTabID filters to a single tab")
    func setVisibleTabID() {
        let provider = DefaultRailViewProviding()
        provider.registerTabs([
            RailTabItem(id: "a", category: .general, title: "A", systemImage: "a") { Text("A") },
            RailTabItem(id: "b", category: .general, title: "B", systemImage: "b") { Text("B") },
        ])
        provider.setVisibleTabID("b")
        #expect(provider.visibleTabID == "b")
    }
}
