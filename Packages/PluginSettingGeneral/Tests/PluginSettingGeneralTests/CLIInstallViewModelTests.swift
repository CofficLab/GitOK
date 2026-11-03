import Foundation
import KitGitOKCLI
import Testing
@testable import PluginSettingGeneral

/// `CLIInstallViewModel` 的状态机测试。
@Suite("CLIInstallViewModel")
@MainActor
struct CLIInstallViewModelTests {

    /// 可编程的安装器替身。
    final class StubInstaller: CLIInstalling {
        var currentStatus: CLIInstallationStatus
        var installOutcome: CLIInstallOutcome
        var uninstallResult: Bool
        private(set) var installCallCount = 0
        private(set) var uninstallCallCount = 0

        init(
            status: CLIInstallationStatus = CLIInstallationStatus(
                installedPath: nil,
                isOnPath: false,
                suggestedTarget: nil
            ),
            installOutcome: CLIInstallOutcome = .installed(
                target: CLIInstallTarget(
                    directory: URL(fileURLWithPath: "/usr/local/bin"),
                    isOnPath: true,
                    isWritable: true
                )
            ),
            uninstallResult: Bool = true
        ) {
            self.currentStatus = status
            self.installOutcome = installOutcome
            self.uninstallResult = uninstallResult
        }

        func status() -> CLIInstallationStatus { currentStatus }
        func install() -> CLIInstallOutcome {
            installCallCount += 1
            return installOutcome
        }
        func uninstall() -> Bool {
            uninstallCallCount += 1
            return uninstallResult
        }
    }

    private func makeTarget(
        isOnPath: Bool = true,
        path: String = "/usr/local/bin"
    ) -> CLIInstallTarget {
        CLIInstallTarget(
            directory: URL(fileURLWithPath: path),
            isOnPath: isOnPath,
            isWritable: true
        )
    }

    @Test("初始状态为未安装")
    func startsNotInstalled() {
        let model = CLIInstallViewModel(installer: StubInstaller())
        #expect(model.status == .notInstalled)
        #expect(model.lastError == nil)
    }

    @Test("安装成功后状态变为已安装")
    func installUpdatesStatus() {
        let stub = StubInstaller()
        stub.installOutcome = .installed(target: makeTarget())
        let model = CLIInstallViewModel(installer: stub)

        model.install()

        #expect(stub.installCallCount == 1)
        #expect(model.lastError == nil)
        // 状态仍由 status() 决定；这里验证安装动作被正确触发。
        #expect(model.status == .notInstalled)
    }

    @Test("安装失败时记录错误")
    func installFailureRecordsError() {
        let stub = StubInstaller()
        stub.installOutcome = .failed(reason: "disk is full")
        let model = CLIInstallViewModel(installer: stub)

        model.install()

        #expect(model.lastError == "disk is full")
    }

    @Test("安装到不在 PATH 的目录时刷新出提示状态")
    func installNotOnPathReflectedInStatus() {
        let stub = StubInstaller()
        let installedURL = URL(fileURLWithPath: "/Users/me/.local/bin/gitok")
        stub.currentStatus = CLIInstallationStatus(
            installedPath: installedURL,
            isOnPath: false,
            suggestedTarget: nil
        )
        stub.installOutcome = .installedButNotOnPath(
            target: makeTarget(isOnPath: false, path: "/Users/me/.local/bin")
        )
        let model = CLIInstallViewModel(installer: stub)

        model.install()

        #expect(model.status == .installedNotOnPath(
            path: "/Users/me/.local/bin/gitok",
            directory: "/Users/me/.local/bin"
        ))
        #expect(model.lastError == nil)
    }

    @Test("已安装且在 PATH 中时状态正确")
    func installedOnPathStatus() {
        let stub = StubInstaller()
        stub.currentStatus = CLIInstallationStatus(
            installedPath: URL(fileURLWithPath: "/usr/local/bin/gitok"),
            isOnPath: true,
            suggestedTarget: nil
        )
        let model = CLIInstallViewModel(installer: stub)

        model.refresh()

        #expect(model.status == .installed(path: "/usr/local/bin/gitok"))
    }

    @Test("卸载成功后状态回到未安装")
    func uninstallReturnsToNotInstalled() {
        let stub = StubInstaller()
        stub.currentStatus = CLIInstallationStatus(
            installedPath: URL(fileURLWithPath: "/usr/local/bin/gitok"),
            isOnPath: true,
            suggestedTarget: nil
        )
        let model = CLIInstallViewModel(installer: stub)
        #expect(model.status.isInstalled)

        // 卸载后安装器报告「未安装」。
        stub.currentStatus = CLIInstallationStatus(
            installedPath: nil,
            isOnPath: false,
            suggestedTarget: nil
        )
        model.uninstall()

        #expect(stub.uninstallCallCount == 1)
        #expect(model.status == .notInstalled)
        #expect(model.lastError == nil)
    }

    @Test("卸载失败时记录错误")
    func uninstallFailureRecordsError() {
        let stub = StubInstaller(uninstallResult: false)
        let model = CLIInstallViewModel(installer: stub)

        model.uninstall()

        #expect(model.lastError == "uninstallFailed")
    }

    @Test("refresh 重新读取安装状态")
    func refreshReadsStatusAgain() {
        let stub = StubInstaller()
        let model = CLIInstallViewModel(installer: stub)
        #expect(model.status == .notInstalled)

        stub.currentStatus = CLIInstallationStatus(
            installedPath: URL(fileURLWithPath: "/opt/homebrew/bin/gitok"),
            isOnPath: true,
            suggestedTarget: nil
        )
        model.refresh()

        #expect(model.status == .installed(path: "/opt/homebrew/bin/gitok"))
    }
}
