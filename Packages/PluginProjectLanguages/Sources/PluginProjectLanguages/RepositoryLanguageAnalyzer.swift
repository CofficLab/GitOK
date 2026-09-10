import Foundation
import KitGit
import ProviderProjectLanguages

struct RepositoryLanguageAnalysisContext: Sendable {
    let cacheKey: ProjectLanguagesCacheKey
    let isWorktreeClean: Bool
}

protocol RepositoryLanguageAnalyzing: Sendable {
    func analyze(repository: URL) throws -> ProjectLanguagesSnapshot
    func context(for repository: URL) throws -> RepositoryLanguageAnalysisContext
}

/// Performs local, source-only language analysis for the current Git tree.
///
/// The analyzer intentionally lives in the implementation plugin rather than
/// the provider contract. This leaves room for a future Linguist-compatible
/// implementation without coupling consumers to a particular detector.
struct RepositoryLanguageAnalyzer: RepositoryLanguageAnalyzing {
    static let cacheVersion = 1

    private struct Definition: Sendable {
        let id: String
        let name: String
        let extensions: Set<String>
        let filenames: Set<String>

        init(
            id: String,
            name: String,
            extensions: Set<String> = [],
            filenames: Set<String> = []
        ) {
            self.id = id
            self.name = name
            self.extensions = extensions
            self.filenames = filenames
        }
    }

    private static let definitions: [Definition] = [
        Definition(id: "swift", name: "Swift", extensions: ["swift"]),
        Definition(id: "objective-c", name: "Objective-C", extensions: ["m"]),
        Definition(id: "objective-cpp", name: "Objective-C++", extensions: ["mm"]),
        Definition(id: "cpp", name: "C++", extensions: ["cc", "cpp", "cxx", "hpp", "hh", "hxx", "h"]),
        Definition(id: "c", name: "C", extensions: ["c"]),
        Definition(id: "csharp", name: "C#", extensions: ["cs"]),
        Definition(id: "java", name: "Java", extensions: ["java"]),
        Definition(id: "kotlin", name: "Kotlin", extensions: ["kt", "kts"]),
        Definition(id: "go", name: "Go", extensions: ["go"]),
        Definition(id: "rust", name: "Rust", extensions: ["rs"]),
        Definition(id: "python", name: "Python", extensions: ["py", "pyw"]),
        Definition(id: "ruby", name: "Ruby", extensions: ["rb", "rake"], filenames: ["rakefile", "gemfile"]),
        Definition(id: "php", name: "PHP", extensions: ["php"]),
        Definition(id: "javascript", name: "JavaScript", extensions: ["js", "mjs", "cjs"]),
        Definition(id: "typescript", name: "TypeScript", extensions: ["ts"]),
        Definition(id: "jsx", name: "JSX", extensions: ["jsx"]),
        Definition(id: "tsx", name: "TSX", extensions: ["tsx"]),
        Definition(id: "vue", name: "Vue", extensions: ["vue"]),
        Definition(id: "html", name: "HTML", extensions: ["html", "htm"]),
        Definition(id: "css", name: "CSS", extensions: ["css"]),
        Definition(id: "scss", name: "SCSS", extensions: ["scss", "sass"]),
        Definition(id: "shell", name: "Shell", extensions: ["sh", "bash", "zsh", "fish"], filenames: ["bashrc", "zshrc"]),
        Definition(id: "sql", name: "SQL", extensions: ["sql"]),
        Definition(id: "dart", name: "Dart", extensions: ["dart"]),
        Definition(id: "lua", name: "Lua", extensions: ["lua"]),
        Definition(id: "r", name: "R", extensions: ["r"]),
        Definition(id: "markdown", name: "Markdown", extensions: ["md", "markdown", "mdown"]),
        Definition(id: "json", name: "JSON", extensions: ["json", "jsonc"]),
        Definition(id: "yaml", name: "YAML", extensions: ["yml", "yaml"]),
        Definition(id: "xml", name: "XML", extensions: ["xml", "plist", "xib", "storyboard"]),
        Definition(id: "toml", name: "TOML", extensions: ["toml"]),
        Definition(id: "makefile", name: "Makefile", filenames: ["makefile", "gnumakefile"]),
        Definition(id: "dockerfile", name: "Dockerfile", filenames: ["dockerfile"]),
    ]

    private static let definitionsByExtension: [String: Definition] = {
        var result: [String: Definition] = [:]
        for definition in definitions {
            for fileExtension in definition.extensions {
                result[fileExtension] = definition
            }
        }
        return result
    }()

    private static let definitionsByFilename: [String: Definition] = {
        var result: [String: Definition] = [:]
        for definition in definitions {
            for filename in definition.filenames {
                result[filename] = definition
            }
        }
        return result
    }()

    private static let excludedDirectories: Set<String> = [
        ".build", "build", "carthage", "coverage", "deriveddata", "dist",
        "node_modules", "pods", "target", "vendor", "vendors"
    ]

    func context(for repository: URL) throws -> RepositoryLanguageAnalysisContext {
        let repository = repository.standardizedFileURL
        let headHash = try GitProcessRunner.run(["rev-parse", "HEAD"], in: repository)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !headHash.isEmpty else {
            throw GitProcessRunner.Error.gitFailed("Repository has no HEAD")
        }

        let status = try GitStatusLoader.loadStatus(in: repository)
        return RepositoryLanguageAnalysisContext(
            cacheKey: ProjectLanguagesCacheKey(
                repositoryPath: repository.path,
                headHash: headHash,
                analyzerVersion: Self.cacheVersion
            ),
            isWorktreeClean: status.isClean
        )
    }

    func analyze(repository: URL) throws -> ProjectLanguagesSnapshot {
        let output = try GitProcessRunner.run(
            ["ls-tree", "-r", "--name-only", "-z", "HEAD"],
            in: repository
        )
        let fileManager = FileManager.default
        var byteCounts: [String: (name: String, bytes: Int64)] = [:]

        for rawPath in output.split(separator: "\0", omittingEmptySubsequences: true) {
            let path = String(rawPath)
            guard !isExcluded(path),
                  let definition = Self.definition(for: path) else { continue }

            let fileURL = repository.appendingPathComponent(path)
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let type = attributes[.type] as? FileAttributeType,
                  type == .typeRegular,
                  let size = (attributes[.size] as? NSNumber)?.int64Value,
                  size > 0,
                  !isBinary(fileURL) else { continue }

            byteCounts[definition.id, default: (definition.name, 0)].bytes += size
        }

        return ProjectLanguagesSnapshot(
            repositoryPath: repository.standardizedFileURL.path,
            languages: byteCounts.map { id, value in
                ProjectLanguage(id: id, name: value.name, byteCount: value.bytes)
            }
        )
    }

    private static func definition(for path: String) -> Definition? {
        let filename = URL(fileURLWithPath: path).lastPathComponent.lowercased()
        if let definition = definitionsByFilename[filename] {
            return definition
        }
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        return definitionsByExtension[fileExtension]
    }

    private func isExcluded(_ path: String) -> Bool {
        path.split(separator: "/").contains { component in
            Self.excludedDirectories.contains(component.lowercased())
        }
    }

    private func isBinary(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return true }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 8 * 1024) else { return true }
        return data.contains(0)
    }
}
