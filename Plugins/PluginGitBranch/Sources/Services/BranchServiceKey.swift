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

struct BranchMonitorKey: EnvironmentKey {
    static let defaultValue: BranchMonitor? = nil
}

extension EnvironmentValues {
    var branchMonitor: BranchMonitor? {
        get { self[BranchMonitorKey.self] }
        set { self[BranchMonitorKey.self] = newValue }
    }
}
