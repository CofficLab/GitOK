import Foundation

public struct DiffBlock {
    public var block = ""

    public init(block: String = "") {
        self.block = block
    }

    public static func fromBlock(_ b: String) -> DiffBlock {
        DiffBlock(block: b)
    }

    public func getDiffs() -> [Diff] {
        block.components(separatedBy: "\n")
            .map({
                Diff.fromLine($0)
            })
    }
}
