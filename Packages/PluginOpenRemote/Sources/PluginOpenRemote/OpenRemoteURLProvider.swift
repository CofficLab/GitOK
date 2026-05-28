import Foundation
import ProjectRulesKit

public enum OpenRemoteURLProvider {
    public static func webURL(for projectURL: URL) async -> URL? {
        guard let remoteURL = await GitOriginRemoteReader.originRemoteURL(for: projectURL) else {
            return nil
        }
        return RemoteRepositoryFormRules.remoteWebLink(for: remoteURL)?.url
    }

    public static func webURL(forRemoteURL remoteURL: String?) -> URL? {
        guard let remoteURL else { return nil }
        return RemoteRepositoryFormRules.remoteWebLink(for: remoteURL)?.url
    }
}
