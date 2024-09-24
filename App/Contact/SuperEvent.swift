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

    func emitGitPullFailed() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitPullFailed, object: self)
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

// MARK: Branch

extension SuperEvent {
    func emitGitBranchChanged(branch: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitBranchChanged, object: self, userInfo: ["branch": branch])
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

// MARK: JS

extension SuperEvent {
    func emitJsReady() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .jsReady, object: self)
        }
    }
}

// MARK: App

extension SuperEvent {
    func emitAppReady() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appReady, object: self)
        }
    }

    func emitAppExit() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appExit, object: self)
        }
    }

    func emitAppError() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appError, object: self)
        }
    }

    func emitAppLog() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appLog, object: self)
        }
    }
    
    func emitAppDidBecomeActive() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appDidBecomeActive, object: self)
        }
    }

    func emitAppWillBecomeActive() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appWillBecomeActive, object: self)
        }
    }

    func emitAppWillResignActive() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appWillResignActive, object: self)
        }
    }
}
