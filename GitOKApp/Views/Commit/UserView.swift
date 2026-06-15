import GitOKAppCore
import GitOKSupportKit
import OSLog
import GitWorkspacePlugin
import SwiftUI

/// 用户信息显示视图
struct UserView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 配置仓库
    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
    }

    var body: some View {
        CommitUserConfigHostView(
            project: vm.project,
            configID: { String(describing: $0.persistentModelID) },
            configName: \.name,
            configEmail: \.email,
            loadProjectUserName: { try await $0.getUserNameAsync() },
            loadProjectUserEmail: { try await $0.getUserEmailAsync() },
            loadRecentConfigs: { try configRepo.getRecentConfigs(limit: $0) },
            applyProjectConfig: { project, identity in
                try await project.setUserConfigAsync(
                    name: identity.name,
                    email: identity.email
                )
            },
            logEvent: logEvent(_:)
        ) {
            SettingView()
                .environmentObject(data)
        }
    }
}

private extension UserView {
    func logEvent(_ event: CommitUserConfigHostLogEvent) {
        guard Self.verbose else {
            return
        }

        switch event {
        case .configLoadSuccess(let count):
            os_log("\(Self.t)\(CommitUserConfigRules.savedConfigsLoadedLogMessage(count: count))")
        case .configLoadFailure(let error):
            os_log(.error, "\(Self.t)\(CommitUserConfigRules.savedConfigsLoadFailureLogMessage(errorDescription: error.localizedDescription))")
        case .applySuccess(let name, let email):
            os_log("\(Self.t)\(CommitUserConfigRules.appliedConfigLogMessage(name: name, email: email))")
        case .applyFailure(let error):
            os_log(.error, "\(Self.t)\(CommitUserConfigRules.applyConfigFailureLogMessage(errorDescription: error.localizedDescription))")
        }
    }
}
