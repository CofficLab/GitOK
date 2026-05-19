import AppKit
import Foundation

struct DiagnosticEntry: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let source: String
    let operation: String
    let message: String
    let projectPath: String?

    init(
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
final class DiagnosticsStore: ObservableObject {
    static let shared = DiagnosticsStore()

    private let cleanExitKey = "Diagnostics.CleanExit"
    private let maxEntries = 20
    private var observers: [NSObjectProtocol] = []

    @Published private(set) var recentEntries: [DiagnosticEntry] = []
    @Published private(set) var previousLaunchDidNotExitCleanly = false

    private init() {
        observeFailures()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func markLaunchStarted() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: cleanExitKey) != nil {
            previousLaunchDidNotExitCleanly = defaults.bool(forKey: cleanExitKey) == false
        }
        defaults.set(false, forKey: cleanExitKey)
    }

    func markCleanExit() {
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

    func copyDiagnosticReport() {
        copy(makeDiagnosticReport())
    }

    func copyLogCommand() {
        copy("log show --predicate 'process == \"GitOK\"' --last 1h --style compact")
    }

    func openConsole() {
        let consoleURL = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        NSWorkspace.shared.openApplication(at: consoleURL, configuration: NSWorkspace.OpenConfiguration())
    }

    func openApplicationSupport() {
        let url = AppConfig.getCurrentAppSupportDir()
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
        lines.append("Application Support: \(AppConfig.getCurrentAppSupportDir().path)")
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
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "--version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return output?.isEmpty == false ? output! : "Unavailable"
        } catch {
            return "Unavailable"
        }
    }

    private static func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
