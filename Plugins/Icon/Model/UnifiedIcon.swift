//
//  UnifiedIcon.swift
//  GitOK
//
//  Created by Angel on 2025/8/24.
//



/**
 * 统一图标
 * 整合本地和远程图标数据
 */
struct UnifiedIcon: Identifiable, Hashable {
    let id: String
    let name: String
    let source: IconSource
    let localIcon: IconAsset?
    let remoteIcon: RemoteIcon?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UnifiedIcon, rhs: UnifiedIcon) -> Bool {
        lhs.id == rhs.id
    }
}