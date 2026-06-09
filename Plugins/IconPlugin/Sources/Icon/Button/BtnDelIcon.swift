
import OSLog
import MagicAlert
import GitOKCoreKit
import SwiftUI

struct BtnDelIcon: View {


    var icon: IconData
    @State private var isDeleting = false

    var body: some View {
        AppButton("删除「\(icon.title)」", systemImage: "trash", style: .destructive, size: .small, isLoading: isDeleting) {
            isDeleting = true
            Task {
                do {
                    try await icon.deleteFromDiskAsync()
                    await MainActor.run {
                        isDeleting = false
                    }
                } catch {
                    await MainActor.run {
                        isDeleting = false
                        os_log(.error, "❌ 删除图标失败: \(error.localizedDescription)")
                        alert_error(error.localizedDescription)
                    }
                }
            }
        }
        .disabled(isDeleting)
    }
}
