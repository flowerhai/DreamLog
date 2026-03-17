//
//  SocialAchievementView.swift
//  DreamLog
//
//  Phase 60: 社交功能增强
//  社交成就界面：成就列表、进度追踪、成就详情
//

import SwiftUI
import SwiftData

/// 社交成就界面
struct SocialAchievementView: View {
    @Query(sort: \SocialAchievement.unlockedAt, order: .reverse) private var achievements: [SocialAchievement]
    @ObservedObject private var service = SocialInteractionService.shared
    @State private var selectedFilter: AchievementFilter = .all
    @State private var showingAchievementDetail = false
    @State private var selectedAchievement: SocialAchievement?
    
    enum AchievementFilter: String, CaseIterable {
        case all = "全部"
        case unlocked = "已解锁"
        case locked = "未解锁"
        
        var displayName: String { rawValue }
    }
    
    private var filteredAchievements: [SocialAchievement] {
        switch selectedFilter {
        case .all:
            return achievements
        case .unlocked:
            return achievements.filter { $0.isUnlocked }
        case .locked:
            return achievements.filter { !$0.isUnlocked }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 筛选器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AchievementFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            action: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // 成就列表
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)], spacing: 16) {
                    ForEach(filteredList) { achievement in
                        AchievementCard(achievement: achievement)
                            .onTapGesture {
                                selectedAchievement = achievement
                                showingAchievementDetail = true
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("社交成就")
        .sheet(isPresented: $showingAchievementDetail) {
            if let achievement = selectedAchievement {
                AchievementDetailView(achievement: achievement)
            }
        }
    }
    
    private var filteredList: [SocialAchievement] {
        // 使用预设成就 + 已解锁的成就
        let presetIds = SocialAchievement.presets.map { $0.type.rawValue }
        var result: [SocialAchievement] = []
        
        // 添加预设成就
        for preset in SocialAchievement.presets {
            if let unlocked = achievements.first(where: { $0.type == preset.type }) {
                result.append(unlocked)
            } else {
                result.append(preset)
            }
        }
        
        return result
    }
}

// MARK: - 成就卡片

struct AchievementCard: View {
    let achievement: SocialAchievement
    
    var body: some View {
        VStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: achievement.isUnlocked ?
                                [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)] :
                                [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Text(achievement.icon)
                    .font(.system(size: 36))
            }
            
            // 名称
            Text(achievement.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // 进度
            if !achievement.isUnlocked {
                VStack(spacing: 4) {
                    ProgressView(value: Double(achievement.progress), total: Double(achievement.requirement))
                        .progressViewStyle(.linear)
                    
                    Text("\(achievement.progress)/\(achievement.requirement)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已解锁")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .frame(height: 180)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked ?
                        LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        Color.gray.opacity(0.2),
                    lineWidth: 2
                )
        )
    }
}

// MARK: - 成就详情

struct AchievementDetailView: View {
    let achievement: SocialAchievement
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 图标
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: achievement.isUnlocked ?
                                        [.yellow, .orange] :
                                        [.gray, .gray.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Text(achievement.icon)
                            .font(.system(size: 60))
                    }
                    .padding(.top, 20)
                    
                    // 名称和状态
                    VStack(spacing: 8) {
                        Text(achievement.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if achievement.isUnlocked {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("已解锁")
                                    .foregroundColor(.green)
                            }
                            .font(.subheadline)
                        } else {
                            Text("未解锁")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                    
                    // 描述
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // 进度
                    if !achievement.isUnlocked {
                        VStack(spacing: 12) {
                            Text("进度")
                                .font(.headline)
                            
                            ProgressView(value: Double(achievement.progress), total: Double(achievement.requirement))
                                .progressViewStyle(.linear)
                                .frame(maxWidth: 300)
                            
                            Text("\(achievement.progress) / \(achievement.requirement)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // 奖励
                    VStack(spacing: 12) {
                        Text("奖励")
                            .font(.headline)
                        
                        HStack(spacing: 30) {
                            RewardItem(icon: "star.fill", value: "+\(achievement.points)", label: "积分")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 解锁日期
                    if let unlockedAt = achievement.unlockedAt {
                        VStack(spacing: 8) {
                            Text("解锁于")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(unlockedAt.formatted(date: .long, time: .shortened))
                                .font(.subheadline)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("成就详情")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct RewardItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 筛选芯片

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - 预览

#Preview {
    NavigationView {
        SocialAchievementView()
    }
    .modelContainer(for: SocialAchievement.self, inMemory: true)
}
