import Foundation
import SwiftUI

enum CommitCategory: String, CaseIterable, Equatable {
    static var auto = "\(CommitCategory.Chore.text) Auto Committed by GitOK"
    static var merge = "\(CommitCategory.CI.text) Merged by GitOK"

    case Bugfix
    case Chore
    case CI
    case Config
    case Docker
    case Document
    case Feature
    case FirstCommit
    case Improve
    case Release
    case Trash
    case Typo
    case UI

    var text: String {
        switch self {
        case .Bugfix:
            "🐛 Bugfix: "
        case .Chore:
            "🎨 Chore: "
        case .CI:
            "👷 CI: "
        case .Config:
            "🔧 Config: "
        case .Docker:
            "🐳 Docker: "
        case .Document:
            "📖 Document: "
        case .Feature:
            "🆕 Feature: "
        case .FirstCommit:
            "🎉 First Commit: "
        case .Improve:
            "🐎 Improve: "
        case .Release:
            "🔖 Release: "
        case .Trash:
            "🗑️ Trash: "
        case .Typo:
            "✏️ Typo: "
        case .UI:
            "💄 UI: "
        }
    }
    
    var defaultMessage: String {
        switch self {
        case .Bugfix:
            return "Fix a bug"
        case .Chore:
            return "Minor adjustments"
        case .CI:
            return "Configure continuous integration"
        case .Config:
            return "Update configuration settings"
        case .Docker:
            return "Update Docker configuration"
        case .Document:
            return "Update documentation"
        case .Feature:
            return "Implement a new feature"
        case .FirstCommit:
            return "Initial commit"
        case .Improve:
            return "Enhance existing functionality"
        case .Release:
            return "Prepare for release"
        case .Trash:
            return "Delete unnecessary code or files"
        case .Typo:
            return "Correct a typo"
        case .UI:
            return "Update user interface elements"
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
