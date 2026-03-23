//
//  DreamFamilyService.swift
//  DreamLog - Family Sharing Core Service
//  Phase 96: Family Sharing 👨‍👩‍👧‍👦✨
//
//  Created on 2026-03-23
//

import Foundation
import Combine

actor DreamFamilyService {
    
    // MARK: - Properties
    
    private let storeKey = "dreamlog.family.groups"
    private let memberStoreKey = "dreamlog.family.members"
    private let sharedDreamsStoreKey = "dreamlog.family.shared_dreams"
    private let patternsStoreKey = "dreamlog.family.patterns"
    private let challengesStoreKey = "dreamlog.family.challenges"
    private let achievementsStoreKey = "dreamlog.family.achievements"
    
    private var familyGroups: [FamilyGroup] = []
    private var familyMembers: [FamilyMember] = []
    private var sharedDreams: [SharedDream] = []
    private var familyPatterns: [FamilyPattern] = []
    private var familyChallenges: [FamilyChallenge] = []
    private var familyAchievements: [FamilyAchievement] = []
    
    private var currentUserId: UUID
    private let privacyService: DreamFamilyPrivacyService
    
    // MARK: - Initialization
    
    init(currentUserId: UUID) {
        self.currentUserId = currentUserId
        self.privacyService = DreamFamilyPrivacyService()
        loadData()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let groups = try? JSONDecoder().decode([FamilyGroup].self, from: data) {
            familyGroups = groups
        }
        
        if let data = UserDefaults.standard.data(forKey: memberStoreKey),
           let members = try? JSONDecoder().decode([FamilyMember].self, from: data) {
            familyMembers = members
        }
        
        if let data = UserDefaults.standard.data(forKey: sharedDreamsStoreKey),
           let dreams = try? JSONDecoder().decode([SharedDream].self, from: data) {
            sharedDreams = dreams
        }
        
        if let data = UserDefaults.standard.data(forKey: patternsStoreKey),
           let patterns = try? JSONDecoder().decode([FamilyPattern].self, from: data) {
            familyPatterns = patterns
        }
        
        if let data = UserDefaults.standard.data(forKey: challengesStoreKey),
           let challenges = try? JSONDecoder().decode([FamilyChallenge].self, from: data) {
            familyChallenges = challenges
        }
        
        if let data = UserDefaults.standard.data(forKey: achievementsStoreKey),
           let achievements = try? JSONDecoder().decode([FamilyAchievement].self, from: data) {
            familyAchievements = achievements
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(familyGroups) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
        
        if let data = try? JSONEncoder().encode(familyMembers) {
            UserDefaults.standard.set(data, forKey: memberStoreKey)
        }
        
        if let data = try? JSONEncoder().encode(sharedDreams) {
            UserDefaults.standard.set(data, forKey: sharedDreamsStoreKey)
        }
        
        if let data = try? JSONEncoder().encode(familyPatterns) {
            UserDefaults.standard.set(data, forKey: patternsStoreKey)
        }
        
        if let data = try? JSONEncoder().encode(familyChallenges) {
            UserDefaults.standard.set(data, forKey: challengesStoreKey)
        }
        
        if let data = try? JSONEncoder().encode(familyAchievements) {
            UserDefaults.standard.set(data, forKey: achievementsStoreKey)
        }
    }
    
    // MARK: - Family Group Management
    
    /// 创建家庭组
    func createFamilyGroup(name: String, avatar: Data? = nil) throws -> FamilyGroup {
        // 检查用户是否已加入其他家庭
        if familyMembers.contains(where: { $0.userId == currentUserId && $0.isActive }) {
            throw FamilyError.alreadyInFamily
        }
        
        let group = FamilyGroup(
            name: name,
            avatar: avatar,
            adminId: currentUserId
        )
        
        let member = FamilyMember(
            userId: currentUserId,
            familyId: group.id,
            nickname: "管理员",
            relationship: .selfRel,
            role: .admin,
            permissions: FamilyMember.defaultPermissions(for: .admin)
        )
        
        familyGroups.append(group)
        familyMembers.append(member)
        saveData()
        
        // 解锁第一个成就
        await unlockAchievement(for: group.id, type: .firstDream)
        
        return group
    }
    
    /// 加入家庭组
    func joinFamilyGroup(inviteCode: String) throws -> FamilyGroup {
        // 查找邀请码对应的家庭
        guard let group = familyGroups.first(where: { $0.inviteCode == inviteCode }) else {
            throw FamilyError.invalidInviteCode
        }
        
        // 检查用户是否已加入家庭
        if familyMembers.contains(where: { $0.userId == currentUserId && $0.isActive }) {
            throw FamilyError.alreadyInFamily
        }
        
        // 检查邀请是否有效
        if group.memberCount >= 20 { // 最多 20 个成员
            throw FamilyError.familyIsFull
        }
        
        let member = FamilyMember(
            userId: currentUserId,
            familyId: group.id,
            nickname: "新成员",
            relationship: .other,
            role: .adult,
            permissions: FamilyMember.defaultPermissions(for: .adult)
        )
        
        // 更新家庭人数
        if let index = familyGroups.firstIndex(where: { $0.id == group.id }) {
            familyGroups[index].memberCount += 1
        }
        
        familyMembers.append(member)
        saveData()
        
        return group
    }
    
    /// 离开家庭组
    func leaveFamilyGroup(familyId: UUID) throws {
        guard let memberIndex = familyMembers.firstIndex(where: {
            $0.familyId == familyId && $0.userId == currentUserId
        }) else {
            throw FamilyError.memberNotFound
        }
        
        let member = familyMembers[memberIndex]
        
        // 如果是管理员，需要转移权限或删除家庭
        if member.role == .admin {
            // 查找其他成人成员
            if let newAdmin = familyMembers.first(where: {
                $0.familyId == familyId && $0.role == .adult && $0.userId != currentUserId
            }) {
                // 转移管理员权限
                if let adminIndex = familyMembers.firstIndex(where: { $0.id == newAdmin.id }) {
                    familyMembers[adminIndex].role = .admin
                    familyMembers[adminIndex].permissions = FamilyMember.defaultPermissions(for: .admin)
                }
                
                if let groupIndex = familyGroups.firstIndex(where: { $0.id == familyId }) {
                    familyGroups[groupIndex].adminId = newAdmin.userId
                }
            } else {
                // 没有其他成员，删除家庭
                try deleteFamilyGroup(familyId: familyId)
                return
            }
        }
        
        // 移除成员
        familyMembers[memberIndex].isActive = false
        if let groupIndex = familyGroups.firstIndex(where: { $0.id == familyId }) {
            familyGroups[groupIndex].memberCount -= 1
        }
        
        saveData()
    }
    
    /// 删除家庭组
    private func deleteFamilyGroup(familyId: UUID) throws {
        familyGroups.removeAll { $0.id == familyId }
        familyMembers.removeAll { $0.familyId == familyId }
        sharedDreams.removeAll { $0.familyId == familyId }
        familyPatterns.removeAll { $0.familyId == familyId }
        familyChallenges.removeAll { $0.familyId == familyId }
        familyAchievements.removeAll { $0.familyId == familyId }
        saveData()
    }
    
    /// 邀请成员
    func inviteMember(familyId: UUID, relationship: Relationship, role: MemberRole) throws -> FamilyInvite {
        guard let group = familyGroups.first(where: { $0.id == familyId }) else {
            throw FamilyError.familyNotFound
        }
        
        guard let inviter = familyMembers.first(where: {
            $0.familyId == familyId && $0.userId == currentUserId
        }) else {
            throw FamilyError.memberNotFound
        }
        
        guard inviter.permissions.contains(.inviteMembers) else {
            throw FamilyError.permissionDenied
        }
        
        let invite = FamilyInvite(
            familyId: familyId,
            familyName: group.name,
            inviterId: currentUserId,
            inviterName: inviter.nickname,
            inviteCode: group.inviteCode
        )
        
        return invite
    }
    
    /// 获取用户的所有家庭
    func getUserFamilies() -> [FamilyGroup] {
        let memberFamilyIds = familyMembers
            .filter { $0.userId == currentUserId && $0.isActive }
            .map { $0.familyId }
        
        return familyGroups.filter { memberFamilyIds.contains($0.id) }
    }
    
    /// 获取家庭成员
    func getFamilyMembers(familyId: UUID) -> [FamilyMember] {
        return familyMembers.filter { $0.familyId == familyId && $0.isActive }
    }
    
    /// 更新成员角色
    func updateMemberRole(familyId: UUID, memberId: UUID, newRole: MemberRole) throws {
        guard let memberIndex = familyMembers.firstIndex(where: { $0.id == memberId }) else {
            throw FamilyError.memberNotFound
        }
        
        guard let admin = familyMembers.first(where: {
            $0.familyId == familyId && $0.userId == currentUserId && $0.role == .admin
        }) else {
            throw FamilyError.permissionDenied
        }
        
        familyMembers[memberIndex].role = newRole
        familyMembers[memberIndex].permissions = FamilyMember.defaultPermissions(for: newRole)
        saveData()
    }
    
    /// 移除成员
    func removeMember(familyId: UUID, memberId: UUID) throws {
        guard let admin = familyMembers.first(where: {
            $0.familyId == familyId && $0.userId == currentUserId && $0.role == .admin
        }) else {
            throw FamilyError.permissionDenied
        }
        
        guard let memberIndex = familyMembers.firstIndex(where: { $0.id == memberId }) else {
            throw FamilyError.memberNotFound
        }
        
        familyMembers[memberIndex].isActive = false
        if let groupIndex = familyGroups.firstIndex(where: { $0.id == familyId }) {
            familyGroups[groupIndex].memberCount -= 1
        }
        
        saveData()
    }
    
    // MARK: - Dream Sharing
    
    /// 分享梦境到家庭
    func shareDreamToFamily(
        dreamId: UUID,
        title: String,
        content: String,
        emotions: [String],
        tags: [String],
        dreamDate: Date,
        privacyLevel: PrivacyLevel,
        visibleTo: [UUID]? = nil
    ) throws -> SharedDream {
        guard let member = familyMembers.first(where: {
            $0.userId == currentUserId && $0.isActive
        }) else {
            throw FamilyError.memberNotFound
        }
        
        // 检查是否有分享权限
        guard member.permissions.contains(.shareDreams) else {
            throw FamilyError.permissionDenied
        }
        
        // 内容过滤（儿童保护）
        let isSensitive = await privacyService.checkSensitiveContent(content)
        
        let sharedDream = SharedDream(
            dreamId: dreamId,
            ownerId: currentUserId,
            ownerName: member.nickname,
            familyId: member.familyId,
            title: title,
            content: content,
            emotions: emotions,
            tags: tags,
            dreamDate: dreamDate,
            privacyLevel: privacyLevel,
            visibleTo: visibleTo,
            isSensitive: isSensitive
        )
        
        sharedDreams.append(sharedDream)
        
        // 更新家庭统计
        await updateFamilyStatistics(familyId: member.familyId)
        
        // 检查成就
        await checkDreamCountAchievements(familyId: member.familyId)
        
        saveData()
        return sharedDream
    }
    
    /// 获取家庭共享梦境
    func getFamilyDreams(familyId: UUID) -> [SharedDream] {
        guard let member = familyMembers.first(where: {
            $0.userId == currentUserId && $0.isActive && $0.familyId == familyId
        }) else {
            return []
        }
        
        return sharedDreams.filter {
            $0.familyId == familyId && $0.isVisible(to: member.id)
        }
        .sorted { $0.sharedAt > $1.sharedAt }
    }
    
    /// 添加反应
    func addReaction(to dreamId: UUID, emoji: String) throws {
        guard let member = familyMembers.first(where: { $0.userId == currentUserId }) else {
            throw FamilyError.memberNotFound
        }
        
        guard let index = sharedDreams.firstIndex(where: { $0.id == dreamId }) else {
            throw FamilyError.dreamNotFound
        }
        
        let reaction = FamilyReaction(
            memberId: member.id,
            memberName: member.nickname,
            emoji: emoji
        )
        
        sharedDreams[index].reactions.append(reaction)
        saveData()
    }
    
    /// 添加评论
    func addComment(to dreamId: UUID, content: String) throws {
        guard let member = familyMembers.first(where: { $0.userId == currentUserId }) else {
            throw FamilyError.memberNotFound
        }
        
        guard let index = sharedDreams.firstIndex(where: { $0.id == dreamId }) else {
            throw FamilyError.dreamNotFound
        }
        
        // 内容过滤
        let filteredContent = await privacyService.filterInappropriateContent(content)
        
        let comment = FamilyComment(
            memberId: member.id,
            memberName: member.nickname,
            content: filteredContent
        )
        
        sharedDreams[index].comments.append(comment)
        saveData()
    }
    
    // MARK: - Family Pattern Analysis
    
    /// 分析家族模式
    func analyzeFamilyPatterns(familyId: UUID) async -> [FamilyPattern] {
        let members = getFamilyMembers(familyId: familyId)
        let dreams = getFamilyDreams(familyId: familyId)
        
        guard dreams.count >= 5 else {
            return [] // 至少需要 5 个梦境才能分析模式
        }
        
        var patterns: [FamilyPattern] = []
        
        // 分析共同符号
        let commonSymbols = await findCommonSymbols(in: dreams, members: members)
        patterns.append(contentsOf: commonSymbols)
        
        // 分析共同主题
        let sharedThemes = await findSharedThemes(in: dreams, members: members)
        patterns.append(contentsOf: sharedThemes)
        
        // 分析情绪传承
        let emotionalPatterns = await findEmotionalPatterns(in: dreams, members: members)
        patterns.append(contentsOf: emotionalPatterns)
        
        // 保存新模式
        for pattern in patterns {
            if !familyPatterns.contains(where: { $0.id == pattern.id }) {
                familyPatterns.append(pattern)
            }
        }
        
        saveData()
        return patterns
    }
    
    private func findCommonSymbols(in dreams: [SharedDream], members: [FamilyMember]) async -> [FamilyPattern] {
        var symbolCounts: [String: [UUID]] = [:]
        
        for dream in dreams {
            for tag in dream.tags {
                if symbolCounts[tag] == nil {
                    symbolCounts[tag] = []
                }
                if !symbolCounts[tag]!.contains(dream.ownerId) {
                    symbolCounts[tag]!.append(dream.ownerId)
                }
            }
        }
        
        var patterns: [FamilyPattern] = []
        for (symbol, memberIds) in symbolCounts {
            if memberIds.count >= 2 { // 至少 2 个成员有相同符号
                let confidence = Double(memberIds.count) / Double(members.count)
                if confidence >= 0.3 { // 30% 以上的成员
                    let pattern = FamilyPattern(
                        familyId: dreams.first?.familyId ?? UUID(),
                        patternType: .commonSymbols,
                        title: "共同符号：\(symbol)",
                        description: "这个符号在 \(memberIds.count) 位家庭成员的梦境中出现",
                        involvedMembers: memberIds,
                        dreamCount: dreams.filter { $0.tags.contains(symbol) }.count,
                        confidence: confidence
                    )
                    patterns.append(pattern)
                }
            }
        }
        
        return patterns
    }
    
    private func findSharedThemes(in dreams: [SharedDream], members: [FamilyMember]) async -> [FamilyPattern] {
        // 简化的主题分析（基于情绪和标签组合）
        var themeCounts: [String: [UUID]] = [:]
        
        for dream in dreams {
            let themeKey = dream.emotions.sorted().joined(separator: "-")
            if themeCounts[themeKey] == nil {
                themeCounts[themeKey] = []
            }
            if !themeCounts[themeKey]!.contains(dream.ownerId) {
                themeCounts[themeKey]!.append(dream.ownerId)
            }
        }
        
        var patterns: [FamilyPattern] = []
        for (theme, memberIds) in themeCounts {
            if memberIds.count >= 2 {
                let confidence = Double(memberIds.count) / Double(members.count)
                if confidence >= 0.3 {
                    let pattern = FamilyPattern(
                        familyId: dreams.first?.familyId ?? UUID(),
                        patternType: .sharedThemes,
                        title: "共同情绪模式",
                        description: "这些情绪在 \(memberIds.count) 位家庭成员的梦境中频繁出现",
                        involvedMembers: memberIds,
                        dreamCount: dreams.filter { dream in
                            dream.emotions.sorted().joined(separator: "-") == theme
                        }.count,
                        confidence: confidence
                    )
                    patterns.append(pattern)
                }
            }
        }
        
        return patterns
    }
    
    private func findEmotionalPatterns(in dreams: [SharedDream], members: [FamilyMember]) async -> [FamilyPattern] {
        // 分析跨代际的情绪模式
        let parentMembers = members.filter { [.parent, .grandparent].contains($0.relationship) }
        let childMembers = members.filter { [.child, .grandchild].contains($0.relationship) }
        
        guard !parentMembers.isEmpty && !childMembers.isEmpty else {
            return []
        }
        
        let parentEmotions = dreams
            .filter { parentMembers.contains(where: { $0.userId == $0.ownerId }) }
            .flatMap { $0.emotions }
        
        let childEmotions = dreams
            .filter { childMembers.contains(where: { $0.userId == $0.ownerId }) }
            .flatMap { $0.emotions }
        
        let commonEmotions = Set(parentEmotions).intersection(Set(childEmotions))
        
        if commonEmotions.count >= 2 {
            return [FamilyPattern(
                familyId: dreams.first?.familyId ?? UUID(),
                patternType: .emotionalInheritance,
                title: "情绪传承模式",
                description: "这些情绪在父母和孩子的梦境中都有出现：\(commonEmotions.joined(separator: ", "))",
                involvedMembers: parentMembers.map { $0.id } + childMembers.map { $0.id },
                dreamCount: dreams.filter { dream in
                    !dream.emotions.filter { commonEmotions.contains($0) }.isEmpty
                }.count,
                confidence: Double(commonEmotions.count) / 10.0
            )]
        }
        
        return []
    }
    
    /// 获取家族模式
    func getFamilyPatterns(familyId: UUID) -> [FamilyPattern] {
        return familyPatterns.filter { $0.familyId == familyId }
    }
    
    // MARK: - Family Statistics
    
    private func updateFamilyStatistics(familyId: UUID) async {
        guard let groupIndex = familyGroups.firstIndex(where: { $0.id == familyId }) else {
            return
        }
        
        let members = getFamilyMembers(familyId: familyId)
        let dreams = getFamilyDreams(familyId: familyId)
        let challenges = familyChallenges.filter { $0.familyId == familyId }
        let patterns = familyPatterns.filter { $0.familyId == familyId }
        
        let activeMembers = members.filter { member in
            guard let lastActive = member.lastActiveAt else { return false }
            return lastActive.timeIntervalSinceNow > -7 * 24 * 60 * 60 // 7 天内活跃
        }.count
        
        let totalXP = dreams.count * 10 + challenges.filter { $0.status == .completed }.count * 100
        let level = totalXP / 1000 + 1
        
        familyGroups[groupIndex].statistics = FamilyStatistics(
            totalDreams: dreams.count,
            activeMembers: activeMembers,
            totalChallenges: challenges.count,
            completedChallenges: challenges.filter { $0.status == .completed }.count,
            discoveredPatterns: patterns.count,
            familyLevel: level,
            familyXP: totalXP
        )
        
        saveData()
    }
    
    private func checkDreamCountAchievements(familyId: UUID) async {
        let dreams = getFamilyDreams(familyId: familyId)
        
        if dreams.count == 1 {
            await unlockAchievement(for: familyId, type: .firstDream)
        } else if dreams.count == 100 {
            await unlockAchievement(for: familyId, type: .hundredDreams)
        }
    }
    
    private func unlockAchievement(for familyId: UUID, type: AchievementType) async {
        if familyAchievements.contains(where: { $0.familyId == familyId && $0.achievementType == type }) {
            return // 已解锁
        }
        
        let achievement = FamilyAchievement(
            familyId: familyId,
            achievementType: type,
            title: type.displayName,
            description: "恭喜解锁成就：\(type.displayName)",
            icon: type.icon
        )
        
        familyAchievements.append(achievement)
        saveData()
    }
    
    // MARK: - Family Achievements
    
    func getFamilyAchievements(familyId: UUID) -> [FamilyAchievement] {
        return familyAchievements.filter { $0.familyId == familyId }
    }
}

// MARK: - Family Errors

public enum FamilyError: LocalizedError {
    case alreadyInFamily
    case invalidInviteCode
    case familyNotFound
    case familyIsFull
    case memberNotFound
    case permissionDenied
    case dreamNotFound
    case inviteExpired
    
    public var errorDescription: String? {
        switch self {
        case .alreadyInFamily:
            return "您已经加入了一个家庭组"
        case .invalidInviteCode:
            return "邀请码无效"
        case .familyNotFound:
            return "家庭组不存在"
        case .familyIsFull:
            return "家庭组已满员"
        case .memberNotFound:
            return "成员不存在"
        case .permissionDenied:
            return "没有权限执行此操作"
        case .dreamNotFound:
            return "梦境不存在"
        case .inviteExpired:
            return "邀请已过期"
        }
    }
}
