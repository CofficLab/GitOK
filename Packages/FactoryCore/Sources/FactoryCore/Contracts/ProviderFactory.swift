import KernelCore

/// Factory boundary for the host's typed Provider graph.
@MainActor
public protocol ProviderFactory {
    func makeRootContainer(composition: RootContainer.Composition) throws -> RootContainer
}

@MainActor
public struct DefaultProviderFactory: ProviderFactory {
    public init() {}

    public func makeRootContainer(composition: RootContainer.Composition) throws -> RootContainer {
        RootContainer(composition: composition)
    }
}
