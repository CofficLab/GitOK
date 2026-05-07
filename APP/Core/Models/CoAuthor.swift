import Foundation

/// 合作者数据模型
struct CoAuthor: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var email: String

    init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }

    /// 生成 Co-authored-by 格式的字符串
    /// 格式: Co-authored-by: name <email>
    var coAuthoredByLine: String {
        "Co-authored-by: \(name) <\(email)>"
    }

    /// 显示文本
    var displayText: String {
        "\(name) <\(email)>"
    }
}

/// 合作者存储管理器
class CoAuthorStore {
    static let shared = CoAuthorStore()

    private let userDefaultsKey = "GitOK_CoAuthors"

    private init() {}

    /// 保存合作者列表
    func saveCoAuthors(_ coauthors: [CoAuthor]) {
        if let data = try? JSONEncoder().encode(coauthors) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    /// 加载合作者列表
    func loadCoAuthors() -> [CoAuthor] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let coauthors = try? JSONDecoder().decode([CoAuthor].self, from: data) else {
            return []
        }
        return coauthors
    }

    /// 添加合作者
    func addCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        // 检查是否已存在
        if !coauthors.contains(where: { $0.email == coauthor.email }) {
            coauthors.append(coauthor)
            saveCoAuthors(coauthors)
        }
    }

    /// 删除合作者
    func removeCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        coauthors.removeAll { $0.id == coauthor.id }
        saveCoAuthors(coauthors)
    }

    /// 更新合作者
    func updateCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        if let index = coauthors.firstIndex(where: { $0.id == coauthor.id }) {
            coauthors[index] = coauthor
            saveCoAuthors(coauthors)
        }
    }
}
