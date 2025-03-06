import SwiftUI
import AppKit

struct ResizableColumn: View {
    let title: String
    let width: CGFloat
    let onResize: (CGFloat) -> Void
    
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
                .lineLimit(1)
            
            Image(systemName: "arrow.up.arrow.down.square.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: width, alignment: .leading)
        .background(Color(.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: isDragging ? 2 : 1, height: nil)
                .foregroundColor(isDragging ? Color.blue : Color(.separatorColor))
                .contentShape(Rectangle().inset(by: -4)) // 增加可点击区域
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            isDragging = true
                            let newWidth = width + value.translation.width - dragOffset
                            if newWidth >= 50 { // 最小宽度
                                onResize(newWidth)
                            }
                            dragOffset = value.translation.width
                        }
                        .onEnded { _ in
                            isDragging = false
                            dragOffset = 0
                        }
                ),
            alignment: .trailing
        )
        .overlay(
            Rectangle()
                .frame(width: nil, height: 1)
                .foregroundColor(Color(.separatorColor)),
            alignment: .bottom
        )
    }
} 
