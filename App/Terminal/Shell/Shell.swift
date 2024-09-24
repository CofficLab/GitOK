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
    
    func run(_ command: String, at path: String? = nil, verbose: Bool = false) throws -> String {
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
            os_log("\(self.label) \(command) -> \(output)")
        }
        
        if process.terminationStatus != 0 {
            throw ShellError.commandFailed(output + "\n" + command)
        }
        
        return output
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
