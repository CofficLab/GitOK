import LumiUI
import ProviderCommitForm
import SwiftUI

/// 工具栏风格的选择器控件：显示当前选中值，点击弹出选项列表（Lumi 风格）。
/// 用于替换原生 Picker，提供更一致的工具栏 UI 体验。
struct ToolbarStylePicker<T: Hashable>: View {
    let title: String
    let options: [T]
    let selection: T
    let labelForOption: (T) -> String
    let onSelectionChanged: (T) -> Void
    
    @State private var isPopoverPresented = false
    @State private var isHovering = false
    
    var body: some View {
        Button {
            isPopoverPresented = true
        } label: {
            HStack(spacing: 6) {
                Text(labelForOption(selection))
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Image(systemName: isPopoverPresented ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHighlighted ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            popoverContent
        }
        .onHover { isHovering = $0 }
    }
    
    private var isHighlighted: Bool {
        isHovering || isPopoverPresented
    }
    
    @ViewBuilder
    private var popoverContent: some View {
        VStack(spacing: 0) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                Divider()
            }
            
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(options, id: \.self) { option in
                        row(for: option)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 200)
    }
    
    private func row(for option: T) -> some View {
        let isSelected = option == selection
        return Button {
            onSelectionChanged(option)
            isPopoverPresented = false
        } label: {
            HStack(spacing: 8) {
                Text(labelForOption(option))
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
