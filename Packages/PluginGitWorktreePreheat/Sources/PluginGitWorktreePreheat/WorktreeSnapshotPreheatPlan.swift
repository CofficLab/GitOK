import Foundation
import ProviderProjects

/// 预热队列的排序规则与去重逻辑。
///
/// 这个纯值层不接触 Git 或 UI，确保队列策略可以独立测试，也让协调器只
/// 负责生命周期和任务调度。
enum WorktreeSnapshotPreheatPlan {
    static func orderedURLs(
        projects: [Project],
        preferredURL: URL?
    ) -> [URL] {
        let preferredKey = preferredURL?.standardizedFileURL.path
        var seen: Set<String> = []
        var result: [URL] = []

        for project in projects {
            let url = project.url.standardizedFileURL
            let key = url.path
            guard seen.insert(key).inserted else { continue }
            result.append(url)
        }

        guard let preferredKey,
              let preferredIndex = result.firstIndex(where: { $0.path == preferredKey }) else {
            return result
        }

        let preferred = result.remove(at: preferredIndex)
        result.insert(preferred, at: 0)
        return result
    }
}
