import GitOKAppCore
import GitOKCoreKit
import GitOKSupportKit
import GitOKUI
import SwiftUI

struct DetailCommitStylePresetView: View, SuperLog {
    nonisolated static let emoji = "🎨"
    nonisolated static let verbose = false

    @EnvironmentObject private var data: DataVM
    @EnvironmentObject private var vm: ProjectVM

    @State private var projectCommitStyle: CommitStyle = .emoji
    @State private var globalCommitStyle: CommitStyle = .emoji

    private var stateRepo: any StateRepoProtocol {
        data.repoManager.stateRepo
    }

    var body: some View {
        AppSettingSection(title: "Commit 风格", titleAlignment: .leading) {
            VStack(spacing: 0) {
                projectCommitStylePicker
                Divider()
                    .padding(.vertical, 8)
                globalCommitStylePicker
            }
        }
        .onAppear(perform: loadData)
    }

    private var projectCommitStylePicker: some View {
        commitStylePickerRow(
            title: "当前项目风格",
            description: "此项目的 Commit 消息显示风格",
            icon: "square.and.pencil",
            selection: Binding(
                get: { projectCommitStyle },
                set: { style in
                    projectCommitStyle = style
                    if let project = vm.project {
                        project.commitStyle = style
                    }
                }
            )
        )
    }

    private var globalCommitStylePicker: some View {
        commitStylePickerRow(
            title: "全局默认风格",
            description: "新项目的默认 Commit 消息显示风格",
            icon: "arrow.up.arrow.down",
            selection: Binding(
                get: { globalCommitStyle },
                set: { style in
                    globalCommitStyle = style
                    stateRepo.setGlobalCommitStyle(style)
                }
            )
        )
    }

    private func commitStylePickerRow(
        title: String,
        description: String,
        icon: String,
        selection: Binding<CommitStyle>
    ) -> some View {
        AppSettingRow(
            title: title,
            description: description,
            icon: icon
        ) {
            Picker("", selection: selection) {
                ForEach(CommitStyle.allCases, id: \.self) { style in
                    Text(style.label)
                        .tag(style)
                }
            }
            .labelsHidden()
            .frame(width: 180)
        }
    }

    private func loadData() {
        if let project = vm.project {
            projectCommitStyle = project.commitStyle
        }
        globalCommitStyle = stateRepo.globalCommitStyle
    }
}
