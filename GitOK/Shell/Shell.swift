import Foundation
import SwiftUI
import OSLog

class Shell {
    static var label: String = "🐚 Shell::"
    
    static func pwd() -> String {
        try! Shell.run("pwd")
    }
    
    static func whoami() -> String {
        try! Shell.run("whoami")
    }
    
    static func run(_ command: String, debugPrint: Bool = false) throws -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let current = task.currentDirectoryURL?.path ?? "-"
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        var isDir: ObjCBool = true
        
        print("\(self.label)")
        print("\(command)")
        print("\n")
        
        if !FileManager.default.fileExists(atPath: current, isDirectory: &isDir) {
            return "不存在这个路径：\(current)"
        }
            
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
            
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        
        if let errorOutput = String(data: errorData, encoding: .utf8), errorOutput.count > 0 {
            if debugPrint {
                os_log("\(self.label)错误：")
                print(errorOutput)
            }
            
            throw SmartError.ShellError(output: errorOutput)
        }
            
        if let output = String(data: outputData, encoding: .utf8) {
            if debugPrint {
                print("\(self.label)输出：\n---\n\(output)---\n")
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
