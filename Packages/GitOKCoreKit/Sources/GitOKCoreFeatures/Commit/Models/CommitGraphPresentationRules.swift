
public enum CommitGraphPresentationRules {
    public typealias Node = CommitGraphLayoutRules.Node
    public typealias Row = CommitGraphLayoutRules.Row

    public struct GraphState: Sendable {
        public let rowsByCommitID: [String: Row]
        public let laneCount: Int

        public init(rowsByCommitID: [String: Row], laneCount: Int) {
            self.rowsByCommitID = rowsByCommitID
            self.laneCount = laneCount
        }
    }

    public static func rows(nodes: [Node]) -> [Row] {
        CommitGraphLayoutRules.layout(nodes: nodes)
    }

    public static func rows<ID>(
        commits: [(id: ID, parentIDs: [ID])]
    ) -> [Row] where ID: CustomStringConvertible {
        rows(nodes: commits.map {
            Node(
                id: $0.id.description,
                parentIDs: $0.parentIDs.map(\.description)
            )
        })
    }

    public static func rowsByCommitID(from rows: [Row]) -> [String: Row] {
        Dictionary(uniqueKeysWithValues: rows.map { ($0.commitID, $0) })
    }

    public static func laneCount(from rows: [Row]) -> Int {
        max(rows.map(\.laneCount).max() ?? 1, 1)
    }

    public static func graphState<ID>(
        commits: [(id: ID, parentIDs: [ID])]
    ) -> GraphState where ID: CustomStringConvertible {
        let rows = rows(commits: commits)
        return GraphState(
            rowsByCommitID: rowsByCommitID(from: rows),
            laneCount: laneCount(from: rows)
        )
    }

    public static func graphState<Item, ID>(
        from items: [Item],
        id: (Item) -> ID,
        parentIDs: (Item) -> [ID]
    ) -> GraphState where ID: CustomStringConvertible {
        graphState(commits: items.map {
            (id: id($0), parentIDs: parentIDs($0))
        })
    }

    public static func performGraphState(
        _ state: GraphState,
        setRowsByCommitID: ([String: Row]) -> Void,
        setLaneCount: (Int) -> Void
    ) {
        setRowsByCommitID(state.rowsByCommitID)
        setLaneCount(state.laneCount)
    }

    public static func row(
        for commitID: String,
        showsCommitGraph: Bool,
        rowsByCommitID: [String: Row]
    ) -> Row? {
        guard showsCommitGraph else {
            return nil
        }

        return rowsByCommitID[commitID]
    }
}
