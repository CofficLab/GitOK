import Foundation
import GitOKCoreKit

extension GitOKAppTab {
  public var displayName: String {
    switch self {
    case .git:
      String(localized: "Git", bundle: .module, comment: "Main window Git tab title")
    }
  }

  public var sortOrder: Int {
    switch self {
    case .git: 0
    }
  }

  public static var sortedAllCases: [GitOKAppTab] {
    allCases.sorted { $0.sortOrder < $1.sortOrder }
  }
}
