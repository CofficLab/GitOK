import SwiftUI

public struct CommitUserMenu: View {
    private let currentUser: String
    private let currentEmail: String
    private let presets: [CommitUserPreset]
    private let onSelectPreset: (CommitUserPreset) -> Void
    private let onManagePresets: () -> Void

    public init(
        currentUser: String,
        currentEmail: String,
        presets: [CommitUserPreset],
        onSelectPreset: @escaping (CommitUserPreset) -> Void,
        onManagePresets: @escaping () -> Void
    ) {
        self.currentUser = currentUser
        self.currentEmail = currentEmail
        self.presets = presets
        self.onSelectPreset = onSelectPreset
        self.onManagePresets = onManagePresets
    }

    public var body: some View {
        Menu {
            if presets.isEmpty == false {
                ForEach(presets) { preset in
                    Button {
                        onSelectPreset(preset)
                    } label: {
                        HStack {
                            Text("\(preset.name) (\(preset.email))")

                            if isCurrentPreset(preset) {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }

                Divider()
            }

            Button {
                onManagePresets()
            } label: {
                Text("管理预设...", tableName: "GitCommit")
            }
        } label: {
            labelView
        }
        .menuStyle(.borderlessButton)
    }

    @ViewBuilder
    private var labelView: some View {
        if currentUser.isEmpty == false {
            configuredLabel
        } else {
            unconfiguredLabel
        }
    }

    private var configuredLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "person")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(currentUser)
                    .font(.caption)
                    .fontWeight(.medium)

                if currentEmail.isEmpty == false {
                    Text(currentEmail)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }

    private var unconfiguredLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 14))

            Text("未配置用户信息", tableName: "GitCommit")
                .font(.caption)
                .foregroundColor(.orange)

            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }

    private func isCurrentPreset(_ preset: CommitUserPreset) -> Bool {
        currentUser == preset.name && currentEmail == preset.email
    }
}
