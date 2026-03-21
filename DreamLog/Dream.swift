//
//  Dream.swift
//  DreamLog
//
//  数据模型：梦境记录
//

import Foundation
import UIKit

/// 梦境记录模型
@MainActor
class Dream: Identifiable, ObservableObject {
    @Published var id: UUID
    @Published var title: String
    @Published var content: String
    @Published var originalText: String
    @Published var date: Date
    @Published var timeOfDay: TimeOfDay
    @Published var tags: [String]
    @Published var emotions: [Emotion]
    @Published var clarity: Int
    @Published var intensity: Int
    @Published var isLucid: Bool
    @Published var aiAnalysis: String?
    @Published var aiImageUrl: String?
    @Published var isPublic: Bool
    @Published var likeCount: Int
    @Published var createdAt: Date
    @Published var updatedAt: Date
    
    // MARK: - Privacy Mode Properties (Phase 70)
    @Published var lockType: DreamLockType         // 隐私锁定类型
    @Published var isHidden: Bool                   // 是否隐藏（不显示在列表中）
    @Published var lockedAt: Date?                  // 锁定时间
    
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        originalText: String = "",
        date: Date = Date(),
        timeOfDay: TimeOfDay = .morning,
        tags: [String] = [],
        emotions: [Emotion] = [],
        clarity: Int = 3,
        intensity: Int = 3,
        isLucid: Bool = false,
        aiAnalysis: String? = nil,
        aiImageUrl: String? = nil,
        isPublic: Bool = false,
        likeCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lockType: DreamLockType = .none,
        isHidden: Bool = false,
        lockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.originalText = originalText
        self.date = date
        self.timeOfDay = timeOfDay
        self.tags = tags
        self.emotions = emotions
        self.clarity = clarity
        self.intensity = intensity
        self.isLucid = isLucid
        self.aiAnalysis = aiAnalysis
        self.aiImageUrl = aiImageUrl
        self.isPublic = isPublic
        self.likeCount = likeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lockType = lockType
        self.isHidden = isHidden
        self.lockedAt = lockedAt
    }
}

// MARK: - 时间段
enum TimeOfDay: String, Codable, CaseIterable {
    case earlyMorning = "凌晨"  // 0-6
    case morning = "早上"       // 6-12
    case afternoon = "下午"     // 12-18
    case evening = "傍晚"       // 18-24
    
    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<6: return .earlyMorning
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        default: return .evening
        }
    }
}

// MARK: - 情绪
enum Emotion: String, Codable, CaseIterable {
    case calm = "平静"
    case happy = "快乐"
    case anxious = "焦虑"
    case fearful = "恐惧"
    case confused = "困惑"
    case excited = "兴奋"
    case sad = "悲伤"
    case angry = "愤怒"
    case surprised = "惊讶"
    case neutral = "中性"
    
    var icon: String {
        switch self {
        case .calm: return "😊"
        case .happy: return "😄"
        case .anxious: return "😰"
        case .fearful: return "😨"
        case .confused: return "🤔"
        case .excited: return "🤩"
        case .sad: return "😢"
        case .angry: return "😠"
        case .surprised: return "😲"
        case .neutral: return "😐"
        }
    }
    
    var color: String {
        switch self {
        case .calm: return "6BB6FF"
        case .happy: return "FFD700"
        case .anxious: return "FFA500"
        case .fearful: return "8B0000"
        case .confused: return "9370DB"
        case .excited: return "FF1493"
        case .sad: return "4682B4"
        case .angry: return "DC143C"
        case .surprised: return "FFD700"
        case .neutral: return "808080"
        }
    }
    
    var uiColor: UIColor {
        UIColor(hex: color)
    }
}

// MARK: - Dream 扩展
extension Dream {
    /// 获取主要情绪 (第一个情绪或默认中性)
    var primaryEmotion: Emotion? {
        emotions.first
    }
    
    /// 格式化的日期字符串
    var formattedDate: String {
        date.formatted(.dateTime.year().month().day().hour().minute())
    }
    
    // MARK: - Privacy Mode Helpers
    
    /// 检查梦境是否已锁定
    var isLocked: Bool {
        lockType != .none
    }
    
    /// 检查梦境是否需要认证才能查看
    var requiresAuthentication: Bool {
        isLocked && !isHidden
    }
    
    /// 获取锁定图标
    var lockIcon: String {
        switch lockType {
        case .none: return ""
        case .biometric: return "faceid"
        case .passcode: return "lock.fill"
        case .hidden: return "eye.slash"
        case .autoLock: return "lock.shield"
        }
    }
    
    /// 锁定梦境
    func lock(type: DreamLockType) {
        lockType = type
        lockedAt = Date()
        updatedAt = Date()
    }
    
    /// 解锁梦境
    func unlock() {
        lockType = .none
        lockedAt = nil
        isHidden = false
        updatedAt = Date()
    }
    
    /// 切换隐藏状态
    func toggleHidden() {
        isHidden.toggle()
        updatedAt = Date()
    }
}

// MARK: - 梦境标签
struct DreamTag: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: TagCategory
    let count: Int
    
    enum TagCategory: String, Codable {
        case person = "人物"
        case place = "地点"
        case object = "物品"
        case action = "行为"
        case emotion = "情绪"
        case animal = "动物"
        case nature = "自然"
        case supernatural = "超自然"
    }
}

// MARK: - 梦境模式
struct DreamPattern: Identifiable, Codable {
    let id: UUID
    let pattern: String
    let frequency: Int
    let lastOccurrence: Date
    let insight: String
    let relatedTags: [String]
}

// MARK: - AI 解析结果
struct AIAnalysis: Codable {
    let summary: String
    let keywords: [String]
    let emotions: [String]
    let symbols: [DreamSymbol]
    let suggestions: [String]
    let relatedDreams: [UUID]
    
    struct DreamSymbol: Codable {
        let symbol: String
        let meaning: String
        let confidence: Double
    }
}

// MARK: - 梦境统计
struct DreamStatistics: Codable {
    let totalDreams: Int
    let lucidDreams: Int
    let averageClarity: Double
    let averageIntensity: Double
    let topEmotions: [EmotionCount]
    let topTags: [TagCount]
    let dreamsByTimeOfDay: [TimeOfDay: Int]
    let dreamsByWeekday: [Int: Int]  // 0=Sunday, 6=Saturday
    
    struct EmotionCount: Codable {
        let emotion: Emotion
        let count: Int
    }
    
    struct TagCount: Codable {
        let tag: String
        let count: Int
    }
}
