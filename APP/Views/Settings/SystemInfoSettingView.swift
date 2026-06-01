import Foundation
import GitOKUI
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
        .navigationTitle(Text("System Info"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }) {
                    Text("完成")
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
        GitOKUI.AppSettingsSection(title: String(localized: "System")) {
            infoRow(title: String(localized: "System Name"), value: systemInfo.systemName, icon: "gearshape")
            infoRow(title: String(localized: "System Version"), value: systemInfo.systemVersion, icon: "gearshape")
            infoRow(title: String(localized: "Architecture"), value: systemInfo.architecture, icon: "gearshape")
            infoRow(title: String(localized: "Hostname"), value: systemInfo.hostname, icon: "gearshape")
        }
    }

    /// 硬件信息
    private var hardwareInfoSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Hardware")) {
            infoRow(title: String(localized: "Processor"), value: systemInfo.cpuModel, icon: "cpu")
            infoRow(
                title: String(localized: "Cores"),
                value: String.localizedStringWithFormat(String(localized: "%lld Cores"), Int64(systemInfo.cpuCores)),
                icon: "cpu"
            )
        }
    }

    /// 内存信息
    private var memoryInfoSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Memory")) {
            VStack(alignment: .leading, spacing: 16) {
                // 内存使用条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Memory Usage")
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
                .padding(.horizontal, 8)

                // 内存详情
                infoRow(title: String(localized: "Total Memory"), value: systemInfo.totalMemory, icon: "memorychip")
                infoRow(title: String(localized: "Free Memory"), value: systemInfo.freeMemory, icon: "memorychip")
                infoRow(title: String(localized: "Used Memory"), value: systemInfo.usedMemory, icon: "memorychip")
            }
        }
    }

    /// 磁盘信息
    private var diskInfoSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Disk")) {
            VStack(alignment: .leading, spacing: 16) {
                // 磁盘使用条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Disk Usage")
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
                .padding(.horizontal, 8)

                // 磁盘详情
                infoRow(title: String(localized: "Total Capacity"), value: systemInfo.totalDiskSpace, icon: "internaldrive")
                infoRow(title: String(localized: "Free Capacity"), value: systemInfo.freeDiskSpace, icon: "internaldrive")
                infoRow(title: String(localized: "Used Capacity"), value: systemInfo.usedDiskSpace, icon: "internaldrive")
            }
        }
    }

    /// Git 信息
    private var gitInfoSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Git")) {
            infoRow(
                title: String(localized: "Git Version"),
                value: systemInfo.gitVersion ?? String(localized: "Not Installed"),
                icon: "terminal"
            )
        }
    }

    /// 信息行
    private func infoRow(title: String, value: String, icon: String) -> some View {
        GitOKUI.AppSettingsRow(verticalPadding: 10) {
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
                        .textSelection(.enabled)
                }

                Spacer()
            }
        }
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
