//
//  DreamChallengeView.swift
//  DreamLog
//
//  梦境挑战系统界面
//  Phase 15 - 梦境挑战系统
//

import SwiftUI
import Combine

// MARK: - 主挑战视图

struct DreamChallengeView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @StateObject private var challengeService = DreamChallengeService.shared
    @State private var selectedFilter: ChallengeFilter = .all
    @State private var showingBadgeDetail = false
    @State private var selectedBadge: ChallengeBadge?
    @State private var showingConfetti = false
    @State private var showingShareSheet = false
    @State private var shareChallenge: DreamChallenge?
    private var cancellables = Set<AnyCancellable>()
    
    enum ChallengeFilter: String, CaseIterable {
        case all = "全部"
        case active = "进行中"
        case completed = "已完成"
        case badges = "徽章"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if challengeService.isLoading {
                    LoadingView()
                } else {
                    challengeContent
                }
                
                // 庆祝动画
                if showingConfetti {
                    ConfettiView(isActive: true)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("🎯 挑战")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 积分显示
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(challengeService.totalPoints)")
                                .fontWeight(.semibold)
                        }
                        
                        // 等级显示
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                            Text("Lv.\(challengeService.currentLevel)")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .onAppear {
            challengeService.checkAndActivateChallenges()
            challengeService.resetDailyChallenges()
            challengeService.scheduleChallengeReminders()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let challenge = shareChallenge {
                ShareChallengeSheet(
                    challenge: challenge,
                    progress: challengeService.getProgress(for: challenge.id)
                )
            }
        }
    }
    
    var challengeContent: some View {
        Group {
            switch selectedFilter {
            case .all:
                allChallengesView
            case .active:
                activeChallengesView
            case .completed:
                completedChallengesView
            case .badges:
                badgesView
            }
        }
    }
    
    // MARK: - 全部挑战视图
    
    var allChallengesView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 统计概览
                statisticsOverview
                
                // 筛选器
                filterPicker
                
                // 活跃挑战
                if !challengeService.activeChallenges.isEmpty {
                    activeChallengesSection
                }
                
                // 已完成挑战
                if !challengeService.completedChallenges.isEmpty {
                    completedChallengesSection
                }
                
                // 徽章预览
                badgesPreviewSection
            }
            .padding()
        }
    }
    
    // MARK: - 活跃挑战视图
    
    var activeChallengesView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if challengeService.activeChallenges.isEmpty {
                    emptyStateView(
                        icon: "checkmark.circle",
                        title: "没有进行中的挑战",
                        subtitle: "每日挑战会自动刷新，敬请期待！"
                    )
                } else {
                    ForEach(challengeService.activeChallenges) { challenge in
                        ChallengeCard(
                            challenge: challenge,
                            progress: challengeService.getProgress(for: challenge.id),
                            onClaimReward: {
                                claimReward(challenge)
                            },
                            onShare: {
                                shareChallenge = challenge
                                showingShareSheet = true
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - 已完成挑战视图
    
    var completedChallengesView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if challengeService.completedChallenges.isEmpty {
                    emptyStateView(
                        icon: "trophy",
                        title: "还没有完成的挑战",
                        subtitle: "完成挑战来获得积分和徽章吧！"
                    )
                } else {
                    ForEach(challengeService.completedChallenges) { challenge in
                        CompletedChallengeCard(challenge: challenge)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - 徽章视图
    
    var badgesView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 徽章统计
                HStack(spacing: 20) {
                    StatCard(
                        icon: "shield.fill",
                        value: "\(challengeService.unlockedBadges.count)",
                        label: "已解锁",
                        color: .green
                    )
                    
                    StatCard(
                        icon: "lock.fill",
                        value: "\(DreamChallengeTemplate.allBadges().count - challengeService.unlockedBadges.count)",
                        label: "未解锁",
                        color: .orange
                    )
                    
                    StatCard(
                        icon: "star.fill",
                        value: "\(challengeService.statistics.totalPoints)",
                        label: "总积分",
                        color: .yellow
                    )
                }
                
                // 按类别分组
                ForEach(ChallengeBadge.BadgeCategory.allCases, id: \.self) { category in
                    badgeCategorySection(category: category)
                }
            }
            .padding()
        }
    }
    
    // MARK: - 组件视图
    
    var statisticsOverview: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "flame.fill",
                    value: "\(challengeService.statistics.currentStreak)",
                    label: "当前连续",
                    color: .orange
                )
                
                StatCard(
                    icon: "checkmark.seal.fill",
                    value: "\(challengeService.statistics.totalChallengesCompleted)",
                    label: "完成挑战",
                    color: .green
                )
                
                StatCard(
                    icon: "star.fill",
                    value: "\(challengeService.totalPoints)",
                    label: "总积分",
                    color: .yellow
                )
            }
            
            // 等级进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("等级 \(challengeService.currentLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("距下一级还需 \(challengeService.statistics.nextLevelPoints) 积分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: Double(challengeService.totalPoints % 100), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    var filterPicker: some View {
        Picker("筛选", selection: $selectedFilter) {
            ForEach(ChallengeFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
    
    var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "🔥 进行中的挑战", count: challengeService.activeChallenges.count)
            
            ForEach(challengeService.activeChallenges) { challenge in
                ChallengeCard(
                    challenge: challenge,
                    progress: challengeService.getProgress(for: challenge.id),
                    onClaimReward: {
                        claimReward(challenge)
                    },
                    onShare: {
                        shareChallenge = challenge
                        showingShareSheet = true
                    }
                )
            }
        }
    }
    
    var completedChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "✅ 已完成的挑战", count: challengeService.completedChallenges.count)
            
            ForEach(challengeService.completedChallenges) { challenge in
                CompletedChallengeCard(challenge: challenge)
            }
        }
    }
    
    var badgesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "🏅 最近解锁的徽章", count: challengeService.unlockedBadges.count)
            
            if challengeService.unlockedBadges.isEmpty {
                Text("完成挑战来解锁徽章！")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(challengeService.unlockedBadges.prefix(10)) { badge in
                            BadgeCard(badge: badge) {
                                selectedBadge = badge
                                showingBadgeDetail = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func badgeCategorySection(category: ChallengeBadge.BadgeCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: category.displayName, count: 0)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                let badges = DreamChallengeTemplate.allBadges().filter { $0.category == category }
                ForEach(badges, id: \.name) { badge in
                    let isUnlocked = challengeService.unlockedBadges.contains(badge)
                    MiniBadgeCard(badge: badge, isUnlocked: isUnlocked) {
                        if isUnlocked {
                            selectedBadge = badge
                            showingBadgeDetail = true
                        }
                    }
                }
            }
        }
    }
    
    func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    func claimReward(_ challenge: DreamChallenge) {
        if challengeService.claimReward(for: challenge.id) {
            // 显示庆祝动画
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showingConfetti = true
            }
            
            // 3 秒后隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showingConfetti = false
                }
            }
            
            // 发送通知
            challengeService.sendChallengeCompletedNotification(challenge)
        }
    }
}

// MARK: - 庆祝动画组件

struct ConfettiView: View {
    let isActive: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isActive {
                    ForEach(0..<50, id: \.self) { index in
                        ConfettiParticle(index: index, size: geometry.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiParticle: View {
    let index: Int
    let size: CGSize
    @State private var offset = CGSize.zero
    @State private var opacity = 1.0
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        Circle()
            .fill(colors[index % colors.count])
            .frame(width: CGFloat.random(in: 8...12), height: CGFloat.random(in: 8...12))
            .position(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -50...0)
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: Double.random(in: 2...4))) {
                    offset = CGSize(
                        width: CGFloat.random(in: -100...100),
                        height: size.height + 100
                    )
                    opacity = 0
                }
            }
    }
}

// MARK: - 分享 Sheet

struct ShareChallengeSheet: View {
    let challenge: DreamChallenge
    let progress: UserChallengeProgress?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 挑战卡片预览
                VStack(spacing: 12) {
                    Image(systemName: challenge.type.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text(challenge.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // 进度
                    if let progress = progress {
                        VStack(spacing: 8) {
                            ProgressView(value: Double(progress.currentTotal), total: Double(challenge.goal.targetValue))
                                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            
                            Text("\(progress.currentTotal) / \(challenge.goal.targetValue) \(challenge.goal.unit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 奖励
                    HStack(spacing: 8) {
                        Image(systemName: challenge.reward.icon)
                            .foregroundColor(.yellow)
                        Text(challenge.reward.description)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding(30)
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .padding()
                
                // 分享按钮
                ShareLink(
                    item: Text("我正在参与 DreamLog 挑战：「\(challenge.title)」！\(challenge.reward.description)"),
                    subject: Text("DreamLog 梦境挑战"),
                    message: Text("加入我，一起记录梦境，探索潜意识！")
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享挑战")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: { dismiss() }) {
                    Text("关闭")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .navigationTitle("分享挑战")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 挑战卡片

struct ChallengeCard: View {
    let challenge: DreamChallenge
    let progress: UserChallengeProgress?
    let onClaimReward: () -> Void
    let onShare: (() -> Void)?
    
    init(challenge: DreamChallenge, progress: UserChallengeProgress?, onClaimReward: @escaping () -> Void, onShare: (() -> Void)? = nil) {
        self.challenge = challenge
        self.progress = progress
        self.onClaimReward = onClaimReward
        self.onShare = onShare
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Image(systemName: challenge.type.icon)
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.headline)
                    
                    Text(challenge.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // 分享按钮
                    if let onShare = onShare {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .padding(6)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    // 难度标签
                    Text(challenge.difficulty.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(challenge.difficulty.color).opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // 描述
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(progress?.currentTotal ?? 0)/\(challenge.goal.targetValue) \(challenge.goal.unit)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: progress?.currentTotal ?? 0, total: challenge.goal.targetValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
            }
            
            // 奖励
            HStack {
                Image(systemName: challenge.reward.icon)
                    .foregroundColor(.yellow)
                
                Text(challenge.reward.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if progress?.isCompleted == true && !(progress?.claimedReward ?? false) {
                    Button(action: onClaimReward) {
                        Text("领取奖励")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            // 截止时间
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("截止：\(challenge.endDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - 已完成挑战卡片

struct CompletedChallengeCard: View {
    let challenge: DreamChallenge
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)
                
                Text(challenge.reward.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("已完成")
                .font(.caption)
                .foregroundColor(.green)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - 徽章卡片

struct BadgeCard: View {
    let badge: ChallengeBadge
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: badge.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                
                Text(badge.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("\(badge.points) 积分")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, height: 120)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - 迷你徽章卡片

struct MiniBadgeCard: View {
    let badge: ChallengeBadge
    let isUnlocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: badge.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isUnlocked ? .yellow : .gray)
                    .opacity(isUnlocked ? 1.0 : 0.5)
                
                Text(badge.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
            }
            .frame(width: 80, height: 90)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .disabled(!isUnlocked)
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 章节头部

struct SectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            if count > 0 {
                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 加载视图

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载中...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 预览

#Preview {
    DreamChallengeView()
        .environmentObject(DreamStore())
}
