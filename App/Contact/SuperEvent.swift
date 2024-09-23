import Foundation

protocol SuperEvent {

}

// MARK: Pull

extension SuperEvent {
    func emitGitPullStart() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitPullStart, object: self)
        }
    }

    func emitGitPullSuccess() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitPullSuccess, object: self)
        }
    }
}

// MARK: Push

extension SuperEvent {
    func emitGitPushStart() { 
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitPushStart, object: self)
        }
    }

    func emitGitPushSuccess() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitPushSuccess, object: self)
        }
    }

    func emitGitPushFailed() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitPushFailed, object: self)
        }
    }
}

// MARK: Commit

extension SuperEvent {
    func emitGitCommitStart() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitCommitStart, object: self)
        }
    }

    func emitGitCommitSuccess() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitCommitSuccess, object: self)
        }
    }

    func emitGitCommitFailed() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitCommitFailed, object: self)
        }
    }

    
}
