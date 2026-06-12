import SwiftUI

struct BranchServiceKey: EnvironmentKey {
    static let defaultValue: (any BranchService)? = nil
}

extension EnvironmentValues {
    var branchService: (any BranchService)? {
        get { self[BranchServiceKey.self] }
        set { self[BranchServiceKey.self] = newValue }
    }
}
