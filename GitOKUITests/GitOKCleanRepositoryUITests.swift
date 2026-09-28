import Foundation
import XCTest

final class GitOKCleanRepositoryUITests: GitOKUITestCase {
    override var hasWorkingTreeChanges: Bool { false }

    func testCreatingBranchRefreshesRepositoryInfo() {
        let branchInfo = element(identifier: "gitok.repository.info.branch")
        XCTAssertTrue(branchInfo.waitForExistence(timeout: 15), "Repository branch information is missing")
        XCTAssertTrue((branchInfo.value as? String)?.contains("main") == true, "The fixture should initially report main")

        let switcher = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 10))
        XCTAssertTrue(waitUntilEnabled(switcher), "The branch list did not finish loading")
        switcher.click()
        let createToggle = element(identifier: "gitok.git.branch.create.toggle")
        XCTAssertTrue(createToggle.waitForExistence(timeout: 5))
        createToggle.click()

        let name = "ui-info-\(UUID().uuidString.prefix(8))"
        let nameField = element(identifier: "gitok.git.branch.new-name")
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        replaceText(in: nameField, with: name)

        let create = element(identifier: "gitok.git.branch.create")
        XCTAssertTrue(waitUntilEnabled(create))
        create.click()

        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "value CONTAINS %@", name), on: branchInfo, timeout: 15),
            "Repository information kept showing the previous branch after checkout"
        )
    }
}
import Foundation
import XCTest
