import Foundation
import OSLog
import SwiftUI

class Shell {
    static var label: String = "🐚 Shell::"
    
    static func pwd() -> String {
        try! Shell.run("pwd")
    }
    
    static func whoami() -> String {
        try! Shell.run("whoami")
    }
    
    static func run(_ command: String, verbose: Bool = false) throws -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let current = task.currentDirectoryURL?.path ?? "-"
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        var isDir: ObjCBool = true
        
        if verbose {
            print("\(self.label)\n\(command)")
        }
        
        if !FileManager.default.fileExists(atPath: current, isDirectory: &isDir) {
            return "不存在这个路径：\(current)"
        }
            
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
            
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if let errorOutput = String(data: errorData, encoding: .utf8), errorOutput.count > 0 {
            os_log("\(self.label)错误")
            print("\(command)")
            os_log(.error, "\(errorOutput)")
            
            throw SmartError.ShellError(output: errorOutput)
        }
            
        if let output = String(data: outputData, encoding: .utf8) {
            if verbose {
                os_log(.debug, "\(self.label)输出：\n\(output)")
            }
            
            return output
        }
        
        return "无输出"
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
