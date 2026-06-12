import SwiftUI

public struct AppInputField: View {
    public enum FieldType {
        case plain
        case secure
    }

    let placeholder: Text
    @Binding var text: String
    let fieldType: FieldType

    public init(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        fieldType: FieldType = .plain
    ) {
        self.placeholder = Text(placeholder)
        self._text = text
        self.fieldType = fieldType
    }

    public init(
        _ placeholder: String,
        text: Binding<String>,
        fieldType: FieldType = .plain
    ) {
        self.placeholder = Text(placeholder)
        self._text = text
        self.fieldType = fieldType
    }

    public var body: some View {
        Group {
            switch fieldType {
            case .plain:
                TextField(text: $text) {
                    placeholder
                }
            case .secure:
                SecureField(text: $text) {
                    placeholder
                }
            }
        }
        .textFieldStyle(.plain)
        .font(DesignTokens.Typography.body)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .fill(DesignTokens.Material.glass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        var body: some View {
            VStack(spacing: 16) {
                AppInputField("placeholder.plain", text: $text, fieldType: .plain)
                AppInputField("placeholder.secure", text: $text, fieldType: .secure)
            }
            .padding()
            .frame(width: 300)
            .background(Color.gray.opacity(0.15))
        }
    }
    return PreviewWrapper()
}
