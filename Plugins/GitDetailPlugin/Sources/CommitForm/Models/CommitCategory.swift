import GitOKCoreKit
import Foundation

/// Git 提交类别枚举
/// 定义不同类型的提交类别，每个类别都有对应的 emoji 和描述文本
public enum CommitCategory: String, CaseIterable, Equatable {
    public static let auto = "\(CommitCategory.Chore.text) Auto Committed by GitOK"
    public static let merge = "\(CommitCategory.CI.text) Merged by GitOK"

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

    public var label: String {
        "\(emoji) \(title)"
    }

    public var emoji: String {
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

    public var title: String {
        switch self {
        case .Bugfix:
            "Bugfix"
        case .Chore:
            "Chore"
        case .CI:
            "CI"
        case .Config:
            "Config"
        case .Docker:
            "Docker"
        case .Document:
            "Document"
        case .Feature:
            "Feature"
        case .FirstCommit:
            "First Commit"
        case .Improve:
            "Improve"
        case.I18n:
            "I18n"
        case .Release:
            "Release"
        case .Trash:
            "Trash"
        case .Typo:
            "Typo"
        case .UI:
            "UI"
        case .PackageUpdate:
            "Package Update"
        case .Test:
            "Test"
        }
    }

    public var text: String {
        "\(self.emoji) \(self.title): "
    }

    public func text(includeEmoji: Bool) -> String {
        if includeEmoji {
            return "\(self.emoji) \(self.title): "
        } else {
            return "\(self.title): "
        }
    }

    public func text(style: CommitStyle) -> String {
        let prefix: String
        if style.includeEmoji {
            prefix = "\(self.emoji) \(self.title): "
        } else if style.isLowercase {
            prefix = "\(self.title.lowercased()): "
        } else {
            prefix = "\(self.title): "
        }
        return prefix
    }

    public var defaultMessage: String {
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
        case.I18n:
            return "Translate or localize content"
        case .Release:
            return "Prepare for release"
        case .Trash:
            return "Delete unnecessary code or files"
        case .Typo:
            return "Correct a typo"
        case .UI:
            return "Update user interface elements"
        case .PackageUpdate:
            return "Update package dependencies"
        case .Test:
            return "Add or update tests"
        }
    }
}
