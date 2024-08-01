import Foundation
import OSLog
import SwiftUI

extension Shell {
    static func isDirExists(_ dir: String) -> Bool {
        try! Shell.run("""
            if [ ! -d "\(dir)" ]; then
                echo "false"
            else
                echo "true"
            fi
        """) == "true"
    }
    
    static func makeDir(_ dir: String, verbose: Bool = true) {
        if verbose {
            os_log("\(self.label)MakeDir -> \(dir)")
        }
        
        _ = try! Shell.run("""
            if [ ! -d "\(dir)" ]; then
                mkdir -p "\(dir)"
            else
                echo "\(dir) 已经存在"
            fi
        """)
    }
    
    static func makeFile(_ path: String, content: String) {
        try! Shell.run("""
            echo "\(content)" > \(path)
        """)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
