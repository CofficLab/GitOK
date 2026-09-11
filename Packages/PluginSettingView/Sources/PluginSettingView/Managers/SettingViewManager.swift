import Foundation
import os
import ProviderSettingView
import KitSuperLog
import SwiftUI

/// `SettingViewProviding` 的自研实现：持有设置入口项和选中状态。
///
/// 参照 `SettingsManager`（KernelLumi 体系）设计，迁移至 KernelCore 生态：
/// - 插件通过 `addEntries(_:)` 追加自己的设置入口（同 id 去重）；
/// - 消费方订阅 `objectWillChange` 即可感知入口集合变化；
/// - 内置结构化日志，便于诊断注册 / 注销 / 选中切换。
///
/// 持久化：当注入 `storageDirectory` 时，`selectedEntryID` 会写入
/// `<directory>/setting-selection.json`，下次启动时自动恢复。
/// 读写失败时静默回退，不影响设置功能。
@MainActor
public final class SettingViewManager: SettingViewProviding, ObservableObject, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.setting-view", category: "Plugin")
    public nonisolated static let emoji = "⚙️"
    nonisolated static let verbose = false

    /// 持久化文件名。
    private static let selectionFileName = "setting-selection.json"

    @Published public private(set) var entries: [SettingEntryItem] = []
    @Published public private(set) var projectDetailSections: [ProjectDetailSectionItem] = []
    @Published public private(set) var selectedEntryID: String?

    /// 插件数据目录（由 `StorageProviding.pluginDataDirectory(for:)` 注入）。
    /// 为 nil 时不做持久化。
    private let storageDirectory: URL?

    /// - Parameter storageDirectory: 插件数据目录；不传时不持久化选中状态。
    public init(storageDirectory: URL? = nil) {
        self.storageDirectory = storageDirectory
        restoreSelection()
    }

    public func registerEntries(_ entries: [SettingEntryItem]) {
        if Self.verbose {
            Self.logger.info("\(Self.t)registerEntries: \(entries.count, privacy: .public) 项")
        }
        self.entries = entries.sorted { $0.order < $1.order }
        if selectedEntryID == nil || !self.entries.contains(where: { $0.id == selectedEntryID }) {
            selectedEntryID = self.entries.first?.id
        }
    }

    public func selectEntry(id: String?) {
        guard selectedEntryID != id else { return }
        if Self.verbose {
            Self.logger.info("\(Self.t)selectEntry: \(id ?? "nil", privacy: .public)")
        }
        selectedEntryID = id
        persistSelection()
    }

    public func addProjectDetailSections(_ newSections: [ProjectDetailSectionItem]) {
        var merged = projectDetailSections
        for section in newSections where !merged.contains(where: { $0.id == section.id }) {
            merged.append(section)
        }
        projectDetailSections = merged.sorted { $0.order < $1.order }
    }

    public func removeProjectDetailSections(ids: Set<String>) {
        projectDetailSections.removeAll { ids.contains($0.id) }
    }

    public func makeSettingView() -> AnyView {
        AnyView(SettingView(provider: self))
    }

    // MARK: - Persistence

    /// 持久化的选中状态快照。
    private struct SelectionSnapshot: Codable {
        let selectedEntryID: String?
    }

    /// 从磁盘恢复上次选中的设置入口 ID。
    private func restoreSelection() {
        guard let storageDirectory else { return }
        let fileURL = storageDirectory.appendingPathComponent(Self.selectionFileName)
        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try JSONDecoder().decode(SelectionSnapshot.self, from: data)
            selectedEntryID = snapshot.selectedEntryID
            if Self.verbose {
                Self.logger.info("\(Self.t)restored selectedEntryID: \(snapshot.selectedEntryID ?? "nil", privacy: .public)")
            }
        } catch {
            // 文件不存在或解码失败 — 正常情况（首次启动 / 文件损坏），静默回退。
            if Self.verbose {
                Self.logger.debug("\(Self.t)restoreSelection skipped: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// 将当前选中的设置入口 ID 写入磁盘。
    private func persistSelection() {
        guard let storageDirectory else { return }
        let fileURL = storageDirectory.appendingPathComponent(Self.selectionFileName)
        let snapshot = SelectionSnapshot(selectedEntryID: selectedEntryID)
        do {
            try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
            if Self.verbose {
                Self.logger.debug("\(Self.t)persisted selectedEntryID: \(self.selectedEntryID ?? "nil", privacy: .public)")
            }
        } catch {
            // 持久化只是体验增强；写入失败不能阻塞设置功能。
            Self.logger.warning("\(Self.t)persistSelection failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
