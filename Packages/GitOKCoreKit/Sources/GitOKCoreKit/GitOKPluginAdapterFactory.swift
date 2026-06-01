@MainActor
public protocol GitOKPluginAdapterFactory {
    func makeAdapter<Plugin: GitOKPlugin>(for plugin: Plugin) -> any SuperPlugin
}

@MainActor
public struct DefaultGitOKPluginAdapterFactory: GitOKPluginAdapterFactory {
    public init() {}

    public func makeAdapter<Plugin: GitOKPlugin>(for plugin: Plugin) -> any SuperPlugin {
        GitOKPluginAdapter(plugin)
    }
}
