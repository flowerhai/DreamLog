//
//  DreamFamilyPrivacyService.swift
//  DreamLog - Family Sharing Privacy Service
//  Phase 96: Family Sharing 👨‍👩‍👧‍👦✨
//
//  Created on 2026-03-23
//

import Foundation

actor DreamFamilyPrivacyService {
    
    // MARK: - Properties
    
    /// 敏感关键词列表（用于内容过滤）
    private let sensitiveKeywords: Set<String> = [
        // 暴力相关
        "暴力", "杀戮", "死亡", "血腥", "伤害", "攻击", "武器",
        // 成人内容
        "性", "色情", "裸露", "成人",
        // 自残
        "自残", "自杀", "伤害自己",
        // 其他敏感内容
        "恐怖", "噩梦", "恐惧"
    ]
    
    /// 不适合儿童的关键词
    private let childInappropriateKeywords: Set<String> = [
        "暴力", "杀戮", "死亡", "血腥", "性", "色情", "成人", "恐怖"
    ]
    
    // MARK: - Content Filtering
    
    /// 检查内容是否敏感
    func checkSensitiveContent(_ content: String) -> Bool {
        let lowercased = content.lowercased()
        return sensitiveKeywords.contains { keyword in
            lowercased.contains(keyword.lowercased())
        }
    }
    
    /// 过滤不当内容
    func filterInappropriateContent(_ content: String) -> String {
        var filtered = content
        
        for keyword in sensitiveKeywords {
            let replacement = String(repeating: "*", count: keyword.count)
            filtered = filtered.replacingOccurrences(
                of: keyword,
                with: replacement,
                options: .caseInsensitive
            )
        }
        
        return filtered
    }
    
    /// 检查内容是否适合儿童
    func isContentAppropriateForChild(_ content: String) -> Bool {
        let lowercased = content.lowercased()
        return !childInappropriateKeywords.contains { keyword in
            lowercased.contains(keyword.lowercased())
        }
    }
    
    /// 获取可见梦境（根据成员角色过滤）
    func getVisibleDreams<DreamType>(
        dreams: [DreamType],
        for member: FamilyMember,
        dreamOwnerId: (DreamType) -> UUID,
        isSensitive: (DreamType) -> Bool
    ) -> [DreamType] {
        return dreams.filter { dream in
            let ownerId = dreamOwnerId(dream)
            
            // 自己的梦境总是可见
            if ownerId == member.userId {
                return true
            }
            
            // 儿童成员看不到敏感内容
            if member.role.isChild && isSensitive(dream) {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Privacy Validation
    
    /// 验证隐私设置
    func validatePrivacySettings(
        privacyLevel: PrivacyLevel,
        memberRole: MemberRole
    ) -> Bool {
        // 儿童不能设置为公开
        if memberRole.isChild && privacyLevel == .publicLevel {
            return false
        }
        
        return true
    }
    
    /// 获取推荐的隐私级别
    func recommendedPrivacyLevel(for memberRole: MemberRole) -> PrivacyLevel {
        switch memberRole {
        case .child:
            return .family // 儿童默认家庭可见
        case .adult, .admin:
            return .privateLevel // 成人默认私密
        }
    }
    
    // MARK: - Data Protection
    
    /// 加密敏感数据
    func encryptSensitiveData(_ data: Data) -> Data {
        // 简化的加密（实际应使用更安全的加密方法）
        return data.base64EncodedData()
    }
    
    /// 解密敏感数据
    func decryptSensitiveData(_ data: Data) -> Data? {
        // 简化的解密
        return Data(base64Encoded: data)
    }
    
    // MARK: - Age Verification
    
    /// 验证用户年龄（简化版）
    func verifyUserAge(birthDate: Date?) -> Bool {
        guard let birthDate = birthDate else {
            return false
        }
        
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return age >= 13 // 最低年龄限制
    }
    
    /// 获取用户年龄段
    func getAgeGroup(birthDate: Date?) -> AgeGroup {
        guard let birthDate = birthDate else {
            return .unknown
        }
        
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
        if age < 13 {
            return .child
        } else if age < 18 {
            return .teen
        } else {
            return .adult
        }
    }
}

// MARK: - Age Group

public enum AgeGroup: String, Codable {
    case child = "child"      // < 13
    case teen = "teen"        // 13-17
    case adult = "adult"      // 18+
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .child: return "儿童"
        case .teen: return "青少年"
        case .adult: return "成人"
        case .unknown: return "未知"
        }
    }
    
    public var requiresParentalConsent: Bool {
        return self == .child || self == .teen
    }
}

// MARK: - Content Safety Rating

public enum ContentSafetyRating: Int, Codable {
    case safe = 0         // 全年龄
    case mild = 1         // 轻度内容
    case moderate = 2     // 中度内容
    case mature = 3       // 成人内容
    
    public var displayName: String {
        switch self {
        case .safe: return "✅ 全年龄"
        case .mild: return "⚠️ 轻度内容"
        case .moderate: return "🔞 中度内容"
        case .mature: return "🚫 成人内容"
        }
    }
    
    public var isAppropriateForChild: Bool {
        return self == .safe
    }
}
