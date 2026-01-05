import Foundation
import SwiftUI

enum CommitCategory: String, CaseIterable, Equatable {
    static var auto = "\(CommitCategory.Chore.text) Auto Committed by GitOK"
    static var merge = "\(CommitCategory.CI.text) Merged by GitOK"

    case Bugfix
    case Chore
    case PackageUpdate
    case CI
    case Config
    case I18n
    case Test
    case Trash
    case UI
    case Improve
    case Docker
    case Document
    case Feature
    case FirstCommit
    case Release
    case Typo
    
    var label: String {
        "\(emoji) \(title)"
    }

    var emoji: String {
        switch self {
        case .Bugfix:
            "🐛"
        case .Chore:
            "🎨"
        case .CI:
            "👷"
        case .Config:
            "🔧"
        case .Docker:
            "🐳"
        case .Document:
            "📖"
        case .Feature:
            "🆕"
        case .FirstCommit:
            "🎉"
        case.I18n:
            "🌍"
        case .Improve:
            "🐎"
        case .Release:
            "🔖"
        case .Trash:
            "🗑️"
        case .Typo:
            "✏️"
        case .UI:
            "💄"
        case .PackageUpdate:
            "📦"
        case .Test:
            "🧪"
        }
    }

    var title: String {
        switch self {
        case .Bugfix:
            "bugfix"
        case .Chore:
            "chore"
        case .CI:
            "ci"
        case .Config:
            "config"
        case .Docker:
            "docker"
        case .Document:
            "document"
        case .Feature:
            "feature"
        case .FirstCommit:
            "first commit"
        case .Improve:
            "improve"
        case.I18n:
            "i18n"
        case .Release:
            "release"
        case .Trash:
            "trash"
        case .Typo:
            "typo"
        case .UI:
            "ui"
        case .PackageUpdate:
            "package update"
        case .Test:
            "test"
        }
    }

    var text: String {
        "\(self.title): "
    }
    
    var defaultMessage: String {
        switch self {
        case .Bugfix:
            return "fix a bug"
        case .Chore:
            return "minor adjustments"
        case .CI:
            return "configure continuous integration"
        case .Config:
            return "update configuration settings"
        case .Docker:
            return "update docker configuration"
        case .Document:
            return "update documentation"
        case .Feature:
            return "implement a new feature"
        case .FirstCommit:
            return "initial commit"
        case .Improve:
            return "enhance existing functionality"
        case.I18n:
            return "translate or localize content"
        case .Release:
            return "prepare for release"
        case .Trash:
            return "delete unnecessary code or files"
        case .Typo:
            return "correct a typo"
        case .UI:
            return "update user interface elements"
        case .PackageUpdate:
            return "update package dependencies"
        case .Test:
            return "add or update tests"
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
