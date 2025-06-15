import MagicCore
import OSLog
import SwiftUI

struct TileQuickMerge: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var g: DataProvider

    @State var hovered = false
    
    static let shared = TileQuickMerge()
    
    private init() {}

    var project: Project? { g.project }

    var body: some View {
        HStack {            
            Image(systemName: "arrowshape.zigzag.forward")
        }
        .help("快速合并")
        .onHover(perform: { hovering in
            hovered = hovering
        })
        .onTapGesture {
            merge()
            self.m.info("已合并到主分支")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    func merge() {
//        self.bg.async {
//            guard let project = project else {
//                os_log(.error, "\(self.t)No project")
//                self.m.error(QuickMergeError.noProject)
//                return
//            }
//
//            do {
//                try ShellGit.merge(project.path)
//            } catch let error {
//                os_log(.error, "\(error.localizedDescription)")
//
//                m.setError(error)
//            }
//        }
    }
}

enum QuickMergeError: Error, LocalizedError {
    case noProject

    var localizedDescription: String {
        switch self {
        case .noProject:
            return "在快速合并时没有项目"
        }
    }
}
