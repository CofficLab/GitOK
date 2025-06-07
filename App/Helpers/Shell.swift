import Foundation
import OSLog
import SwiftUI
import MagicCore

class Shell: SuperLog {
    static let emoji = "🐚"

    static func pwd() -> String {
        do {
            return try self.run("pwd")
        } catch {
            return error.localizedDescription
        }
    }

    static func whoami() -> String {
        do {
            return try self.run("whoami")
        } catch {
            return error.localizedDescription
        }
    }

    static func run(_ command: String, at path: String? = nil, verbose: Bool = false) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]

        if let path = path {
            process.currentDirectoryURL = URL(fileURLWithPath: path)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let outputHandle = pipe.fileHandleForReading
        var outputData = Data()

        outputHandle.readabilityHandler = { handle in
            outputData.append(handle.availableData)
        }

        try process.run()
        process.waitUntilExit()

        outputHandle.readabilityHandler = nil

        let output = String(data: outputData, encoding: .utf8) ?? ""

        if verbose {
            os_log("\(self.t)\(command)")
            os_log("\(output)")
        }

        if process.terminationStatus != 0 {
            throw ShellError.commandFailed(output + "\n" + command)
        }

        return output
    }

    static func configureGitCredentialCache() -> String {
        do {
            return try self.run("git config --global credential.helper cache")
        } catch {
            return error.localizedDescription
        }
    }
}

// MARK: File

extension Shell {
    func isDirExists(_ dir: String) -> Bool {
        try! Shell.run("""
            if [ ! -d "\(dir)" ]; then
                echo "false"
            else
                echo "true"
            fi
        """) == "true"
    }

    func makeDir(_ dir: String, verbose: Bool = true) {
        if verbose {
            os_log("\(self.t)MakeDir -> \(dir)")
        }

        _ = try! Shell.run("""
            if [ ! -d "\(dir)" ]; then
                mkdir -p "\(dir)"
            else
                echo "\(dir) 已经存在"
            fi
        """)
    }

    func makeFile(_ path: String, content: String) {
        _ = try! Shell.run("""
            echo "\(content)" > \(path)
        """)
    }

    func getFileContent(_ path: String) throws -> String {
        try Shell.run("cat \(path)")
    }
}

enum ShellError: Error, LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(output):
            return "Command failed with output: \(output)"
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
