import Foundation

extension WebContent {
    @objc func setTexts(_ o: String, _ c: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try! encoder.encode([
            "original": o,
            "modified": c
        ])
        let jsonString = String(data: jsonData, encoding: .utf8)!

        run("window.api.setTextsWithObject(\(jsonString))")
    }
    
    @objc func setOriginal(_ s: String) {
        run("window.api.setOriginal(`\(s)`)")
    }
    
    @objc func setModified(_ s: String) {
        run("window.api.setModified(`\(s)`)")
    }
    
    @objc func getOriginal() {
        run("window.api.original")
    }
}
