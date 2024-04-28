import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    var timestamp: Date
    var url: URL
    
    var title: String {
        url.lastPathComponent
    }
    
    var path: String {
        url.path
    }
    
    init(_ url: URL) {
        self.timestamp = .now
        self.url = url
    }
    
    func getCommits() -> [GitCommit] {
        let commits = try! Git.logs(path)
        
        return [GitCommit.headFor(path)] + commits
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
