import SwiftUI

/// Visual selector for the shared legacy background catalog.
public struct MagicBackgroundPicker: View {
    @Binding private var selection: String

    public init(selection: Binding<String>) {
        _selection = selection
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MagicBackgroundGroup.all, id: \.rawValue) { gradient in
                    Button {
                        selection = gradient.rawValue
                    } label: {
                        MagicBackgroundGroup(for: gradient)
                            .frame(width: 58, height: 42)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        selection == gradient.rawValue ? Color.accentColor : .clear,
                                        lineWidth: 2
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .help(gradient.displayName)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}
