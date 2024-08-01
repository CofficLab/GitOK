import Foundation
import SwiftUI

enum SmartError: Error,LocalizedError {
    case ShellError(output: String)
    
    var errorDescription: String? {
        switch self {
        case .ShellError(let output):
            output
        }
    }
}

#Preview {
    AppPreview()
}
