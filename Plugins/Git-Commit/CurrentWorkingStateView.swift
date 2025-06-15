import MagicCore
import OSLog
import SwiftUI

struct CurrentWorkingStateView: View, SuperLog {
    @EnvironmentObject var data: DataProvider

    @State private var changedFileCount = 0

    private var isSelected: Bool {
        data.commit == nil
    }

    static let emoji = "🌳"

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .medium))

                VStack(alignment: .leading, spacing: 2) {
                    Text("当前工作状态")
                        .font(.system(size: 14, weight: .medium))

                    Text("(\(changedFileCount) 个未提交文件)")
                        .font(.system(size: 11))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(Color.white.opacity(0.2))
        }
        .background(
            isSelected
                ? Color.green.opacity(0.12)
                : Color(.controlBackgroundColor)
        )
        .onTapGesture(perform: onTap)
        .onAppear(perform: onAppear)
        .onChange(of: data.project, onProjectDidChange)
        .onNotification(.projectDidCommit, onProjectDidCommit)
    }
}

// MARK: - Action

extension CurrentWorkingStateView {
    private func loadChangedFileCount() async {
        guard let project = data.project else {
            return
        }

        do {
            let count = try await project.untrackedFiles().count
            self.changedFileCount = count
        } catch {
            os_log(.error, "\(self.t)❌ Failed to load changed file count: \(error)")
        }
    }
}

// MARK: - Event

extension CurrentWorkingStateView {
    func onAppear() {
        Task {
            await self.loadChangedFileCount()
        }
    }

    func onTap() {
        data.commit = nil
    }

    func onProjectDidCommit(_ notification: Notification) {
        Task {
            await self.loadChangedFileCount()
        }
    }

    func onProjectDidChange() {
        Task {
            await self.loadChangedFileCount()
        }
    }
}

// MARK: - Preview

#Preview {
    CurrentWorkingStateView()
        .inRootView()
        .frame(width: 400)
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 700)
        .frame(height: 700)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
