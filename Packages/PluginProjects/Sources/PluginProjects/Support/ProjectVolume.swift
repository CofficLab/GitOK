import Foundation

/// 项目所在卷的归类结果。
///
/// `externalVolume` 覆盖外接硬盘、U 盘、外置 SSD、磁盘映像和网络卷；
/// `unavailable` 表示卷属性无法读取（设备被拔掉、挂载点消失等）。
enum ProjectVolumeStatus: Equatable, Sendable {
    case internalVolume
    case externalVolume
    case unavailable
}

/// 侧边栏需要展示的卷标识。
enum ProjectVolumeBadge: Equatable, Sendable {
    /// 本机启动盘上的项目，或尚未完成判定。
    case none
    case external
    case unavailable
}

/// 从 `URLResourceValues` 中提取出的卷属性（只保留判定所需字段）。
struct ProjectVolumeAttributes: Equatable, Sendable {
    var isInternal: Bool?
    var isEjectable: Bool?
    var isRemovable: Bool?
    var isLocal: Bool?
}

/// 纯函数分类器：把卷属性映射为卷类型，便于独立单测。
enum ProjectVolumeClassifier {
    static func classify(_ attributes: ProjectVolumeAttributes) -> ProjectVolumeStatus {
        // 任一「非启动盘」信号成立即视为外接卷：
        // - volumeIsInternal == false：非内置卷
        // - volumeIsEjectable / volumeIsRemovable：可弹出或可移除
        // - volumeIsLocal == false：网络等远程卷
        if attributes.isInternal == false
            || attributes.isEjectable == true
            || attributes.isRemovable == true
            || attributes.isLocal == false {
            return .externalVolume
        }
        return .internalVolume
    }
}

/// 卷类型判定能力（可注入测试替身）。
protocol ProjectVolumeResolving: Sendable {
    /// 通过项目路径解析其所在卷的类型。
    func status(forProjectURL url: URL) async -> ProjectVolumeStatus
}

/// 基于 `URLResourceValues` 的真实实现。
///
/// 不使用路径前缀猜测卷类型：从项目路径读取卷属性，读取失败即视为不可访问。
struct FileSystemProjectVolumeResolver: ProjectVolumeResolving {
    func status(forProjectURL url: URL) async -> ProjectVolumeStatus {
        guard let attributes = Self.attributes(for: url) else {
            return .unavailable
        }
        return ProjectVolumeClassifier.classify(attributes)
    }

    static func attributes(for url: URL) -> ProjectVolumeAttributes? {
        let keys: Set<URLResourceKey> = [
            .volumeIsInternalKey,
            .volumeIsEjectableKey,
            .volumeIsRemovableKey,
            .volumeIsLocalKey,
        ]

        do {
            let values = try url.resourceValues(forKeys: keys)
            return ProjectVolumeAttributes(
                isInternal: values.volumeIsInternal,
                isEjectable: values.volumeIsEjectable,
                isRemovable: values.volumeIsRemovable,
                isLocal: values.volumeIsLocal
            )
        } catch {
            // 路径不存在、卷已卸载或无法读取卷属性。
            return nil
        }
    }
}
