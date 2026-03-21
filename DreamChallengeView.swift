//
//  DreamChallengeView.swift
//  DreamLog
//
//  Phase 58 - 梦境挑战系统 UI
//  创建时间：2026-03-16
//

import SwiftUI
import SwiftData

// MARK: - 主视图

struct DreamChallengeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ChallengeViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: ChallengeViewModel())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 统计卡片
                    StatsOverviewCard(stats: viewModel.stats)
                    
                    // 进行中挑战
                    if !viewModel.activeChallenges.isEmpty {
                        SectionView(
                            title: "🔥 进行中挑战",
                            subtitle: "继续加油！"
                        ) {
                            ForEach(viewModel.activeChallenges, id: \.id) { challenge in
                                ActiveChallengeCard(
                                    challenge: challenge,
                                    template: viewModel.getTemplate(for: challenge.templateId),
                                    onStart: { viewModel.startChallenge(templateId: challenge.templateId) },
                                    onUpdate: { viewModel.updateProgress(challengeId: challenge.id) }
                                )
                            }
                        }
                    }
                    
                    // 推荐挑战
                    SectionView(
                        title: "🎯 推荐挑战",
                        subtitle: "根据你的记录习惯推荐"
                    ) {
                        ForEach(viewModel.recommendedChallenges.prefix(3), id: \.id) { template in
                            RecommendedChallengeCard(
                                template: template,
                                isStarted: viewModel.isChallengeStarted(templateId: template.id),
                                onStart: { viewModel.startChallenge(templateId: template.id) }
                            )
                        }
                    }
                    
                    // 按类别浏览
                    SectionView(
                        title: "📂 浏览挑战",
                        subtitle: "按类别查看所有挑战"
                    ) {
                        CategoryGrid(
                            categories: ChallengeCategory.allCases,
                            onSelect: { category in
                                viewModel.selectedCategory = category
                            }
                        )
                    }
                    
                    // 徽章展示
                    SectionView(
                        title: "🏆 成就徽章",
                        subtitle: "解锁更多徽章"
                    ) {
                        BadgeShowcase(
                            badges: viewModel.badges,
                            onTap: { badge in
                                viewModel.showBadgeDetail = badge
                            }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("梦境挑战")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showStatsDetail = true }) {
                        Image(systemName: "chart.bar.fill")
                            .accessibilityLabel("查看挑战统计")
                            .accessibilityHint("显示详细的挑战完成统计和进度")
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("梦境挑战")
            .sheet(item: $viewModel.showBadgeDetail) { badge in
                BadgeDetailView(badge: badge)
            }
            .sheet(isPresented: $viewModel.showStatsDetail) {
                StatsDetailView(stats: viewModel.stats)
            }
            .onAppear {
                viewModel.loadAllData()
            }
        }
    }
}

// MARK: - 统计卡片

struct StatsOverviewCard: View {
    let stats: ChallengeStats?
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                ChallengeStatItem(
                    icon: "🏆",
                    value: "\(stats?.totalChallengesCompleted ?? 0)",
                    label: "已完成"
                )
                
                ChallengeStatItem(
                    icon: "⭐",
                    value: "\(stats?.totalPointsEarned ?? 0)",
                    label: "总积分"
                )
                
                ChallengeStatItem(
                    icon: "🔥",
                    value: "\(stats?.currentStreak ?? 0)",
                    label: "连续天数"
                )
            }
            
            HStack(spacing: 20) {
                ChallengeStatItem(
                    icon: "🎖️",
                    value: "\(stats?.totalBadgesEarned ?? 0)",
                    label: "徽章"
                )
                
                ChallengeStatItem(
                    icon: "📅",
                    value: "\(stats?.todayCompleted ?? 0)",
                    label: "今日"
                )
                
                ChallengeStatItem(
                    icon: "📆",
                    value: "\(stats?.weekCompleted ?? 0)",
                    label: "本周"
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(hex: "#6366F1"), Color(hex: "#8B5CF6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .cornerRadius(16)
        .shadow(color: Color(hex: "#6366F1").opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct ChallengeStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 20))
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
            
            Text(label)
                .font(.system(size: 12))
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 进行中挑战卡片

struct ActiveChallengeCard: View {
    let challenge: UserChallenge
    let template: DreamChallengeTemplate?
    let onStart: () -> Void
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(template?.icon ?? "🎯")
                    .font(.system(size: 32))
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template?.title ?? "挑战")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(template?.description ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                
                DifficultyBadge(difficulty: template?.difficulty ?? .medium)
            }
            
            // 进度条
            VStack(spacing: 8) {
                HStack {
                    Text("进度")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(challenge.progress)/\(challenge.targetProgress)")
                        .font(.system(size: 12, weight: .medium))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray4))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: template?.backgroundColor ?? "#6366F1"), Color(hex: "#8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * challenge.progressPercentage)
                    }
                }
                .frame(height: 8)
            }
            
            // 过期时间
            if let expiresAt = challenge.expiresAt {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    
                    Text("剩余 \(formatTimeRemaining(until: expiresAt))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            Button(action: onUpdate) {
                Text("更新进度")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: template?.backgroundColor ?? "#6366F1"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func formatTimeRemaining(until date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: now, to: date)
        
        if let hours = components.hour, hours > 0 {
            return "\(hours)小时"
        } else if let minutes = components.minute {
            return "\(minutes)分钟"
        }
        return "即将过期"
    }
}

// MARK: - 推荐挑战卡片

struct RecommendedChallengeCard: View {
    let template: DreamChallengeTemplate
    let isStarted: Bool
    let onStart: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Text(template.icon)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(Color(hex: template.backgroundColor).opacity(0.1))
                .cornerRadius(12)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(template.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    DifficultyBadge(difficulty: template.difficulty)
                    
                    Text("+\(template.rewardPoints) 积分")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if isStarted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                    .accessibilityLabel("已开始")
            } else {
                Button(action: onStart) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: template.backgroundColor))
                        .accessibilityLabel("开始挑战：\(template.title)")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.title) - \(template.description) - 奖励\(template.rewardPoints)积分")
    }
}

// MARK: - 难度徽章

struct DifficultyBadge: View {
    let difficulty: ChallengeDifficulty
    
    var body: some View {
        HStack(spacing: 2) {
            switch difficulty {
            case .easy:
                Text("⭐")
            case .medium:
                Text("⭐⭐")
            case .hard:
                Text("⭐⭐⭐")
            case .expert:
                Text("⭐⭐⭐⭐")
            }
        }
        .font(.system(size: 10))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(hex: difficulty.color).opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - 分类网格

struct CategoryGrid: View {
    let categories: [ChallengeCategory]
    let onSelect: (ChallengeCategory) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(categories) { category in
                Button(action: { onSelect(category) }) {
                    VStack(spacing: 8) {
                        Text(category.icon)
                            .font(.system(size: 32))
                        
                        Text(category.displayName)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
        }
    }
}

// MARK: - 徽章展示

struct BadgeShowcase: View {
    let badges: [AchievementBadge]
    let onTap: (AchievementBadge) -> Void
    
    var unlockedBadges: [AchievementBadge] {
        badges.filter { $0.isUnlocked }
    }
    
    var lockedBadges: [AchievementBadge] {
        badges.filter { !$0.isUnlocked }.prefix(6).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 已解锁徽章
            if !unlockedBadges.isEmpty {
                HStack(spacing: 12) {
                    ForEach(unlockedBadges.prefix(5), id: \.id) { badge in
                        Button(action: { onTap(badge) }) {
                            VStack {
                                Text(badge.icon)
                                    .font(.system(size: 36))
                                
                                Text(badge.name)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                            }
                            .frame(width: 70, height: 80)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                }
            }
            
            // 未解锁徽章
            HStack(spacing: 12) {
                ForEach(lockedBadges, id: \.id) { badge in
                    VStack {
                        Text("🔒")
                            .font(.system(size: 36))
                            .opacity(0.5)
                        
                        Text(badge.name)
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .opacity(0.5)
                    }
                    .frame(width: 70, height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - 徽章详情

struct BadgeDetailView: View {
    let badge: AchievementBadge
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 徽章图标
                    VStack(spacing: 15) {
                        Text(badge.isUnlocked ? badge.icon : "🔒")
                            .font(.system(size: 100))
                        
                        Text(badge.name)
                            .font(.system(size: 28, weight: .bold))
                        
                        if badge.isUnlocked {
                            Text("已解锁")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(20)
                        } else {
                            Text("未解锁")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .cornerRadius(20)
                        }
                    }
                    .padding(.top, 40)
                    
                    // 描述
                    VStack(alignment: .leading, spacing: 10) {
                        Text("描述")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(badge.description)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    // 要求
                    VStack(alignment: .leading, spacing: 10) {
                        Text("解锁要求")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(badge.requirementDescription)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    // 奖励
                    HStack(spacing: 30) {
                        VStack {
                            Text("🏆")
                                .font(.system(size: 24))
                            Text("\(badge.points)")
                                .font(.system(size: 20, weight: .bold))
                            Text("积分")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("📊")
                                .font(.system(size: 24))
                            Text(badge.difficulty.displayName)
                                .font(.system(size: 20, weight: .bold))
                            Text("难度")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("徽章详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 统计详情

struct StatsDetailView: View {
    let stats: ChallengeStats?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("总体统计")) {
                    StatRow(label: "已完成挑战", value: "\(stats?.totalChallengesCompleted ?? 0)")
                    StatRow(label: "总积分", value: "\(stats?.totalPointsEarned ?? 0)")
                    StatRow(label: "已解锁徽章", value: "\(stats?.totalBadgesEarned ?? 0)")
                    StatRow(label: "当前连续", value: "\(stats?.currentStreak ?? 0) 天")
                    StatRow(label: "最长连续", value: "\(stats?.longestStreak ?? 0) 天")
                }
                
                Section(header: Text("时间统计")) {
                    StatRow(label: "今日完成", value: "\(stats?.todayCompleted ?? 0)")
                    StatRow(label: "本周完成", value: "\(stats?.weekCompleted ?? 0)")
                    StatRow(label: "本月完成", value: "\(stats?.monthCompleted ?? 0)")
                }
                
                Section(header: Text("按类别")) {
                    StatRow(label: "记录挑战", value: "\(stats?.recordingChallengesCompleted ?? 0)")
                    StatRow(label: "清醒梦挑战", value: "\(stats?.lucidChallengesCompleted ?? 0)")
                    StatRow(label: "反思挑战", value: "\(stats?.reflectionChallengesCompleted ?? 0)")
                    StatRow(label: "创意挑战", value: "\(stats?.creativityChallengesCompleted ?? 0)")
                    StatRow(label: "社交挑战", value: "\(stats?.socialChallengesCompleted ?? 0)")
                    StatRow(label: "连续挑战", value: "\(stats?.streakChallengesCompleted ?? 0)")
                    StatRow(label: "探索挑战", value: "\(stats?.explorationChallengesCompleted ?? 0)")
                }
                
                Section(header: Text("按难度")) {
                    StatRow(label: "简单", value: "\(stats?.easyCompleted ?? 0)")
                    StatRow(label: "中等", value: "\(stats?.mediumCompleted ?? 0)")
                    StatRow(label: "困难", value: "\(stats?.hardCompleted ?? 0)")
                    StatRow(label: "专家", value: "\(stats?.expertCompleted ?? 0)")
                }
            }
            .navigationTitle("挑战统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

struct ChallengeStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - 分区视图

struct SectionView<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            content
        }
    }
}

// MARK: - ViewModel

@MainActor
class ChallengeViewModel: ObservableObject {
    @Published var stats: ChallengeStats?
    @Published var activeChallenges: [UserChallenge] = []
    @Published var recommendedChallenges: [DreamChallengeTemplate] = []
    @Published var badges: [AchievementBadge] = []
    @Published var selectedCategory: ChallengeCategory?
    @Published var showBadgeDetail: AchievementBadge?
    @Published var showStatsDetail: Bool = false
    
    private var service: DreamChallengeService?
    private var modelContext: ModelContext?
    
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.service = DreamChallengeService(modelContext: modelContext)
    }
    
    func loadAllData() {
        guard let service = service else { return }
        
        do {
            // 初始化预设数据
            try service.initializePresetTemplates()
            try service.initializePresetBadges()
            
            // 加载数据
            stats = try service.getStats()
            activeChallenges = try service.getActiveChallenges()
            recommendedChallenges = try service.getAllTemplates().prefix(10).map { $0 }
            badges = try service.getAllBadges()
            
            try service.refreshStats()
            stats = try service.getStats()
        } catch {
            print("加载挑战数据失败：\(error)")
        }
    }
    
    func getTemplate(for templateId: UUID) -> DreamChallengeTemplate? {
        guard let service = service else { return nil }
        return try? service.getTemplates(by: .recording).first { $0.id == templateId }
    }
    
    func isChallengeStarted(templateId: UUID) -> Bool {
        return activeChallenges.contains { $0.templateId == templateId }
    }
    
    func startChallenge(templateId: UUID) {
        guard let service = service else { return }
        
        do {
            _ = try service.startChallenge(templateId: templateId)
            loadAllData()
        } catch {
            print("开始挑战失败：\(error)")
        }
    }
    
    func updateProgress(challengeId: UUID) {
        guard let service = service else { return }
        
        do {
            let challenges = try service.getUserChallenges()
            if let challenge = challenges.first(where: { $0.id == challengeId }) {
                try service.updateChallengeProgress(
                    challengeId: challengeId,
                    progress: challenge.progress + 1
                )
                loadAllData()
            }
        } catch {
            print("更新进度失败：\(error)")
        }
    }
}

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
