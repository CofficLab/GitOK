import Foundation

protocol SuperEvent {

}

// MARK: Pull

extension SuperEvent {
    func emitGitPullStart() {
        NotificationCenter.default.post(name: .gitPullStart, object: self)
    }

    func emitGitPullSuccess() {
        NotificationCenter.default.post(name: .gitPullSuccess, object: self)
    }
}

// MARK: Push

extension SuperEvent {
    func emitGitPushStart() { 
        NotificationCenter.default.post(name: .gitPushStart, object: self)
    }

    func emitGitPushSuccess() {
        NotificationCenter.default.post(name: .gitPushSuccess, object: self)
    }

    func emitGitPushFailed() {
        NotificationCenter.default.post(name: .gitPushFailed, object: self)
    }
}

// MARK: Commit

extension SuperEvent {
    func emitGitCommitStart() {
        NotificationCenter.default.post(name: .gitCommitStart, object: self)
    }

    func emitGitCommitSuccess() {
        NotificationCenter.default.post(name: .gitCommitSuccess, object: self)
    }

    func emitGitCommitFailed() {
        NotificationCenter.default.post(name: .gitCommitFailed, object: self)
    }

    
}
