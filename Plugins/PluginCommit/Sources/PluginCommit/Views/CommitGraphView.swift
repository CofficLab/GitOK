import SwiftUI
import GitOKCoreKit

public struct CommitGraphView: View {
    let row: CommitGraphLayoutRules.Row?
    let laneCount: Int

    private let preferredLaneSpacing: CGFloat = 12
    private let maxGraphWidth: CGFloat = 120
    private let horizontalPadding: CGFloat = 8
    private let nodeRadius: CGFloat = 4
    private let lineWidth: CGFloat = 1.5

    public init(row: CommitGraphLayoutRules.Row?, laneCount: Int) {
        self.row = row
        self.laneCount = laneCount
    }

    public var body: some View {
        Canvas { context, size in
            guard let row else { return }

            let midY = size.height / 2
            let bottomY = size.height

            for segment in row.topSegments {
                let x = laneX(segment.lane)
                strokeLine(in: &context, from: CGPoint(x: x, y: 0), to: CGPoint(x: x, y: midY), id: segment.id)
            }

            for segment in row.bottomSegments {
                let x = laneX(segment.lane)
                strokeLine(in: &context, from: CGPoint(x: x, y: midY), to: CGPoint(x: x, y: bottomY), id: segment.id)
            }

            for edge in row.parentEdges where edge.fromLane != edge.toLane {
                let startX = laneX(edge.fromLane)
                let endX = laneX(edge.toLane)
                var path = Path()
                path.move(to: CGPoint(x: startX, y: midY))
                path.addCurve(
                    to: CGPoint(x: endX, y: bottomY),
                    control1: CGPoint(x: startX, y: midY + size.height * 0.22),
                    control2: CGPoint(x: endX, y: bottomY - size.height * 0.22)
                )
                context.stroke(path, with: .color(color(for: edge.parentID)), lineWidth: lineWidth)
            }

            let nodeCenter = CGPoint(x: laneX(row.nodeLane), y: midY)
            let nodeRect = CGRect(
                x: nodeCenter.x - nodeRadius,
                y: nodeCenter.y - nodeRadius,
                width: nodeRadius * 2,
                height: nodeRadius * 2
            )
            context.fill(Path(ellipseIn: nodeRect), with: .color(color(for: row.commitID)))
            context.stroke(Path(ellipseIn: nodeRect.insetBy(dx: -1, dy: -1)), with: .color(.white.opacity(0.85)), lineWidth: 1)
        }
        .frame(width: graphWidth)
        .frame(minHeight: 34)
        .accessibilityHidden(true)
    }

    private var graphWidth: CGFloat {
        let visibleLanes = max(laneCount, 1)
        let preferredWidth = horizontalPadding * 2 + CGFloat(visibleLanes - 1) * preferredLaneSpacing + nodeRadius * 2
        return min(preferredWidth, maxGraphWidth)
    }

    private var actualLaneSpacing: CGFloat {
        guard laneCount > 1 else { return preferredLaneSpacing }

        let availableWidth = maxGraphWidth - horizontalPadding * 2 - nodeRadius * 2
        let compressedSpacing = availableWidth / CGFloat(laneCount - 1)
        return min(preferredLaneSpacing, max(compressedSpacing, 3))
    }

    private func laneX(_ lane: Int) -> CGFloat {
        horizontalPadding + nodeRadius + CGFloat(lane) * actualLaneSpacing
    }

    private func strokeLine(in context: inout GraphicsContext, from: CGPoint, to: CGPoint, id: String) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color(for: id)), lineWidth: lineWidth)
    }

    private func color(for id: String) -> Color {
        let palette: [Color] = [
            .blue,
            .pink,
            .teal,
            .orange,
            .purple,
            .brown,
            .green,
            .red,
        ]
        let value = id.unicodeScalars.reduce(0) { partial, scalar in
            partial &+ Int(scalar.value)
        }
        return palette[abs(value) % palette.count]
    }
}
