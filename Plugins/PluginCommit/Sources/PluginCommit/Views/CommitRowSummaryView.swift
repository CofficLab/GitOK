import Foundation
import ProjectRulesKit
import SwiftUI

public struct CommitRowSummaryView: View {
    private let graphRow: CommitGraphLayoutRules.Row?
    private let graphLaneCount: Int
    private let message: String
    private let tag: String
    private let authors: String
    private let relativeTime: String
    private let fullDateTime: String
    private let avatarUsers: [AvatarUser]

    public init(
        graphRow: CommitGraphLayoutRules.Row?,
        graphLaneCount: Int,
        message: String,
        tag: String,
        authors: String,
        relativeTime: String,
        fullDateTime: String,
        avatarUsers: [AvatarUser]
    ) {
        self.graphRow = graphRow
        self.graphLaneCount = graphLaneCount
        self.message = message
        self.tag = tag
        self.authors = authors
        self.relativeTime = relativeTime
        self.fullDateTime = fullDateTime
        self.avatarUsers = avatarUsers
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let graphRow {
                CommitGraphView(row: graphRow, laneCount: graphLaneCount)
                    .padding(.leading, 2)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(message)
                        .lineLimit(1)
                        .font(.system(size: 13))

                    if tag.isEmpty == false {
                        Text(tag)
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(3)
                    }

                    Spacer()
                }

                HStack(spacing: 4) {
                    if let firstUser = avatarUsers.first {
                        AvatarView(user: firstUser, size: 14)
                    }

                    Text(authors)
                        .padding(.vertical, 1)
                        .lineLimit(1)

                    Text(relativeTime)
                        .padding(.vertical, 1)
                        .padding(.horizontal, 1)

                    Spacer()
                }
                .padding(.vertical, 1)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

                HStack {
                    Text(fullDateTime)
                        .lineLimit(1)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.vertical, 6)
            .padding(.leading, 8)
            .frame(minHeight: 25)
        }
    }
}
