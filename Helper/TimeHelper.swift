import Foundation

class TimeHelper {
    static func getTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: Date())
    }
    
    static func toTimeString(_ time: Date?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let t = time {
            return dateFormatter.string(from: t)
        } else {
            return "-"
        }
    }
}
