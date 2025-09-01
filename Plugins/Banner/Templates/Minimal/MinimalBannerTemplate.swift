import SwiftUI
import AppKit

/**
 简约模板
 居中简洁的布局风格
 */
struct MinimalBannerTemplate: BannerTemplateProtocol {
    let id = "minimal"
    let name = "简约风格"
    let description = "居中布局，简洁优雅"
    let systemImageName = "rectangle.center.inset.filled"
    
    func createPreviewView(device: Device) -> AnyView {
        AnyView(
            MinimalBannerLayout(device: device)
                .environmentObject(BannerProvider.shared)
        )
    }
    
    func createModifierView() -> AnyView {
        AnyView(MinimalBannerModifiers())
    }
    
    func createExampleView() -> AnyView {
        AnyView(MinimalBannerExampleView())
    }
    
    func getDefaultData() -> Any {
        return MinimalBannerData()
    }
    
    func restoreData(from bannerData: BannerData) -> Any {
        // 首先从通用字段恢复基本数据
        var minimalData = MinimalBannerData(
            title: bannerData.title,
            subtitle: bannerData.subTitle,
            backgroundId: bannerData.backgroundId,
            opacity: bannerData.opacity,
            titleColor: bannerData.titleColor,
            subtitleColor: bannerData.subTitleColor
        )
        
        // 然后从模板特定数据恢复额外属性
        if let templateDataString = bannerData.templateData,
           let templateData = templateDataString.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                let storedData = try decoder.decode(MinimalBannerData.self, from: templateData)
                // 只恢复模板特有的属性，保持基本属性不变
                minimalData.titleSize = storedData.titleSize
                minimalData.subtitleSize = storedData.subtitleSize
                minimalData.titleWeightRaw = storedData.titleWeightRaw
                minimalData.subtitleWeightRaw = storedData.subtitleWeightRaw
                minimalData.spacing = storedData.spacing
            } catch {
                // 如果解析失败，使用默认值
                print("Failed to restore minimal template data: \(error)")
            }
        }
        
        return minimalData
    }
    
    func saveData(_ templateData: Any, to bannerData: inout BannerData) throws {
        guard let minimalData = templateData as? MinimalBannerData else {
            throw BannerError.invalidTemplateData
        }
        
        // 保存通用字段
        bannerData.title = minimalData.title
        bannerData.subTitle = minimalData.subtitle
        bannerData.backgroundId = minimalData.backgroundId
        bannerData.opacity = minimalData.opacity
        bannerData.titleColor = minimalData.titleColor
        bannerData.subTitleColor = minimalData.subtitleColor
        
        // 保存模板特定数据为JSON
        do {
            let encoder = JSONEncoder()
            let templateData = try encoder.encode(minimalData)
            bannerData.templateData = String(data: templateData, encoding: .utf8)
        } catch {
            throw BannerError.invalidTemplateData
        }
    }
}

/**
 简约模板的数据模型
 */
struct MinimalBannerData: Codable {
    var title: String = "App Title"
    var subtitle: String = "Simple and Clean"
    var backgroundId: String = "1"
    var opacity: Double = 1.0
    var titleColor: Color? = nil
    var subtitleColor: Color? = nil
    
    // 简约模板特有的属性
    var titleSize: Double = 36.0
    var subtitleSize: Double = 18.0
    var titleWeightRaw: String = "bold"  // 存储为字符串，因为Font.Weight不是Codable
    var subtitleWeightRaw: String = "medium"
    var spacing: Double = 8.0
    
    // 用于Codable的私有属性
    private var titleColorData: Data? = nil
    private var subtitleColorData: Data? = nil
    
    // 计算属性，用于获取Font.Weight
    var titleWeight: Font.Weight {
        get { Font.Weight.fromString(titleWeightRaw) }
        set { titleWeightRaw = newValue.toString() }
    }
    
    var subtitleWeight: Font.Weight {
        get { Font.Weight.fromString(subtitleWeightRaw) }
        set { subtitleWeightRaw = newValue.toString() }
    }
    
    init(
        title: String = "App Title",
        subtitle: String = "Simple and Clean",
        backgroundId: String = "1",
        opacity: Double = 1.0,
        titleColor: Color? = nil,
        subtitleColor: Color? = nil,
        titleSize: Double = 36.0,
        subtitleSize: Double = 18.0,
        titleWeight: Font.Weight = .bold,
        subtitleWeight: Font.Weight = .medium,
        spacing: Double = 8.0
    ) {
        self.title = title
        self.subtitle = subtitle
        self.backgroundId = backgroundId
        self.opacity = opacity
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.titleSize = titleSize
        self.subtitleSize = subtitleSize
        self.titleWeightRaw = titleWeight.toString()
        self.subtitleWeightRaw = subtitleWeight.toString()
        self.spacing = spacing
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case backgroundId
        case opacity
        case titleSize
        case subtitleSize
        case titleWeightRaw
        case subtitleWeightRaw
        case spacing
        case titleColorData
        case subtitleColorData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        backgroundId = try container.decode(String.self, forKey: .backgroundId)
        opacity = try container.decode(Double.self, forKey: .opacity)
        titleSize = try container.decode(Double.self, forKey: .titleSize)
        subtitleSize = try container.decode(Double.self, forKey: .subtitleSize)
        titleWeightRaw = try container.decode(String.self, forKey: .titleWeightRaw)
        subtitleWeightRaw = try container.decode(String.self, forKey: .subtitleWeightRaw)
        spacing = try container.decode(Double.self, forKey: .spacing)
        titleColorData = try container.decodeIfPresent(Data.self, forKey: .titleColorData)
        subtitleColorData = try container.decodeIfPresent(Data.self, forKey: .subtitleColorData)
        
        // 从Data恢复Color
        if let titleColorData = titleColorData {
            if let nsColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: titleColorData) {
                titleColor = Color(nsColor)
            } else {
                titleColor = nil
            }
        } else {
            titleColor = nil
        }
        
        if let subtitleColorData = subtitleColorData {
            if let nsColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: subtitleColorData) {
                subtitleColor = Color(nsColor)
            } else {
                subtitleColor = nil
            }
        } else {
            subtitleColor = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(backgroundId, forKey: .backgroundId)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(titleSize, forKey: .titleSize)
        try container.encode(subtitleSize, forKey: .subtitleSize)
        try container.encode(titleWeightRaw, forKey: .titleWeightRaw)
        try container.encode(subtitleWeightRaw, forKey: .subtitleWeightRaw)
        try container.encode(spacing, forKey: .spacing)
        
        // 将Color转换为Data存储
        if let titleColor = titleColor {
            let nsColor = NSColor(titleColor)
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false)
            try container.encode(colorData, forKey: .titleColorData)
        }
        
        if let subtitleColor = subtitleColor {
            let nsColor = NSColor(subtitleColor)
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false)
            try container.encode(colorData, forKey: .subtitleColorData)
        }
    }
}

// MARK: - Font.Weight Extensions

extension Font.Weight {
    func toString() -> String {
        switch self {
        case .ultraLight: return "ultraLight"
        case .thin: return "thin"
        case .light: return "light"
        case .regular: return "regular"
        case .medium: return "medium"
        case .semibold: return "semibold"
        case .bold: return "bold"
        case .heavy: return "heavy"
        case .black: return "black"
        default: return "regular"
        }
    }
    
    static func fromString(_ string: String) -> Font.Weight {
        switch string {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
