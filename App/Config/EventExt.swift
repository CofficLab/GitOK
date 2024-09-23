import Foundation

extension AppConfig {
    enum Event {
        case Committed
        case AudioUpdated
        case Delete
        case JSReady
        case Refresh
        case DidBecomeActive
        
        var name: String {
            String(describing: self)
        }
    }
}
