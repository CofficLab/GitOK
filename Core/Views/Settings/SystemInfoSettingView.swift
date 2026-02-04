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
        .navigationTitle("系统信息")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
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
        MagicSettingSection(title: "系统", titleAlignment: .leading) {
            VStack(spacing: 0) {
                infoRow(
                    title: "系统名称",
                    value: systemInfo.systemName,
                    icon: "desktopcomputer"
                )

                Divider()

                infoRow(
                    title: "系统版本",
                    value: systemInfo.systemVersion,
                    icon: "info.circle"
                )

                Divider()

                infoRow(
                    title: "系统架构",
                    value: systemInfo.architecture,
                    icon: "cpu"
                )

                Divider()

                infoRow(
                    title: "主机名",
                    value: systemInfo.hostname,
                    icon: "server.rack"
                )
            }
        }
    }

    /// 硬件信息
    private var hardwareInfoSection: some View {
        MagicSettingSection(title: "硬件", titleAlignment: .leading) {
            VStack(spacing: 0) {
                infoRow(
                    title: "处理器",
                    value: systemInfo.cpuModel,
                    icon: "cpu"
                )

                Divider()

                infoRow(
                    title: "核心数",
                    value: "\(systemInfo.cpuCores) 核",
                    icon: "number"
                )
            }
        }
    }

    /// 内存信息
    private var memoryInfoSection: some View {
        MagicSettingSection(title: "内存", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 16) {
                // 内存使用条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("内存使用")
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
                    infoRow(
                        title: "总内存",
                        value: String(format: "%.1f GB", systemInfo.memorySize),
                        icon: "memorychip"
                    )

                    Divider()

                    infoRow(
                        title: "可用内存",
                        value: String(format: "%.1f GB", systemInfo.memoryAvailable),
                        icon: "checkmark.circle"
                    )

                    Divider()

                    infoRow(
                        title: "已用内存",
                        value: String(format: "%.1f GB", systemInfo.memorySize - systemInfo.memoryAvailable),
                        icon: "arrow.up.circle"
                    )
                }
            }
        }
    }

    /// 磁盘信息
    private var diskInfoSection: some View {
        MagicSettingSection(title: "磁盘", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 16) {
                // 磁盘使用条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("磁盘使用")
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
                    infoRow(
                        title: "总容量",
                        value: String(format: "%.0f GB", systemInfo.diskTotal),
                        icon: "internaldrive"
                    )

                    Divider()

                    infoRow(
                        title: "可用容量",
                        value: String(format: "%.0f GB", systemInfo.diskAvailable),
                        icon: "checkmark.circle"
                    )

                    Divider()

                    infoRow(
                        title: "已用容量",
                        value: String(format: "%.0f GB", systemInfo.diskTotal - systemInfo.diskAvailable),
                        icon: "arrow.up.circle"
                    )
                }
            }
        }
    }

    /// Git 信息
    private var gitInfoSection: some View {
        MagicSettingSection(title: "Git", titleAlignment: .leading) {
            VStack(spacing: 0) {
                if let gitVersion = systemInfo.gitVersion {
                    infoRow(
                        title: "Git 版本",
                        value: gitVersion,
                        icon: "git"
                    )
                } else {
                    HStack {
                        Image(systemName: "git")
                            .foregroundColor(.secondary)
                            .frame(width: 28)

                        Text("Git 版本")
                            .font(.system(size: 13))

                        Spacer()

                        Text("未安装")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
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
