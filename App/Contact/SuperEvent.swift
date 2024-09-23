import Foundation

protocol SuperEvent {

}

// MARK: Push

extension SuperEvent {
    func emitGitPushing() {
        NotificationCenter.default.post(name: .gitPushing, object: self)
    }

    func emitGitPulling() {
        NotificationCenter.default.post(name: .gitPulling, object: self)
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
