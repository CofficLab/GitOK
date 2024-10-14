import Foundation
import MagicKit

extension WebContent {
    @objc func setTexts(_ o: String, _ c: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try! encoder.encode([
            "original": o,
            "modified": c,
        ])
        let jsonString = String(data: jsonData, encoding: .utf8)!

        Task {
            try? await run("window.api.setTextsWithObject(\(jsonString))")
        }
    }

    @objc func setOriginal(_ s: String) {
        Task {
            try? await run("window.api.setOriginal(`\(s)`)")
        }
    }

    @objc func setModified(_ s: String) {
        Task {
            try? await run("window.api.setModified(`\(s)`)")
        }
    }

    @objc func getOriginal() {
        Task {
            try? await run("window.api.original")
        }
    }
}
