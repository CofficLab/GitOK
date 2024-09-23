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

    func run(_ command: String, at path: String? = nil) throws -> String {
        let verbose = false
        let process = Process()

        if verbose {
            os_log("\(self.label)Run -> \(command)")
        }

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
            os_log(.error, "\(self.label)Run -> \(output)")
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



#Preview {
    AppPreview()
        .frame(width: 800)
}
