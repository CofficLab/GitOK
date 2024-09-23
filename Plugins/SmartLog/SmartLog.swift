import Foundation
import SwiftUI
import SwiftData

@Model
final class SmartLog: Hashable, Identifiable {
    var id: String = UUID().uuidString
    var createdAt: Date = Date()
    var author: String? = "[无]"
    var title: String? = "[无]"
    var content: String? = "[无]"
    var ideaTitle: String? = nil
    
    @Transient
    var createdAtString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return dateFormatter.string(from: createdAt)
    }
    
    @Transient
    var createdAtStringLong: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        return dateFormatter.string(from: createdAt)
    }
    
    init(author: String?, title: String?, content: String?, ideaTitle: String?) {
        self.id = UUID().uuidString
        self.author = author
        self.title = title
        self.content = content
        self.ideaTitle = ideaTitle
        self.createdAt = Date()
    }
    
    func getTitle() -> String {
        title ?? "[无]"
    }
    
    static func destroy(_ context: ModelContext) {
        let result = try! context.fetch(FetchDescriptor<SmartLog>(predicate: #Predicate<SmartLog> {
            $0.id != ""
        }))
        
        for log in result {
            context.delete(log)
        }
        
        try! context.save()
    }
}
