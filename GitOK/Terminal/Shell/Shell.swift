import Foundation
import OSLog
import SwiftUI

class Shell {
    var label = "🐚 Shell::"
    
    func pwd() -> String {
        do {
            return try self.run("pwd")
        } catch {
            return error.localizedDescription
        }
    }
    
    func whoami() -> String {
        do {
            return try self.run("whoami")
        } catch {
            return error.localizedDescription
        }
    }

    @discardableResult
    func run(_ command: String, at path: String? = nil) throws -> String {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", command]
        
        if let path = path {
            process.currentDirectoryPath = path
        }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.launch()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if process.terminationStatus != 0 {
            throw ShellError.commandFailed(output)
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func configureGitCredentialCache() -> String {
        do {
            return try self.run("git config --global credential.helper cache")
        } catch {
            return error.localizedDescription
        }
    }
}

enum ShellError: Error {
    case commandFailed(String)
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
