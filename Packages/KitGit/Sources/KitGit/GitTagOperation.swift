import Foundation

/// Git tag 的创建、删除和远程维护操作。
public enum GitTagOperation {
    public enum Error: Swift.Error, LocalizedError {
        case invalidName
        case invalidCommit
        case invalidMessage
        case invalidRemote
        case createFailed(String)
        case deleteFailed(String)
        case pushFailed(String)
        case deleteRemoteFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidName:
                pluginLocalization.string("A valid tag name is required.")
            case .invalidCommit:
                pluginLocalization.string("A commit is required for the tag.")
            case .invalidMessage:
                pluginLocalization.string("An annotated tag message is required.")
            case .invalidRemote:
                pluginLocalization.string("A remote name is required for the tag.")
            case .createFailed(let message):
                String(format: pluginLocalization.string("Tag creation failed: %@"), message)
            case .deleteFailed(let message):
                String(format: pluginLocalization.string("Tag deletion failed: %@"), message)
            case .pushFailed(let message):
                String(format: pluginLocalization.string("Tag push failed: %@"), message)
            case .deleteRemoteFailed(let message):
                String(format: pluginLocalization.string("Remote tag deletion failed: %@"), message)
            }
        }
    }

    @discardableResult
    public static func createLightweight(
        named name: String,
        at commitHash: String,
        in repository: URL
    ) throws -> String {
        let tagName = try validatedName(name, in: repository)
        let hash = try validatedCommit(commitHash)

        do {
            _ = try GitProcessRunner.run(["rev-parse", "--verify", "\(hash)^{commit}"], in: repository)
            return try GitProcessRunner.run(["tag", tagName, hash], in: repository)
        } catch let error as Error {
            throw error
        } catch {
            throw Error.createFailed(Self.message(for: error))
        }
    }

    @discardableResult
    public static func createAnnotated(
        named name: String,
        at commitHash: String,
        message: String,
        in repository: URL
    ) throws -> String {
        let tagName = try validatedName(name, in: repository)
        let hash = try validatedCommit(commitHash)
        let tagMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tagMessage.isEmpty else { throw Error.invalidMessage }

        do {
            _ = try GitProcessRunner.run(["rev-parse", "--verify", "\(hash)^{commit}"], in: repository)
            return try GitProcessRunner.run(["tag", "-a", tagName, hash, "-m", tagMessage], in: repository)
        } catch let error as Error {
            throw error
        } catch {
            throw Error.createFailed(Self.message(for: error))
        }
    }

    @discardableResult
    public static func deleteLocal(named name: String, in repository: URL) throws -> String {
        let tagName = try validatedName(name, in: repository)
        do {
            return try GitProcessRunner.run(["tag", "-d", tagName], in: repository)
        } catch let error as Error {
            throw error
        } catch {
            throw Error.deleteFailed(Self.message(for: error))
        }
    }

    @discardableResult
    public static func push(
        named name: String,
        remote: String = "origin",
        in repository: URL
    ) throws -> String {
        let tagName = try validatedName(name, in: repository)
        let remoteName = try validatedRemote(remote)
        do {
            return try GitProcessRunner.run(
                ["push", remoteName, "refs/tags/\(tagName)"],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            throw Error.pushFailed(Self.message(for: error))
        }
    }

    @discardableResult
    public static func deleteRemote(
        named name: String,
        remote: String = "origin",
        in repository: URL
    ) throws -> String {
        let tagName = try validatedName(name, in: repository)
        let remoteName = try validatedRemote(remote)
        do {
            return try GitProcessRunner.run(
                ["push", remoteName, "--delete", "refs/tags/\(tagName)"],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            throw Error.deleteRemoteFailed(Self.message(for: error))
        }
    }

    private static func validatedName(_ name: String, in repository: URL) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Error.invalidName }
        do {
            _ = try GitProcessRunner.run(["check-ref-format", "refs/tags/\(trimmed)"], in: repository)
        } catch {
            throw Error.invalidName
        }
        return trimmed
    }

    private static func validatedCommit(_ hash: String) throws -> String {
        let trimmed = hash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Error.invalidCommit }
        return trimmed
    }

    private static func validatedRemote(_ remote: String) throws -> String {
        let trimmed = remote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Error.invalidRemote }
        return trimmed
    }

    private static func message(for error: Swift.Error) -> String {
        (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
    }
}
