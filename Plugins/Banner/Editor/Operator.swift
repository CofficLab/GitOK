import SwiftUI

struct Operator: View {
    var text: String
    var action: (() -> Void) = {
        print("clicked")
    }

    init(_ text: String, action: @escaping () -> Void = { print("clicked") }) {
        self.text = text
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .padding(.horizontal, 8)
                .overlay(
                    Rectangle()
                        .fill(Color.green.opacity(0.2))
                        .frame(height: 30)
                        .cornerRadius(8)).padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}

