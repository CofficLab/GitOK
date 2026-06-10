import AppKit
import Foundation
import GitCoreKit

public struct DiagnosticEntry: Identifiable, Equatable {
    public let id: UUID
    public let date: Date
    public let source: String
    public let operation: String
    public let message: String
    public let projectPath: String?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        source: String,
        operation: String,
        message: String,
        projectPath: String? = nil
    ) {
        self.id = id
        self.date = date
        self.source = source
        self.operation = operation
        self.message = message
        self.projectPath = projectPath
    }
}

@MainActor
public final class DiagnosticsStore: ObservableObject {
    public static let shared = DiagnosticsStore()

    private let cleanExitKey = "Diagnostics.CleanExit"
    private let maxEntries = 20
    private var observers: [NSObjectProtocol] = []

    @Published public private(set) var recentEntries: [DiagnosticEntry] = []
    @Published public private(set) var previousLaunchDidNotExitCleanly = false

    private init() {
        observeFailures()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public func markLaunchStarted() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: cleanExitKey) != nil {
            previousLaunchDidNotExitCleanly = defaults.bool(forKey: cleanExitKey) == false
        }
        defaults.set(false, forKey: cleanExitKey)
    }

    public func markCleanExit() {
        UserDefaults.standard.set(true, forKey: cleanExitKey)
    }

    func record(source: String, operation: String, message: String, projectPath: String? = nil) {
        let entry = DiagnosticEntry(
            source: source,
            operation: operation,
            message: message,
            projectPath: projectPath
        )
        recentEntries.insert(entry, at: 0)
        if recentEntries.count > maxEntries {
            recentEntries.removeLast(recentEntries.count - maxEntries)
        }
    }

    func clear() {
        recentEntries.removeAll()
        previousLaunchDidNotExitCleanly = false
        UserDefaults.standard.set(true, forKey: cleanExitKey)
    }

    public func copyDiagnosticReport() {
        copy(makeDiagnosticReport())
    }

    public func copyLogCommand() {
        copy("log show --predicate 'process == \"GitOK\"' --last 1h --style compact")
    }

    public func openConsole() {
        let consoleURL = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        NSWorkspace.shared.openApplication(at: consoleURL, configuration: NSWorkspace.OpenConfiguration())
    }

    public func openApplicationSupport() {
        let url = GitOKAppPaths.getCurrentAppSupportDir()
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }

    func makeDiagnosticReport() -> String {
        var lines: [String] = []
        lines.append("GitOK Diagnostics")
        lines.append("Generated: \(Self.format(Date()))")
        lines.append("App: \(AppInfo().name) \(AppInfo().version) (\(AppInfo().build))")
        lines.append("macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        lines.append("Git: \(Self.gitVersion())")
        lines.append("Application Support: \(GitOKAppPaths.getCurrentAppSupportDir().path)")
        lines.append("Previous launch clean: \(previousLaunchDidNotExitCleanly ? "No" : "Yes")")
        lines.append("")
        lines.append("Recent failures:")

        if recentEntries.isEmpty {
            lines.append("- None recorded in this session")
        } else {
            for entry in recentEntries {
                let project = entry.projectPath.map { " [\($0)]" } ?? ""
                lines.append("- \(Self.format(entry.date)) \(entry.source).\(entry.operation)\(project): \(entry.message)")
            }
        }

        lines.append("")
        lines.append("Log command:")
        lines.append("log show --predicate 'process == \"GitOK\"' --last 1h --style compact")
        return lines.joined(separator: "\n")
    }

    private func observeFailures() {
        let projectFailure = NotificationCenter.default.addObserver(
            forName: .projectOperationDidFail,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let eventInfo = notification.userInfo?["eventInfo"] as? ProjectEventInfo else { return }
            Task { @MainActor in
                self?.record(
                    source: "Project",
                    operation: eventInfo.operation,
                    message: eventInfo.error?.localizedDescription ?? "Unknown project operation failure",
                    projectPath: eventInfo.project.path
                )
            }
        }

        let appFailure = NotificationCenter.default.addObserver(
            forName: .appError,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let message = notification.userInfo?["message"] as? String
                ?? (notification.object as? Error)?.localizedDescription
                ?? "Unknown app error"
            Task { @MainActor in
                self?.record(source: "App", operation: "error", message: message)
            }
        }

        observers = [projectFailure, appFailure]
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private static func gitVersion() -> String {
        "libgit2 \(GitRuntime.versionString())"
    }

    private static func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
