import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class EventManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var n = NotificationCenter.default
    var queue = DispatchQueue(label: "EventQueue")
    
    func emitCommitted() {
        NotificationCenter.default.post(
            name: NSNotification.Name(Event.Committed.name),
            object: nil,
            userInfo: [:]
        )
    }
    
    func onCommitted(_ callback: @escaping () -> Void) {
        n.addObserver(
            forName: NSNotification.Name(Event.Committed.name),
            object: nil,
            queue: .main,
            using: { notification in
                self.queue.async {
                    callback()
                }
            })
    }
    
    func removeListener(_ observer: Any) {
        n.removeObserver(observer)
    }
    
    enum Event {
        case Committed
        case AudioUpdated
        case Delete
        
        var name: String {
            String(describing: self)
        }
    }
}
