import Foundation
import GitCoreKit

@MainActor
public final class GitNetworkSettingsStore: ObservableObject {
    @Published public var httpProxy = ""
    @Published public var httpsProxy = ""
    @Published public var sslVerify = true
    @Published public var sslCAInfo = ""
    @Published public var isLoading = false
    @Published public var isSaving = false
    @Published public var message: String?
    @Published public var errorMessage: String?

    public init() {}

    public func load() {
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

    public func save() {
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
