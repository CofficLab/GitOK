import MagicCore
import MagicShell
import MagicUI
import SwiftUI

struct BranchRowView: View {
    let branch: GitBranch
    let isSelected: Bool
    let onSwitch: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.system(size: 12))
            
            Text(branch.name)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
            
            if !isSelected {
                MagicButton.simple {
                    onSwitch()
                }
                .magicTitle("切换")
                .magicSize(.small)
                .magicIcon(.iconCheckmark)
            } else {
                Text("当前")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

