import Foundation

struct CommitSample: Hashable {
    static var all: [CommitSample] = [
        CommitSample(type: .Improve, message: "Improved"),
        CommitSample(type: .Bugfix, message: "Bug Fixed"),
        CommitSample(type: .Chore, message: "Chore"),
        CommitSample(type: .Chore, message: "Update dependencies"),
        CommitSample(type: .Improve, message: "Improve performance"),
        CommitSample(type: .CI, message: "Modify CI/CD configuration"),
        CommitSample(type: .Feature, message: "Implement new functionality")
    ]
    
    var type: CommitCategory
    var message: String
}
