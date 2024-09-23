import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class EventManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var n = NotificationCenter.default
    var queue = DispatchQueue(label: "EventQueue")
    
    func emitRefresh() {
        NotificationCenter.default.post(
            name: NSNotification.Name(AppConfig.Event.Refresh.name),
            object: nil,
            userInfo: [:]
        )
    }
    
    func emitDidBecomeActive() {
        NotificationCenter.default.post(
            name: NSNotification.Name(AppConfig.Event.DidBecomeActive.name),
            object: nil,
            userInfo: [:]
        )
    }
    
    func emitJSReady() {
        NotificationCenter.default.post(
            name: NSNotification.Name(AppConfig.Event.JSReady.name),
            object: nil,
            userInfo: [:]
        )
    }
    
    func onRefresh(_ callback: @escaping () -> Void) {
        n.addObserver(
            forName: NSNotification.Name(AppConfig.Event.Refresh.name),
            object: nil,
            queue: .main,
            using: { notification in
                self.queue.async {
                    callback()
                }
            })
    }
    
    func onJSReady(_ callback: @escaping () -> Void) {
        n.addObserver(
            forName: NSNotification.Name(AppConfig.Event.JSReady.name),
            object: nil,
            queue: .main,
            using: { notification in
                self.queue.async {
                    callback()
                }
            })
    }
    
    func onDidBecomeActive(_ callback: @escaping () -> Void) {
        n.addObserver(
            forName: NSNotification.Name(AppConfig.Event.DidBecomeActive.name),
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
}
