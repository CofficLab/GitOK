import Foundation

extension AppConfig {
    static var mainQueue: DispatchQueue {
        DispatchQueue.main
    }
    
    static var bgQueue: DispatchQueue {
        DispatchQueue.global()
    }
}
