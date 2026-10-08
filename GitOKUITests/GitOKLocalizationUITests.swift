import Foundation
import XCTest

struct GitOKLocalizationExpectation {
    let addProject: String
    let cloneRepository: String
    let clone: String
    let cloneHeading: String
    let cloneDescription: String
    let remoteURL: String
    let destination: String
    let chooseDestination: String
    let repositoryName: String
    let untracked: String
    let search: String
    let newBranchName: String
    let createBranch: String
    let openSettings: String
    let general: String
    let cancel: String
}

class GitOKLocalizationUITestCase: GitOKUITestCase {
    var expectedLocalization: GitOKLocalizationExpectation { fatalError("Override per language") }

    private func staticText(matching text: String) -> XCUIElement {
        app.staticTexts.matching(
            NSPredicate(format: "label == %@ OR value == %@", text, text)
        ).firstMatch
    }

    func assertKeySurfacesUseExpectedLocalization() {
        let expected = expectedLocalization

        let addProject = element(identifier: "gitok.projects.add")
        XCTAssertTrue(addProject.waitForExistence(timeout: 10))
        XCTAssertEqual(addProject.label, expected.addProject)

        let cloneRepository = app.buttons.matching(identifier: "gitok.projects.clone").firstMatch
        XCTAssertEqual(cloneRepository.label, expected.cloneRepository)
        cloneRepository.click()

        for text in [expected.cloneHeading, expected.cloneDescription, expected.remoteURL, expected.destination] {
            XCTAssertTrue(staticText(matching: text).waitForExistence(timeout: 5), "Missing localized clone-form text: \(text)")
        }
        let destinationPicker = element(identifier: "gitok.clone.destination.choose")
        XCTAssertEqual(destinationPicker.label, expected.chooseDestination)
        let repositoryName = element(identifier: "gitok.clone.repository-name")
        XCTAssertEqual(repositoryName.placeholderValue, expected.repositoryName)
        let clone = app.buttons.matching(NSPredicate(format: "label == %@", expected.clone)).firstMatch
        XCTAssertTrue(clone.waitForExistence(timeout: 5))
        XCTAssertFalse(clone.isEnabled, "Clone should remain disabled until required values are valid")
        app.buttons[expectedLocalization.cancel].click()

        let untracked = element(identifier: "gitok.worktree.status.untracked.txt")
        XCTAssertTrue(untracked.waitForExistence(timeout: 10))
        XCTAssertEqual(untracked.value as? String, expected.untracked)

        element(identifier: "gitok.git.branch.switcher").click()
        let branchSearch = element(identifier: "gitok.git.branch.search")
        XCTAssertTrue(branchSearch.waitForExistence(timeout: 5))
        XCTAssertEqual(branchSearch.placeholderValue, expected.search)
        element(identifier: "gitok.git.branch.create.toggle").click()
        let newBranchName = element(identifier: "gitok.git.branch.new-name")
        XCTAssertTrue(newBranchName.waitForExistence(timeout: 5))
        XCTAssertEqual(newBranchName.placeholderValue, expected.newBranchName)
        let createBranch = element(identifier: "gitok.git.branch.create")
        XCTAssertEqual(createBranch.label, expected.createBranch)

        _ = openSettings()
        let settingsButton = app.buttons.matching(identifier: "gitok.settings.button").firstMatch
        XCTAssertEqual(settingsButton.label, expected.openSettings)
        // 侧边栏条目不带 accessibility identifier，按本地化标题定位。
        let general = app.buttons.matching(
            NSPredicate(format: "label == %@ OR value == %@", expected.general, expected.general)
        ).firstMatch
        XCTAssertTrue(
            general.waitForExistence(timeout: 5),
            "General settings section was not localized: label=\(general.label), value=\(general.value ?? "nil")"
        )
    }
}

final class GitOKEnglishLocalizationUITests: GitOKLocalizationUITestCase {
    override var uiTestLanguage: String { "en" }
    override var uiTestLocale: String { "en_US" }
    override var expectedLocalization: GitOKLocalizationExpectation {
        GitOKLocalizationExpectation(
            addProject: "Add Project",
            cloneRepository: "Clone Repository",
            clone: "Clone",
            cloneHeading: "Clone Repository",
            cloneDescription: "Clone a remote repository and add it to your projects.",
            remoteURL: "Remote URL",
            destination: "Destination",
            chooseDestination: "Choose...",
            repositoryName: "Repository name",
            untracked: "Untracked",
            search: "Search",
            newBranchName: "New branch name",
            createBranch: "Create",
            openSettings: "Open Settings",
            general: "General",
            cancel: "Cancel"
        )
    }

    func testEnglishLocaleShowsEnglishAcrossMainGitCloneAndSettings() {
        assertKeySurfacesUseExpectedLocalization()
    }
}

final class GitOKChineseLocalizationUITests: GitOKLocalizationUITestCase {
    override var uiTestLanguage: String { "zh-Hans" }
    override var uiTestLocale: String { "zh_CN" }
    override var expectedLocalization: GitOKLocalizationExpectation {
        GitOKLocalizationExpectation(
            addProject: "添加项目",
            cloneRepository: "克隆仓库",
            clone: "克隆",
            cloneHeading: "克隆仓库",
            cloneDescription: "克隆远程仓库并将其添加到项目中。",
            remoteURL: "远程 URL",
            destination: "目标位置",
            chooseDestination: "选择…",
            repositoryName: "仓库名称",
            untracked: "未跟踪",
            search: "搜索",
            newBranchName: "新分支名称",
            createBranch: "创建",
            openSettings: "打开设置",
            general: "通用",
            cancel: "取消"
        )
    }

    func testChineseLocaleShowsChineseAcrossMainGitCloneAndSettings() {
        assertKeySurfacesUseExpectedLocalization()
    }
}
import Foundation
import XCTest
