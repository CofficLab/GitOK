import Foundation
import GitOKCoreKit

extension GitOKAppTab {
  public var displayName: String {
    switch self {
    case .git:
      String(localized: "Git", bundle: .module, comment: "Main window Git tab title")
    case .banner:
      String(localized: "Banner", bundle: .module, comment: "Main window Banner tab title")
    case .icon:
      String(localized: "Icon", bundle: .module, comment: "Main window Icon tab title")
    }
  }

  public var sortOrder: Int {
    switch self {
    case .git: 0
    case .icon: 1
    case .banner: 2
    }
  }

  public static var sortedAllCases: [GitOKAppTab] {
    allCases.sorted { $0.sortOrder < $1.sortOrder }
  }
}
