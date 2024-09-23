import Foundation
import OSLog
import SwiftData
import SwiftUI

class MessageProvider: ObservableObject, SuperLog, SuperThread, SuperEvent {
    @Published var messages: [SmartMessage] = []
    @Published var alerts: [String] = []
    @Published var error: Error? = nil

    init() {
        let verbose = false
        if verbose {
            os_log("\(Logger.initLog) MessageProvider")
        }
    }

    func setError(_ error: Error) {
        main.async {
            self.error = error
        }
    }

    func clearError() {
        self.error = nil
    }

    func append(_ message: String) {
        main.async {
            self.messages.insert(SmartMessage(description: message), at: 0)
            self.main.asyncAfter(deadline: .now() + 3) {
                if self.messages.count > 10 {
                    _ = self.messages.popLast()
                }
            }
        }
    }
}
