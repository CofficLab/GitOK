import GitOKFoundationKit
import GitOKDesignKit
import Foundation
import OSLog
import SwiftUI
import UniformTypeIdentifiers

/// 封面设置视图模型
///
/// 负责处理媒体文件封面的设置逻辑，包括图片选择、验证和写入。
/// 与 UI 完全分离，便于测试和复用。
@MainActor
public final class CoverArtViewModel: ObservableObject {
    // MARK: - Published Properties

    /// 是否显示图片选择器
    @Published public var isImagePickerPresented = false

    /// 是否正在处理
    @Published public var isProcessing = false

    /// 错误信息
    @Published public var errorMessage: String?

    // MARK: - Properties

    /// 目标文件 URL
    private let targetURL: URL

    /// 是否启用详细日志
    private let verbose: Bool

    /// 完成回调
    public var onCompletion: (() -> Void)?

    /// 错误回调
    public var onError: ((Error) -> Void)?

    private let maxImageDataSize = 10 * 1024 * 1024
    private var processImageTask: Task<Void, Never>?
    private var currentProcessingID: UUID?

    // MARK: - Initialization

    /// 创建封面设置视图模型
    /// - Parameters:
    ///   - targetURL: 要设置封面的目标文件 URL
    ///   - verbose: 是否启用详细日志，默认为 false
    public init(targetURL: URL, verbose: Bool = false) {
        self.targetURL = targetURL
        self.verbose = verbose
    }

    deinit {
        processImageTask?.cancel()
    }

    // MARK: - Public Methods

    /// 显示图片选择器
    public func selectImage() {
        if verbose {
            os_log("📸 准备选择封面图片")
        }
        isImagePickerPresented = true
    }

    /// 处理图片选择结果
    /// - Parameter result: 文件选择器的结果
    public func handleImageSelection(result: Result<[URL], Error>) {
        switch result {
        case let .success(files):
            guard let selectedURL = files.first else {
                if verbose {
                    os_log("⚠️ 未选择文件")
                }
                return
            }

            processImageTask?.cancel()
            let processingID = UUID()
            currentProcessingID = processingID
            processImageTask = Task { [weak self] in
                guard let self else { return }
                await processSelectedImage(at: selectedURL, processingID: processingID)
            }

        case let .failure(error):
            if verbose {
                os_log(.error, "❌ 选择图片失败: \(error.localizedDescription)")
            }
            handleError(error)
        }
    }

    // MARK: - Private Methods

    /// 处理选中的图片
    /// - Parameter selectedURL: 选中的图片 URL
    private func processSelectedImage(at selectedURL: URL, processingID: UUID) async {
        guard currentProcessingID == processingID, Task.isCancelled == false else { return }
        isProcessing = true
        errorMessage = nil

        defer {
            if currentProcessingID == processingID {
                isProcessing = false
                isImagePickerPresented = false
                processImageTask = nil
                currentProcessingID = nil
            }
        }

        do {
            if verbose {
                os_log("🎨 开始设置封面：\(selectedURL.lastPathComponent)")
            }

            // 1. 验证文件类型
            guard selectedURL.isImage else {
                throw CoverArtError.invalidFileType
            }

            // 2. 获取文件的安全访问权限
            guard selectedURL.startAccessingSecurityScopedResource() else {
                throw CoverArtError.accessDenied
            }

            defer {
                // 完成后释放访问权限
                selectedURL.stopAccessingSecurityScopedResource()
            }

            // 3. 先检查文件大小，避免超大图片先被完整读入内存
            try validateImageFileSize(selectedURL)

            guard Task.isCancelled == false else { return }

            // 4. 读取图片数据
            let imageData = try Data(contentsOf: selectedURL)

            guard Task.isCancelled == false else { return }

            // 5. 验证图片数据
            try validateImageData(imageData)

            // 6. 写入封面到媒体文件
            try await targetURL.writeCoverToMediaFile(
                imageData: imageData,
                imageType: detectedImageType(for: selectedURL),
                verbose: verbose
            )

            guard currentProcessingID == processingID, Task.isCancelled == false else { return }

            if verbose {
                os_log("✅ 封面设置成功")
            }

            // 通知完成
            onCompletion?()

        } catch {
            if verbose {
                os_log(.error, "❌ 设置封面失败: \(error.localizedDescription)")
            }
            if currentProcessingID == processingID {
                handleError(error)
            }
        }
    }

    private func validateImageFileSize(_ url: URL) throws {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey])
        let fileSize = values?.fileSize ?? values?.totalFileAllocatedSize ?? 0
        if fileSize > maxImageDataSize {
            throw CoverArtError.fileTooLarge
        }
    }

    /// 验证图片数据
    /// - Parameter imageData: 图片数据
    /// - Throws: 如果数据无效则抛出错误
    private func validateImageData(_ imageData: Data) throws {
        // 检查数据大小（限制为 10MB）
        if imageData.count > maxImageDataSize {
            throw CoverArtError.fileTooLarge
        }

        // 检查是否为有效图片（简单验证）
        guard imageData.count > 0 else {
            throw CoverArtError.invalidImageData
        }
    }

    /// 检测图片类型
    /// - Parameter url: 图片文件 URL
    /// - Returns: MIME 类型
    private func detectedImageType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "png":
            return "image/png"
        case "gif", "webp":
            return "image/\(ext)"
        default: // jpg, jpeg
            return "image/jpeg"
        }
    }

    /// 处理错误
    /// - Parameter error: 错误对象
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        onError?(error)
    }
}

// MARK: - Errors

/// 封面设置相关错误
public enum CoverArtError: LocalizedError {
    case invalidFileType
    case accessDenied
    case fileTooLarge
    case invalidImageData

    public var errorDescription: String? {
        switch self {
        case .invalidFileType:
            return "请选择图片文件"
        case .accessDenied:
            return "无法访问选中的文件"
        case .fileTooLarge:
            return "图片文件过大（最大 10MB）"
        case .invalidImageData:
            return "无效的图片数据"
        }
    }
}

// MARK: - Preview
