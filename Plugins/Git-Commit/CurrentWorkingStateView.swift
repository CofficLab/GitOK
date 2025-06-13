import SwiftUI
import MagicCore

struct CurrentWorkingStateView: View {
    @EnvironmentObject var data: DataProvider
    
    private var isSelected: Bool {
        data.commit == nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(isSelected ? .white : .secondary)
                    .font(.system(size: 16, weight: .medium))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前工作状态")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text("Working Directory")
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.2))
        }
        .background(
            isSelected 
                ? Color.green.opacity(0.2)
                : Color(.controlBackgroundColor)
        )
        .onTapGesture {
            data.commit = nil
        }
    }
}

#Preview {
    CurrentWorkingStateView()
        .inRootView()
        .frame(width: 400)
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 700)
    .frame(height: 700)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

