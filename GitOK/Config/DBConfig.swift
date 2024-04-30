//
//  DBConfig.swift
//  SmartBanner
//
//  Created by Angel on 2024/4/19.
//

import Foundation
import SwiftData

// MARK: 数据库配置

class DBConfig {
    static var dbFileName = AppConfig.debug ? "database_debug.db" : "database.db"
    static func getContainer() -> ModelContainer {
        guard let url = AppConfig.localDocumentsDir?.appendingPathComponent(dbFileName) else {
            fatalError("Could not create ModelContainer")
        }

        let schema = Schema([
            BannerModel.self,
            TaskModel.self,
            IconModel.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: url,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
