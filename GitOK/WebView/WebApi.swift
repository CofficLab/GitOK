import Foundation

extension WebContent {
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
