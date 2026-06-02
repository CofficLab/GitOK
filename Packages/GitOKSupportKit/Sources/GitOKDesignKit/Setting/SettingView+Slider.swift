import GitOKFoundationKit
import SwiftUI

/// A slider setting component
public struct MagicSettingSlider<V: BinaryFloatingPoint>: View where V.Stride: BinaryFloatingPoint {
    let title: String
    let description: String?
    let icon: String?
    @Binding var value: V
    let range: ClosedRange<V>
    let step: V.Stride
    
    public init(
        title: String,
        description: String? = nil,
        icon: String? = nil,
        value: Binding<V>,
        range: ClosedRange<V>,
        step: V.Stride = 1
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self._value = value
        self.range = range
        self.step = step
    }
    
    public var body: some View {
        MagicSettingRow(title: title, description: description, icon: icon) {
            Slider(value: $value, in: range, step: step)
                .frame(width: 200)
        }
    }
}

// MARK: - Preview
