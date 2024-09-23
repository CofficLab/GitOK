import Foundation

protocol SuperEvent {

}

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