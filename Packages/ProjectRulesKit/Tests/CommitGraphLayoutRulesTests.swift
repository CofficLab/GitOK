import ProjectRulesKit
import Testing

@Suite("CommitGraphLayoutRulesTests")
struct CommitGraphLayoutRulesTests {
    @Test("Linear history stays on one lane")
    func linearHistoryStaysOnOneLane() {
        let rows = CommitGraphLayoutRules.layout(nodes: [
            .init(id: "C", parentIDs: ["B"]),
            .init(id: "B", parentIDs: ["A"]),
            .init(id: "A", parentIDs: []),
        ])

        #expect(rows.map(\.nodeLane) == [0, 0, 0])
        #expect(rows.map(\.laneCount) == [1, 1, 1])
        #expect(rows[0].parentEdges == [.init(parentID: "B", fromLane: 0, toLane: 0)])
        #expect(rows[2].bottomSegments.isEmpty)
    }

    @Test("Unmerged branch tip opens a second lane without moving active lane")
    func branchTipOpensSecondLane() {
        let rows = CommitGraphLayoutRules.layout(nodes: [
            .init(id: "main2", parentIDs: ["base"]),
            .init(id: "feature1", parentIDs: ["base"]),
            .init(id: "base", parentIDs: []),
        ])

        #expect(rows[0].nodeLane == 0)
        #expect(rows[1].nodeLane == 1)
        #expect(rows[1].topSegments == [.init(lane: 0, id: "base")])
        #expect(rows[1].bottomSegments == [
            .init(lane: 0, id: "base"),
        ])
        #expect(rows[2].nodeLane == 0)
    }

    @Test("Merge commit connects to both parents")
    func mergeCommitConnectsBothParents() {
        let rows = CommitGraphLayoutRules.layout(nodes: [
            .init(id: "merge", parentIDs: ["main1", "feature1"]),
            .init(id: "main1", parentIDs: ["base"]),
            .init(id: "feature1", parentIDs: ["base"]),
            .init(id: "base", parentIDs: []),
        ])

        #expect(rows[0].nodeLane == 0)
        #expect(rows[0].bottomSegments == [
            .init(lane: 0, id: "main1"),
            .init(lane: 1, id: "feature1"),
        ])
        #expect(rows[0].parentEdges == [
            .init(parentID: "main1", fromLane: 0, toLane: 0),
            .init(parentID: "feature1", fromLane: 0, toLane: 1),
        ])
        #expect(rows[2].parentEdges == [
            .init(parentID: "base", fromLane: 1, toLane: 0),
        ])
    }

    @Test("Duplicate parents are ignored")
    func duplicateParentsAreIgnored() {
        let rows = CommitGraphLayoutRules.layout(nodes: [
            .init(id: "C", parentIDs: ["B", "B", "C"]),
            .init(id: "B", parentIDs: []),
        ])

        #expect(rows[0].parentEdges == [.init(parentID: "B", fromLane: 0, toLane: 0)])
    }
}
