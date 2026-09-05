import SwiftUI
import XCTest
@testable import KitGitOKSupport

final class MagicBackgroundGroupCoverageTests: XCTestCase {

    func testAllGradientsBuildViews() {
        for gradient in MagicBackgroundGroup.all {
            // body 触发 gradientView：blue2white_center 走径向分支，其余走线性分支。
            _ = MagicBackgroundGroup(for: gradient).body
        }
    }

    func testStringInitMapsGradient() {
        _ = MagicBackgroundGroup(for: "blue2cyan").body
        _ = MagicBackgroundGroup(for: "2").body
        _ = MagicBackgroundGroup(for: "unknown-name").body
    }

    func testDisplayNameFormatting() {
        XCTAssertEqual(MagicBackgroundGroup.GradientName.blue2white_center.displayName, "blue → white center")
        XCTAssertEqual(MagicBackgroundGroup.GradientName.amber2orange_t2b.displayName, "amber → orange t → b")
        XCTAssertEqual(MagicBackgroundGroup.GradientName.aquamarine2teal_l2r.displayName, "aquamarine → teal l → r")
    }

    func testValidRawValueMapsToGradient() {
        XCTAssertEqual(MagicBackgroundGroup.gradientName(for: "blue2cyan"), .blue2cyan)
        XCTAssertEqual(MagicBackgroundGroup.gradientName(for: "red2orange_tl2br"), .red2orange_tl2br)
    }

    func testAllCasesPresentInCatalog() {
        XCTAssertEqual(MagicBackgroundGroup.all.count, MagicBackgroundGroup.GradientName.allCases.count)
        for name in MagicBackgroundGroup.GradientName.allCases {
            XCTAssertTrue(MagicBackgroundGroup.all.contains(name))
        }
    }
}

@MainActor
final class MagicBackgroundPickerCoverageTests: XCTestCase {

    func testPickerBuildsWithBinding() {
        var selection = "blue2cyan"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )
        _ = MagicBackgroundPicker(selection: binding).body
        // 绑定值未被视图构造过程改动。
        XCTAssertEqual(selection, "blue2cyan")
    }
}
