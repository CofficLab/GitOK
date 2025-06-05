import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicCore

class GitProvider: NSObject, ObservableObject, SuperLog {
    @Published private(set) var branches: [Branch] = []
    @Published var branch: Branch? = nil
    @Published var project: Project? = nil
    @Published private(set) var commit: GitCommit? = nil
    @Published private(set) var file: File? = nil
    @Published var projects: [Project] = []
    
    var emoji = "🏠"
    
    init(projects: [Project]) {
        self.projects = projects
        
        self.project = projects.first(where: {
            $0.path == AppConfig.projectPath
        })
        
        super.init()
        
        Task {
            self.refreshBranches(reason: "GitProvider.Init")
        }
    }
    
    func setProject(_ p: Project?, reason: String) {
        let verbose = false

        if verbose {
            os_log("\(self.t)Set Project(\(reason))")
            os_log("  ➡️ \(p?.path ?? "")")
        }
        
        self.project = p
        AppConfig.setProjectPath(p?.path ?? "")
    }
    
//        .onReceive(NotificationCenter.default.publisher(for: .gitProjectDeleted)) { notification in
//            if let path = notification.userInfo?["path"] as? String {
//                if self.project?.path == path {
//                    self.project = projects.first
//                }
//            }
//        }
    
    
    var currentBranch: Branch? {
        guard let project = project else {
            return nil
        }
        
        do {
            return try GitShell.getCurrentBranch(project.path)
        } catch _ {
            return nil
        }
    }

    func setFile(_ f: File?) {
        file = f
    }

    func setCommit(_ c: GitCommit?) {
        guard commit?.id != c?.id else { return }
        commit = c
    }
    
    func setBranch(_ branch: Branch?) throws {
        let verbose = false

        if verbose {
            os_log("\(self.t)Set Branch to \(branch?.name ?? "-")")
        }
        
        guard let project = project, let branch = branch else {
            return
        }
        
        if branch.name == currentBranch?.name {
            return
        }
        
        try GitShell.setBranch(branch, project.path, verbose: true)
    }

    func commit(_ message: String) {
        guard let project = self.project else { return }
        
        do {
            try GitShell.commit(project.path, commit: message)
        } catch {
            // 错误处理...
        }
    }
    
    func pull() {
        guard let project = self.project else { return }
        
        do {
            try GitShell.pull(project.path)
        } catch {
            // 错误处理...
        }
    }
    
    /**
     * 移动项目并更新排序
     * @param source 源索引集合
     * @param destination 目标索引
     * @param repo 项目仓库实例
     */
    func moveProjects(from source: IndexSet, to destination: Int, using repo: any ProjectRepoProtocol) {
        let itemsToMove = source.map { self.projects[$0] }
        
        os_log("Moving items: \(itemsToMove.map { $0.title }) from \(source) to \(destination)")
    
        do {
            // 创建一个临时数组来重新排序
            var tempProjects = projects
            
            // 从原位置移除项目
            for index in source.sorted(by: >) {
                tempProjects.remove(at: index)
            }
            
            // 确保目标索引不会超出数组范围
            let safeDestination = min(destination, tempProjects.count)
            
            // 在目标位置插入项目
            for item in itemsToMove.reversed() {
                tempProjects.insert(item, at: safeDestination)
            }
            
            // 批量更新所有项目的order值
            for (index, project) in tempProjects.enumerated() {
                project.order = Int16(index)
            }
            
            // 通过repo保存更改
            try repo.save()
            
            // 更新本地projects数组
            self.projects = tempProjects
            
            os_log("Successfully moved items and updated projects array.")
            
        } catch {
            os_log("Failed to move items: \(error.localizedDescription)")
        }
    }
    
    /**
     * 刷新项目列表
     * @param repo 项目仓库实例
     */
    func refreshProjects(using repo: any ProjectRepoProtocol) {
        do {
            self.projects = try repo.findAll(sortedBy: .ascending)
            os_log("Projects refreshed successfully, count: \(self.projects.count)")
        } catch {
            os_log(.error, "Failed to refresh projects: \(error.localizedDescription)")
        }
    }
    
    func refreshBranches(reason: String) {
        let verbose = false

        guard let project = project else {
            return
        }

        if verbose {
            os_log("\(self.t)Refresh")
        }

        branches = (try? GitShell.getBranches(project.path)) ?? []
        branch = branches.first(where: {
            $0.name == self.currentBranch?.name
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
