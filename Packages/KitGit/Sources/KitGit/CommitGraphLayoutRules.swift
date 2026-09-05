import Foundation

/// Commit graph 布局算法：把提交（含 parent 关系）映射成行内的 lane 布局
/// （移植自旧版 KitProjectRules.CommitGraphLayoutRules，纯 Foundation 无外部依赖）。
public enum CommitGraphLayoutRules {
    public struct Node: Equatable, Sendable {
        public let id: String
        public let parentIDs: [String]

        public init(id: String, parentIDs: [String]) {
            self.id = id
            self.parentIDs = parentIDs
        }
    }

    public struct Segment: Equatable, Sendable {
        public let lane: Int
        public let id: String

        public init(lane: Int, id: String) {
            self.lane = lane
            self.id = id
        }
    }

    public struct Edge: Equatable, Sendable {
        public let parentID: String
        public let fromLane: Int
        public let toLane: Int

        public init(parentID: String, fromLane: Int, toLane: Int) {
            self.parentID = parentID
            self.fromLane = fromLane
            self.toLane = toLane
        }
    }

    public struct Row: Equatable, Sendable {
        public let commitID: String
        public let nodeLane: Int
        public let topSegments: [Segment]
        public let bottomSegments: [Segment]
        public let parentEdges: [Edge]
        public let laneCount: Int

        public init(
            commitID: String,
            nodeLane: Int,
            topSegments: [Segment],
            bottomSegments: [Segment],
            parentEdges: [Edge],
            laneCount: Int
        ) {
            self.commitID = commitID
            self.nodeLane = nodeLane
            self.topSegments = topSegments
            self.bottomSegments = bottomSegments
            self.parentEdges = parentEdges
            self.laneCount = laneCount
        }
    }

    /// 按提交顺序（新→旧）计算每一行的 lane 布局。
    public static func layout(nodes: [Node]) -> [Row] {
        var activeLanes: [String] = []
        var rows: [Row] = []

        for node in nodes {
            let topSegments = activeLanes.enumerated().map { lane, id in
                Segment(lane: lane, id: id)
            }

            let nodeLane: Int
            if let existingLane = activeLanes.firstIndex(of: node.id) {
                nodeLane = existingLane
            } else {
                activeLanes.append(node.id)
                nodeLane = activeLanes.count - 1
            }

            let parentIDs = uniqueParentIDs(from: node.parentIDs, excluding: node.id)
            var bottomLanes = activeLanes

            if let currentLane = bottomLanes.firstIndex(of: node.id) {
                bottomLanes.remove(at: currentLane)

                for (offset, parentID) in parentIDs.enumerated() where bottomLanes.contains(parentID) == false {
                    let insertionIndex = min(currentLane + offset, bottomLanes.count)
                    bottomLanes.insert(parentID, at: insertionIndex)
                }
            }

            let bottomSegments = bottomLanes.enumerated().map { lane, id in
                Segment(lane: lane, id: id)
            }

            let parentEdges = parentIDs.compactMap { parentID -> Edge? in
                guard let parentLane = bottomLanes.firstIndex(of: parentID) else { return nil }
                return Edge(parentID: parentID, fromLane: nodeLane, toLane: parentLane)
            }

            rows.append(Row(
                commitID: node.id,
                nodeLane: nodeLane,
                topSegments: topSegments,
                bottomSegments: bottomSegments,
                parentEdges: parentEdges,
                laneCount: max(topSegments.count, bottomSegments.count, nodeLane + 1)
            ))

            activeLanes = bottomLanes
        }

        return rows
    }

    private static func uniqueParentIDs(from parentIDs: [String], excluding commitID: String) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []

        for parentID in parentIDs where parentID != commitID {
            guard seen.insert(parentID).inserted else { continue }
            result.append(parentID)
        }

        return result
    }
}
