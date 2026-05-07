import Foundation

struct GitStashEntry: Equatable {
    let index: Int
    let message: String
}

enum GitMergeFileState: String, Equatable {
    case unresolved
    case pendingStage
    case staged
}

struct GitMergeFile: Identifiable, Equatable {
    let path: String
    let state: GitMergeFileState

    var id: String { path }
}

struct GitStatusEntry: Equatable {
    let path: String
    let indexStatus: Character
    let workTreeStatus: Character
}
