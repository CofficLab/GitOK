import Foundation
import MagicUI
import MagicKit
import SwiftUI

/**
 * MagicAsset 图标仓库
 * 读取 MagicKit 提供的内置 SwiftUI 图标（如书本、相机、音乐等），
 * 将其以只读方式暴露给 GitOK 的图标系统。
 */
class MagicAssetRepo: IconSourceProtocol, SuperLog {
    nonisolated static var emoji: String { "✨" }

    /// 单例
    static let shared = MagicAssetRepo()

    // 唯一标识与名称
    var sourceIdentifier: String { "magic_asset" }
    var sourceName: String { "MagicAsset 图标" }

    // 只读
    var supportsMutations: Bool { false }
    var supportsCategories: Bool { true }

    private init() {}

    // MARK: - IconSourceProtocol

    var isAvailable: Bool {
        get async { true }
    }

    /// MagicAsset 下的固定分类
    private enum Category: String, CaseIterable {
        case general
    }

    func getAllCategories(reason: String) async throws -> [IconCategory] {
        // 单一分类，聚合 MagicAsset 所有内置图标
        return [
            IconCategory(
                id: Category.general.rawValue,
                name: "MagicAsset",
                displayName: "MAGICASSET",
                iconCount: Self.allIconMakers.count,
                sourceIdentifier: self.sourceIdentifier,
                metadata: [:]
            ),
        ]
    }

    func getIcons(for categoryId: String) async -> [IconAsset] {
        guard categoryId == Category.general.rawValue else { return [] }
        return Self.allIconMakers.enumerated().map { idx, maker in
            IconAsset(viewBuilder: maker, id: String(idx))
        }
    }

    func getAllIcons() async -> [IconAsset] {
        return Self.allIconMakers.enumerated().map { idx, maker in IconAsset(viewBuilder: maker, id: String(idx)) }
    }

    func getIconAsset(byId iconId: String) async throws -> IconAsset? {
        // 以注册顺序的名称作为 id（与 IconAsset.viewId 一致）
        if let idx = Int(iconId), idx >= 0, idx < Self.allIconMakers.count {
            return IconAsset(viewBuilder: Self.allIconMakers[idx], id: String(idx))
        }
        return nil
    }

    func getCategory(byName name: String) async throws -> IconCategory? {
        if name.lowercased() == "magicasseT".lowercased() {
            let items = try await getAllCategories(reason: "get_category_by_name")
            return items.first
        }
        return nil
    }

    // MARK: - MagicAsset 视图工厂

    /// 将 MagicAsset 的各个内置图标以闭包形式注册为视图构造器
    private static let allIconMakers: [() -> AnyView] = {
        var makers: [() -> AnyView] = []

        // Book
        makers.append { AnyView(Image.makeBookIcon(useDefaultBackground: false)) }
        // Camera
        makers.append { AnyView(Image.makeCameraIcon(useDefaultBackground: false)) }
        // Coffee Reel
        makers.append { AnyView(Image.makeCoffeeReelIcon(useDefaultBackground: false)) }
        // Globe
        makers.append { AnyView(Image.makeGlobeIcon(useDefaultBackground: false)) }
        // Kids Edu
        makers.append { AnyView(Image.makeKidsEduIcon(useDefaultBackground: false)) }
        // Music
        makers.append { AnyView(Image.makeMusicIcon(useDefaultBackground: false)) }
        // Note
        makers.append { AnyView(Image.makeNoteIcon(useDefaultBackground: false)) }
        // Pencil
        makers.append { AnyView(Image.makePencilIcon(useDefaultBackground: false)) }
        // Video Player
        makers.append { AnyView(Image.makeVideoPlayerIcon(useDefaultBackground: false)) }

        return makers
    }()
}

// MARK: - 预览

#Preview("App - MagicAsset") {
    ScrollView {
        VStack {
            Image.makeBookIcon()
                .frame(height: 200)
                .frame(width: 200)
            Image.makeCameraIcon()
                .frame(height: 200)
                .frame(width: 200)
            Image.makeCoffeeReelIcon()
                .frame(height: 200)
                .frame(width: 200)
            Image.makeGlobeIcon()
                .frame(height: 200)
                .frame(width: 200)
            Image.makeKidsEduIcon()
                .frame(height: 200)
                .frame(width: 200)
            Image.makeMusicIcon()
                .frame(height: 200)
                .frame(width: 200)
            Image.makeNoteIcon()
                .frame(height: 200)
                .frame(width: 200)
        }
        .frame(width: 800)
    }
    .frame(height: 800)
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 700)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
