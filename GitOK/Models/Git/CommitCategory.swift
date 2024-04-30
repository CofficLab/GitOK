import Foundation
import SwiftUI

enum CommitCategory: String, CaseIterable {
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
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
