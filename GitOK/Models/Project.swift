import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    static var orderReverse = [
        SortDescriptor<Project>(\.timestamp, order: .reverse)
    ]
    
    var timestamp: Date
    var url: URL
    
    var title: String {
        url.lastPathComponent
    }
    
    var path: String {
        url.path
    }
    
    var headCommit: GitCommit {
        GitCommit.headFor(path)
    }
    
    init(_ url: URL) {
        self.timestamp = .now
        self.url = url
    }
    
    func getCommits() -> [GitCommit] {
        try! Git.logs(path)
    }
    
    func getCommitsWithHead() -> [GitCommit] {
        [self.headCommit] + getCommits()
    }
}

extension Project: Identifiable {
    var id: URL {
        self.url
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
