import MagicCore
import SwiftUI

/**
 * 展示 Commit 详细信息的视图组件
 */
struct CommitDetail: View, SuperEvent {
    @EnvironmentObject var data: DataProvider
    
    let commit: GitCommit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if !commit.isHead {
                    CommitInfoView(commit: commit)
                } else {
                    CommitForm()
                }
                
            }
            .padding(.horizontal, 16)

            
            HSplitView {
                FileList(file: $data.file, commit: commit)
                    .frame(idealWidth: 200)
                    .frame(minWidth: 200, maxWidth: 300)
                    .layoutPriority(1)

                if let file = data.file {
                    FileDetail(file: file, commit: commit)
                }
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        .background(background)
        .onChange(of: data.project) { self.onProjectChanged() }
        .onReceive(nc.publisher(for: .appWillBecomeActive), perform: onAppWillBecomeActive)
    }

    private var background: some View {
        ZStack {
            if commit.isHead {
                MagicBackground.blueberry.opacity(0.12)
            } else {
                MagicBackground.orange.opacity(0.15)
            }
        }
    }
}

// MARK: - Event

extension CommitDetail {
    func onAppWillBecomeActive(_ notification: Notification) {
        
    }

    func onProjectChanged() {
        
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
