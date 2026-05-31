import Foundation
import GitCoreKit

@MainActor
final class GitNetworkSettingsStore: ObservableObject {
    @Published var httpProxy = ""
    @Published var httpsProxy = ""
    @Published var sslVerify = true
    @Published var sslCAInfo = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var message: String?
    @Published var errorMessage: String?

    func load() {
        isLoading = true
        errorMessage = nil
        message = nil

        Task.detached(priority: .userInitiated) {
            let result = Result { try CloneRepositoryValidation.loadGlobalNetworkConfiguration() }

            await MainActor.run {
                self.isLoading = false

                switch result {
                case let .success(configuration):
                    self.httpProxy = configuration.httpProxy
                    self.httpsProxy = configuration.httpsProxy
                    self.sslVerify = configuration.sslVerify
                    self.sslCAInfo = configuration.sslCAInfo
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func save() {
        isSaving = true
        errorMessage = nil
        message = nil

        let configuration = CloneRepositoryValidation.NetworkConfiguration(
            httpProxy: httpProxy,
            httpsProxy: httpsProxy,
            sslVerify: sslVerify,
            sslCAInfo: sslCAInfo
        )

        Task.detached(priority: .userInitiated) {
            let result = Result { try CloneRepositoryValidation.saveGlobalNetworkConfiguration(configuration) }

            await MainActor.run {
                self.isSaving = false

                switch result {
                case .success:
                    self.message = "Git 网络配置已保存"
                    self.load()
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
