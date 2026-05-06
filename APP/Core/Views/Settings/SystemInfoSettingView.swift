import Foundation
import MagicKit
import OSLog
import SwiftUI

/// 系统信息设置视图
struct SystemInfoSettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "💻"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @State private var systemInfo = SystemInfo()

    /// 刷新状态
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 系统基本信息
                systemBasicInfoSection

                // 硬件信息
                hardwareInfoSection

                // 内存信息
                memoryInfoSection

                // 磁盘信息
                diskInfoSection

                // Git 信息
                gitInfoSection
            }
            .padding()
        }
        .navigationTitle(Text("系统信息", tableName: "Core"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }) {
                    Text("完成", tableName: "Core")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    refreshSystemInfo()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isRefreshing)
            }
        }
        .onAppear {
            refreshSystemInfo()
        }
    }

    // MARK: - View Components

    /// 系统基本信息
    private var systemBasicInfoSection: some View {
        MagicSettingSection(title: String(localized: "系统", table: "Core"), titleAlignment: .leading) {
            VStack(spacing: 0) {
                // 系统名称
                MagicSettingRow(
                    title: String(localized: "系统名称", table: "Core"),
                    description: systemInfo.systemName,
                    icon: .iconGear
                ) {
                    EmptyView()
                }

                Divider()
                    .padding(.leading, 16)

                // 系统版本
                MagicSettingRow(
                    title: String(localized: "系统版本", table: "Core"),
                    description: systemInfo.systemVersion,
                    icon: .iconGear
                ) {
                    EmptyView()
                }

                Divider()
                    .padding(.leading, 16)

                // 系统架构
                MagicSettingRow(
                    title: String(localized: "系统架构", table: "Core"),
                    description: systemInfo.architecture,
                    icon: .iconGear
                ) {
                    EmptyView()
                }

                Divider()
                    .padding(.leading, 16)

                // 主机名
                MagicSettingRow(
                    title: String(localized: "主机名", table: "Core"),
                    description: systemInfo.hostname,
                    icon: .iconGear
                ) {
                    EmptyView()
                }
            }
        }
    }

    /// 硬件信息
    private var hardwareInfoSection: some View {
        MagicSettingSection(title: String(localized: "硬件", table: "Core"), titleAlignment: .leading) {
            VStack(spacing: 0) {
                // 处理器
                MagicSettingRow(
                    title: String(localized: "处理器", table: "Core"),
                    description: systemInfo.cpuModel,
                    icon: .iconGear
                ) {
                    EmptyView()
                }

                Divider()
                    .padding(.leading, 16)

                // 核心数
                MagicSettingRow(
                    title: String(localized: "核心数", table: "Core"),
                    description: String.localizedStringWithFormat(String(localized: "%lld 核", table: "Core"), Int64(systemInfo.cpuCores)),
                    icon: .iconGear
                ) {
                    EmptyView()
                }
            }
        }
    }

    /// 内存信息
    private var memoryInfoSection: some View {
        MagicSettingSection(title: String(localized: "内存", table: "Core"), titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 16) {
                // 内存使用条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("内存使用", tableName: "Core")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(systemInfo.memoryUsagePercent)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: Double(systemInfo.memoryUsagePercent) / 100.0)
                        .progressViewStyle(.linear)
                }
                .padding(.horizontal)

                // 内存详情
                VStack(spacing: 0) {
                    MagicSettingRow(
                        title: String(localized: "总内存", table: "Core"),
                        description: systemInfo.totalMemory,
                        icon: .iconGear
                    ) {
                        EmptyView()
                    }

                    Divider()
                        .padding(.leading, 16)

                    MagicSettingRow(
                        title: String(localized: "可用内存", table: "Core"),
                        description: systemInfo.freeMemory,
                        icon: .iconGear
                    ) {
                        EmptyView()
                    }

                    Divider()
                        .padding(.leading, 16)

                    MagicSettingRow(
                        title: String(localized: "已用内存", table: "Core"),
                        description: systemInfo.usedMemory,
                        icon: .iconGear
                    ) {
                        EmptyView()
                    }
                }
            }
        }
    }

    /// 磁盘信息
    private var diskInfoSection: some View {
        MagicSettingSection(title: String(localized: "磁盘", table: "Core"), titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 16) {
                // 磁盘使用条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("磁盘使用", tableName: "Core")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(systemInfo.diskUsagePercent)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: Double(systemInfo.diskUsagePercent) / 100.0)
                        .progressViewStyle(.linear)
                }
                .padding(.horizontal)

                // 磁盘详情
                VStack(spacing: 0) {
                    MagicSettingRow(
                        title: String(localized: "总容量", table: "Core"),
                        description: systemInfo.totalDiskSpace,
                        icon: .iconGear
                    ) {
                        EmptyView()
                    }

                    Divider()
                        .padding(.leading, 16)

                    MagicSettingRow(
                        title: String(localized: "可用容量", table: "Core"),
                        description: systemInfo.freeDiskSpace,
                        icon: .iconGear
                    ) {
                        EmptyView()
                    }

                    Divider()
                        .padding(.leading, 16)

                    MagicSettingRow(
                        title: String(localized: "已用容量", table: "Core"),
                        description: systemInfo.usedDiskSpace,
                        icon: .iconGear
                    ) {
                        EmptyView()
                    }
                }
            }
        }
    }

    /// Git 信息
    private var gitInfoSection: some View {
        MagicSettingSection(title: String(localized: "Git", table: "Core"), titleAlignment: .leading) {
            VStack(spacing: 0) {
                if let gitVersion = systemInfo.gitVersion {
                    MagicSettingRow(
                        title: String(localized: "Git 版本", table: "Core"),
                        description: gitVersion,
                        icon: .iconGear
                    ) {
                        EmptyView()
                    }
                } else {
                    MagicSettingRow(
                        title: String(localized: "Git 版本", table: "Core"),
                        description: String(localized: "未安装", table: "Core"),
                        icon: .iconGear
                    ) {
                        EmptyView()
                    }
                }
            }
        }
    }

    /// 信息行
    private func infoRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))

                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func refreshSystemInfo() {
        isRefreshing = true

        // 模拟刷新延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            systemInfo = SystemInfo()
            isRefreshing = false

            if Self.verbose {
                os_log("\(Self.t)🔄 Refreshed system info")
            }
        }
    }
}

// MARK: - Preview

#Preview("System Info") {
    SystemInfoSettingView()
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
