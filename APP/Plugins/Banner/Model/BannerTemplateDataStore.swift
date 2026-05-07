import Foundation

enum BannerTemplateDataStore {
    static func decode<T: Decodable>(
        _ type: T.Type,
        templateID: String,
        from templateData: [String: String]
    ) -> T? {
        guard let jsonString = templateData[templateID],
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: jsonData)
    }

    static func updateEncoded<T: Encodable>(
        _ value: T?,
        templateID: String,
        in templateData: inout [String: String]
    ) {
        guard let value else {
            templateData.removeValue(forKey: templateID)
            return
        }

        guard let jsonData = try? JSONEncoder().encode(value),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        templateData[templateID] = jsonString
    }
}
