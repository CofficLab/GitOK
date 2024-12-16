import SwiftUI

struct DBConfigRow: View {
    let config: DatabaseConfig
    @EnvironmentObject var dbProvider: DatabaseProvider

    var body: some View {
        HStack {
            Image(systemName: config.type == .mysql ? "network" : "doc.fill")
                .foregroundColor(.purple)

            VStack(alignment: .leading) {
                Text(config.name)
                    .fontWeight(.medium)
                Text(config.type == .mysql ? "\(config.host ?? ""):\(config.port ?? 0)" : config.path ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if dbProvider.selectedConfigId == config.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if dbProvider.selectedConfigId != config.id {
                dbProvider.connect(configId: config.id)
            }
        }
    }
}
