import Foundation

protocol SuperEvent {

}

extension SuperEvent {
    var notification: NotificationCenter {
        NotificationCenter.default
    }

    var nc: NotificationCenter { NotificationCenter.default }

    func emit(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        DispatchQueue.main.async {
            self.nc.post(name: name, object: object, userInfo: userInfo)
        }
    }

    func emit(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        self.emit(name, object: object, userInfo: userInfo)
    }
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

// MARK: Project

extension SuperEvent {
    func emitGitProjectDeleted(path: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gitProjectDeleted, object: self, userInfo: ["path": path])
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

// MARK: Banner

extension SuperEvent {
    func emitBannerChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerChanged, object: self)
        }
    }

    func emitBannerListChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerListChanged, object: self)
        }
    }

    func emitBannerAdded() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerAdded, object: self)
        }
    }

    func emitBannerRemoved() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerRemoved, object: self)
        }
    }

    func emitBannerTitleChanged(title: String, id: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerTitleChanged, object: self, userInfo: ["title": title, "id": id])
        }
    }
}

// MARK: Icon

extension SuperEvent {
    func emitIconDidChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iconDidChange, object: self)
        }
    }

    func emitIconDidSave() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iconDidSave, object: self)
        }
    }

    func emitIconDidFail() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iconDidFail, object: self)
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
