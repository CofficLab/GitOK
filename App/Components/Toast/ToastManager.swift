import SwiftUI
import Combine

// MARK: - Toast类型定义
enum ToastType {
    case info
    case success
    case warning
    case error
    case loading
    case custom(systemImage: String, color: Color)
    
    var systemImage: String {
        switch self {
        case .info:
            return "info.circle"
        case .success:
            return "checkmark.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        case .loading:
            return "arrow.clockwise"
        case .custom(let systemImage, _):
            return systemImage
        }
    }
    
    var color: Color {
        switch self {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .loading:
            return .gray
        case .custom(_, let color):
            return color
        }
    }
}

// MARK: - 显示模式
enum ToastDisplayMode {
    case overlay       // 覆盖层显示在屏幕中央
    case banner        // 横幅从顶部滑下
    case bottom        // 从底部弹出
    case corner        // 在角落显示
}

// MARK: - Toast模型
struct ToastModel: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let subtitle: String?
    let displayMode: ToastDisplayMode
    let duration: TimeInterval
    let autoDismiss: Bool
    let tapToDismiss: Bool
    let showProgress: Bool
    let onTap: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(
        type: ToastType,
        title: String,
        subtitle: String? = nil,
        displayMode: ToastDisplayMode = .overlay,
        duration: TimeInterval = 3.0,
        autoDismiss: Bool = true,
        tapToDismiss: Bool = true,
        showProgress: Bool = false,
        onTap: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.displayMode = displayMode
        self.duration = duration
        self.autoDismiss = autoDismiss
        self.tapToDismiss = tapToDismiss
        self.showProgress = showProgress
        self.onTap = onTap
        self.onDismiss = onDismiss
    }
    
    static func == (lhs: ToastModel, rhs: ToastModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast管理器
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published private(set) var toasts: [ToastModel] = []
    private var timers: [UUID: Timer] = [:]
    
    private init() {}
    
    // MARK: - 显示Toast
    func show(_ toast: ToastModel) {
        DispatchQueue.main.async {
            // 移除相同类型的已存在toast（可选）
            self.toasts.removeAll { existingToast in
                existingToast.type.systemImage == toast.type.systemImage && 
                existingToast.title == toast.title
            }
            
            self.toasts.append(toast)
            
            // 设置自动消失
            if toast.autoDismiss && toast.duration > 0 {
                let timer = Timer.scheduledTimer(withTimeInterval: toast.duration, repeats: false) { _ in
                    self.dismiss(toast.id)
                }
                self.timers[toast.id] = timer
            }
        }
    }
    
    // MARK: - 便捷方法
    func info(_ title: String, subtitle: String? = nil, duration: TimeInterval = 3.0) {
        let toast = ToastModel(
            type: .info,
            title: title,
            subtitle: subtitle,
            duration: duration
        )
        show(toast)
    }
    
    func success(_ title: String, subtitle: String? = nil, duration: TimeInterval = 3.0) {
        let toast = ToastModel(
            type: .success,
            title: title,
            subtitle: subtitle,
            duration: duration
        )
        show(toast)
    }
    
    func warning(_ title: String, subtitle: String? = nil, duration: TimeInterval = 4.0) {
        let toast = ToastModel(
            type: .warning,
            title: title,
            subtitle: subtitle,
            duration: duration
        )
        show(toast)
    }
    
    func error(_ title: String, subtitle: String? = nil, duration: TimeInterval = 0, autoDismiss: Bool = false) {
        let toast = ToastModel(
            type: .error,
            title: title,
            subtitle: subtitle,
            displayMode: .banner,
            duration: duration,
            autoDismiss: autoDismiss,
            tapToDismiss: true
        )
        show(toast)
    }
    
    func loading(_ title: String, subtitle: String? = nil, showProgress: Bool = true) {
        let toast = ToastModel(
            type: .loading,
            title: title,
            subtitle: subtitle,
            duration: 0,
            autoDismiss: false,
            tapToDismiss: false,
            showProgress: showProgress
        )
        show(toast)
    }
    
    func custom(
        systemImage: String,
        color: Color,
        title: String,
        subtitle: String? = nil,
        displayMode: ToastDisplayMode = .overlay,
        duration: TimeInterval = 3.0
    ) {
        let toast = ToastModel(
            type: .custom(systemImage: systemImage, color: color),
            title: title,
            subtitle: subtitle,
            displayMode: displayMode,
            duration: duration
        )
        show(toast)
    }
    
    // MARK: - 消失Toast
    func dismiss(_ id: UUID) {
        DispatchQueue.main.async {
            if let index = self.toasts.firstIndex(where: { $0.id == id }) {
                let toast = self.toasts[index]
                self.toasts.remove(at: index)
                
                // 清理定时器
                self.timers[id]?.invalidate()
                self.timers.removeValue(forKey: id)
                
                // 调用回调
                toast.onDismiss?()
            }
        }
    }
    
    func dismissAll() {
        DispatchQueue.main.async {
            self.toasts.removeAll()
            
            // 清理所有定时器
            self.timers.values.forEach { $0.invalidate() }
            self.timers.removeAll()
        }
    }
    
    // MARK: - 查找加载中的Toast
    func dismissLoading() {
        let loadingToasts = toasts.filter { 
            if case .loading = $0.type { return true }
            return false
        }
        
        loadingToasts.forEach { dismiss($0.id) }
    }
} 