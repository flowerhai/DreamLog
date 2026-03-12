//
//  DreamARSocialService.swift
//  DreamLog - Phase 22: AR Enhancement & 3D Dream World
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import Combine

// MARK: - Social Service

/// AR 场景社交服务
/// 管理点赞、评论、收藏、热门场景等社交功能
class DreamARSocialService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DreamARSocialService()
    
    // MARK: - Published Properties
    
    @Published var likedScenes: Set<String> = []
    @Published var favoritedScenes: Set<String> = []
    @Published var viewedHistory: [String] = []
    @Published var myComments: [ARComment] = []
    @Published var trendingScenes: [ARSceneMetadata] = []
    @Published var recommendedScenes: [ARSceneMetadata] = []
    
    // MARK: - Properties
    
    private let likedScenesKey = "dreamlog_liked_scenes"
    private let favoritedScenesKey = "dreamlog_favorited_scenes"
    private let viewedHistoryKey = "dreamlog_viewed_history"
    private let maxHistoryCount = 50
    
    // 模拟数据
    private var mockScenes: [ARSceneMetadata] = []
    
    // MARK: - Init
    
    private init() {
        loadUserPreferences()
        generateMockData()
    }
    
    // MARK: - Like Functions
    
    /// 点赞场景
    func likeScene(_ sceneId: String) {
        if likedScenes.contains(sceneId) {
            likedScenes.remove(sceneId)
            print("💔 取消点赞场景：\(sceneId)")
        } else {
            likedScenes.insert(sceneId)
            print("❤️ 点赞场景：\(sceneId)")
        }
        saveUserPreferences()
    }
    
    /// 检查是否已点赞
    func isLiked(_ sceneId: String) -> Bool {
        return likedScenes.contains(sceneId)
    }
    
    /// 获取点赞数
    func getLikeCount(for sceneId: String) -> Int {
        // 实际实现中从服务器获取
        return Int.random(in: 0...500)
    }
    
    // MARK: - Favorite Functions
    
    /// 收藏场景
    func favoriteScene(_ sceneId: String) {
        if favoritedScenes.contains(sceneId) {
            favoritedScenes.remove(sceneId)
            print("⭐ 取消收藏场景：\(sceneId)")
        } else {
            favoritedScenes.insert(sceneId)
            print("⭐ 收藏场景：\(sceneId)")
        }
        saveUserPreferences()
    }
    
    /// 检查是否已收藏
    func isFavorited(_ sceneId: String) -> Bool {
        return favoritedScenes.contains(sceneId)
    }
    
    /// 获取收藏的场景列表
    func getFavoritedScenes() -> [String] {
        return Array(favoritedScenes)
    }
    
    // MARK: - History Functions
    
    /// 记录查看历史
    func recordView(_ sceneId: String) {
        // 移除已存在的记录
        viewedHistory.removeAll { $0 == sceneId }
        
        // 添加到开头
        viewedHistory.insert(sceneId, at: 0)
        
        // 限制历史记录数量
        if viewedHistory.count > maxHistoryCount {
            viewedHistory.removeLast()
        }
        
        saveUserPreferences()
    }
    
    /// 获取浏览历史
    func getViewHistory() -> [String] {
        return viewedHistory
    }
    
    /// 清除浏览历史
    func clearViewHistory() {
        viewedHistory.removeAll()
        saveUserPreferences()
    }
    
    // MARK: - Comment Functions
    
    /// 发表评论
    func addComment(_ comment: ARComment) {
        myComments.append(comment)
        print("💬 发表评论：\(comment.content.prefix(20))...")
    }
    
    /// 获取场景评论列表
    func getComments(for sceneId: String) -> [ARComment] {
        // 实际实现中从服务器获取
        return generateMockComments(for: sceneId)
    }
    
    /// 删除评论
    func deleteComment(_ commentId: UUID) {
        myComments.removeAll { $0.id == commentId }
    }
    
    // MARK: - Trending & Recommended
    
    /// 获取热门场景
    func getTrendingScenes(limit: Int = 10) -> [ARSceneMetadata] {
        return Array(trendingScenes.prefix(limit))
    }
    
    /// 获取推荐场景
    func getRecommendedScenes(limit: Int = 10) -> [ARSceneMetadata] {
        return Array(recommendedScenes.prefix(limit))
    }
    
    /// 刷新热门和推荐数据
    func refreshRecommendations() {
        generateMockData()
    }
    
    // MARK: - Share Functions
    
    /// 生成分享链接
    func generateShareLink(for sceneId: String) -> URL? {
        // 实际实现中生成真实的分享链接
        return URL(string: "dreamlog://scene/\(sceneId)")
    }
    
    /// 生成分享码
    func generateShareCode(for sceneId: String) -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).compactMap { _ in chars.randomElement() })
    }
    
    // MARK: - Private Functions
    
    private func loadUserPreferences() {
        if let data = UserDefaults.standard.data(forKey: likedScenesKey),
           let scenes = try? JSONDecoder().decode(Set<String>.self, from: data) {
            likedScenes = scenes
        }
        
        if let data = UserDefaults.standard.data(forKey: favoritedScenesKey),
           let scenes = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoritedScenes = scenes
        }
        
        if let history = UserDefaults.standard.stringArray(forKey: viewedHistoryKey) {
            viewedHistory = history
        }
    }
    
    private func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(likedScenes) {
            UserDefaults.standard.set(data, forKey: likedScenesKey)
        }
        
        if let data = try? JSONEncoder().encode(favoritedScenes) {
            UserDefaults.standard.set(data, forKey: favoritedScenesKey)
        }
        
        UserDefaults.standard.set(viewedHistory, forKey: viewedHistoryKey)
    }
    
    private func generateMockData() {
        // 生成模拟的热门场景
        mockScenes = [
            ARSceneMetadata(
                id: "scene_001",
                title: "🌌 星空梦境",
                creator: "Dreamer123",
                likeCount: 1234,
                viewCount: 5678,
                commentCount: 89,
                category: .starry,
                thumbnail: "star.fill",
                createdAt: Date().addingTimeInterval(-86400 * 2)
            ),
            ARSceneMetadata(
                id: "scene_002",
                title: "🌊 海洋世界",
                creator: "OceanLover",
                likeCount: 987,
                viewCount: 4321,
                commentCount: 67,
                category: .ocean,
                thumbnail: "water.waves",
                createdAt: Date().addingTimeInterval(-86400 * 1)
            ),
            ARSceneMetadata(
                id: "scene_003",
                title: "🌲 森林秘境",
                creator: "NatureFan",
                likeCount: 856,
                viewCount: 3456,
                commentCount: 54,
                category: .forest,
                thumbnail: "tree.fill",
                createdAt: Date().addingTimeInterval(-86400 * 3)
            ),
            ARSceneMetadata(
                id: "scene_004",
                title: "🔮 魔法空间",
                creator: "MagicMaster",
                likeCount: 765,
                viewCount: 2987,
                commentCount: 43,
                category: .magic,
                thumbnail: "wand.and.stars",
                createdAt: Date().addingTimeInterval(-86400 * 4)
            ),
            ARSceneMetadata(
                id: "scene_005",
                title: "🏰 童话城堡",
                creator: "PrincessDream",
                likeCount: 654,
                viewCount: 2345,
                commentCount: 38,
                category: .castle,
                thumbnail: "castle",
                createdAt: Date().addingTimeInterval(-86400 * 5)
            )
        ]
        
        trendingScenes = mockScenes.sorted { $0.likeCount > $1.likeCount }
        recommendedScenes = mockScenes.shuffled()
    }
    
    private func generateMockComments(for sceneId: String) -> [ARComment] {
        return [
            ARComment(
                id: UUID(),
                sceneId: sceneId,
                userId: "user_001",
                userName: "Dreamer123",
                content: "太美了！这个星空场景真的很震撼 ✨",
                likeCount: 23,
                createdAt: Date().addingTimeInterval(-3600 * 2),
                replies: []
            ),
            ARComment(
                id: UUID(),
                sceneId: sceneId,
                userId: "user_002",
                userName: "ARExplorer",
                content: "星星的动画效果做得很细腻，怎么做的？",
                likeCount: 15,
                createdAt: Date().addingTimeInterval(-3600 * 5),
                replies: []
            ),
            ARComment(
                id: UUID(),
                sceneId: sceneId,
                userId: "user_003",
                userName: "NightOwl",
                content: "已收藏！晚上拿出来看特别有感觉 🌙",
                likeCount: 8,
                createdAt: Date().addingTimeInterval(-3600 * 12),
                replies: []
            )
        ]
    }
}

// MARK: - Data Models

/// AR 场景元数据
struct ARSceneMetadata: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let creator: String
    let likeCount: Int
    let viewCount: Int
    let commentCount: Int
    let category: TemplateCategory
    let thumbnail: String
    let createdAt: Date
    
    /// 格式化点赞数
    var formattedLikeCount: String {
        if likeCount >= 1000 {
            return String(format: "%.1fK", Double(likeCount) / 1000)
        }
        return "\(likeCount)"
    }
    
    /// 格式化浏览数
    var formattedViewCount: String {
        if viewCount >= 1000 {
            return String(format: "%.1fK", Double(viewCount) / 1000)
        }
        return "\(viewCount)"
    }
}

/// AR 评论
struct ARComment: Identifiable, Codable {
    let id: UUID
    let sceneId: String
    let userId: String
    let userName: String
    var content: String
    var likeCount: Int
    let createdAt: Date
    var replies: [ARCommentReply]
    
    /// 格式化时间
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

/// AR 评论回复
struct ARCommentReply: Identifiable, Codable {
    let id: UUID
    let commentId: UUID
    let userId: String
    let userName: String
    var content: String
    let createdAt: Date
}

// MARK: - Social Stats

/// 社交统计数据
struct ARSocialStats {
    var totalLikes = 0
    var totalComments = 0
    var totalShares = 0
    var totalViews = 0
    var followerCount = 0
    var followingCount = 0
    
    /// 格式化总点赞数
    var formattedTotalLikes: String {
        if totalLikes >= 1000 {
            return String(format: "%.1fK", Double(totalLikes) / 1000)
        }
        return "\(totalLikes)"
    }
}
