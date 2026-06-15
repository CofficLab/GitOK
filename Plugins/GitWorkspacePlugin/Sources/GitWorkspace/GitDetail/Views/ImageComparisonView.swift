import AppKit
import SwiftUI

public struct ImageComparisonView: View {
    private let before: NSImage?
    private let after: NSImage?
    @Binding private var mode: GitDetailImageDiffMode
    @Binding private var blendAmount: Double

    public init(
        before: NSImage?,
        after: NSImage?,
        mode: Binding<GitDetailImageDiffMode>,
        blendAmount: Binding<Double>
    ) {
        self.before = before
        self.after = after
        self._mode = mode
        self._blendAmount = blendAmount
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar

            switch mode {
            case .twoUp:
                HStack(spacing: 0) {
                    ImagePreviewSectionView(title: GitDetailLocalization.string("Before"), image: before)

                    Divider()

                    ImagePreviewSectionView(title: GitDetailLocalization.string("After"), image: after)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(GitDetailLocalization.string("Image side-by-side comparison"))
            case .swipe:
                overlayComparison(mode: .swipe)
            case .onion:
                overlayComparison(mode: .onion)
            case .difference:
                overlayComparison(mode: .difference)
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Picker(GitDetailLocalization.string("Image Comparison Mode"), selection: $mode) {
                ForEach(GitDetailImageDiffMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 360)
            .accessibilityLabel(GitDetailLocalization.string("Image Comparison Mode"))

            if mode.usesBlendAmount {
                Slider(value: $blendAmount, in: 0...1)
                    .frame(width: 160)
                    .accessibilityLabel(mode.sliderAccessibilityLabel)

                Text(mode.valueLabel(for: blendAmount))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 52, alignment: .trailing)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }

    @ViewBuilder
    private func overlayComparison(mode: GitDetailImageDiffMode) -> some View {
        if let before, let after {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    ZStack(alignment: .leading) {
                        Color(NSColor.textBackgroundColor)

                        imageLayer(before, in: geometry)

                        switch mode {
                        case .swipe:
                            imageLayer(after, in: geometry)
                                .frame(width: max(1, geometry.size.width * blendAmount), alignment: .leading)
                                .clipped()

                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 2)
                                .offset(x: max(0, geometry.size.width * blendAmount - 1))
                        case .onion:
                            imageLayer(after, in: geometry)
                                .opacity(blendAmount)
                        case .difference:
                            imageLayer(after, in: geometry)
                                .blendMode(.difference)
                        case .twoUp:
                            EmptyView()
                        }
                    }
                    .frame(
                        width: max(max(before.size.width, after.size.width), geometry.size.width),
                        height: max(max(before.size.height, after.size.height), geometry.size.height)
                    )
                    .padding(8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(mode.accessibilityLabel)
            .accessibilityHint(mode.accessibilityHint)
        } else {
            ImagePreviewView(image: before ?? after)
        }
    }

    private func imageLayer(_ image: NSImage, in geometry: GeometryProxy) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                width: max(image.size.width, geometry.size.width),
                height: max(image.size.height, geometry.size.height)
            )
    }
}
