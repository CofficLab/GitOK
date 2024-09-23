import Foundation

extension Notification.Name {
    static let appReady = Notification.Name("appReady")
    static let appExit = Notification.Name("appExit")
    static let appError = Notification.Name("appError")
    static let appLog = Notification.Name("appLog")
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let appWillBecomeActive = Notification.Name("appWillBecomeActive")
    static let appWillResignActive = Notification.Name("appWillResignActive")
}
