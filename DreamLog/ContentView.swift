//
//  ContentView.swift
//  DreamLog
//
//  Phase 43 - 导航重构：5 个主标签
//  Phase 98 - 移除重复引导逻辑（引导已在 RootView 处理）
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @ObservedObject private var challengeService = DreamChallengeService.shared
    @ObservedObject private var favoriteManager = FavoriteManager.shared
    @AppStorage("selectedMainTab") private var selectedTab = 0
    
    var body: some View {
        mainTabView
    }
    
    var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // 📖 梦境
            DreamsNavigationView()
                .environmentObject(dreamStore)
                .tabItem {
                    Image(systemName: MainTab.dreams.icon)
                        .accessibilityHidden(true)
                    Text(MainTab.dreams.title)
                }
                .accessibilityLabel(MainTab.dreams.title)
                .tag(0)
            
            // 📊 分析
            InsightsNavigationView()
                .environmentObject(dreamStore)
                .tabItem {
                    Image(systemName: MainTab.insights.icon)
                        .accessibilityHidden(true)
                    Text(MainTab.insights.title)
                }
                .accessibilityLabel(MainTab.insights.title)
                .tag(1)
            
            // 🎮 探索
            ExploreNavigationView()
                .environmentObject(dreamStore)
                .environmentObject(challengeService)
                .tabItem {
                    Image(systemName: MainTab.explore.icon)
                        .accessibilityHidden(true)
                    Text(MainTab.explore.title)
                }
                .accessibilityLabel(MainTab.explore.title)
                .tag(2)
            
            // 🧘 成长
            GrowthNavigationView()
                .environmentObject(dreamStore)
                .tabItem {
                    Image(systemName: MainTab.growth.icon)
                        .accessibilityHidden(true)
                    Text(MainTab.growth.title)
                }
                .accessibilityLabel(MainTab.growth.title)
                .tag(3)
            
            // ⚙️ 我的
            ProfileNavigationView()
                .environmentObject(dreamStore)
                .environmentObject(challengeService)
                .tabItem {
                    Image(systemName: MainTab.profile.icon)
                        .accessibilityHidden(true)
                    Text(MainTab.profile.title)
                }
                .accessibilityLabel(MainTab.profile.title)
                .tag(4)
        }
        .tint(Color(hex: "9B7EBD"))
        .background(
            LinearGradient(
                colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .accessibilityElement(children: .contain)
    }
}

// MARK: - 空状态视图 (Empty States)

struct EmptyDreamsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "9B7EBD").opacity(0.5))
            
            VStack(spacing: 12) {
                Text("还没有梦境记录")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("开始记录你的第一个梦境吧\n每一次记录都是对自己的探索")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("记录梦境")
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "9B7EBD"), Color(hex: "7B68A8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 加载状态视图 (Loading States)

struct DreamsListViewShimmer: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 📖 梦境导航

struct DreamsNavigationView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedViewId: String = "home"
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("常用功能").accessibilityHidden(true)) {
                    NavigationLink(destination: HomeView(), tag: "home", selection: $selectedViewId) {
                        Label("梦境列表", systemImage: "list.bullet")
                            .accessibilityLabel("查看梦境列表")
                    }
                    NavigationLink(destination: CalendarView(), tag: "calendar", selection: $selectedViewId) {
                        Label("日历视图", systemImage: "calendar")
                            .accessibilityLabel("查看日历视图")
                    }
                    NavigationLink(destination: QuickAddView(), tag: "quick-add", selection: $selectedViewId) {
                        Label("快速记录", systemImage: "plus.circle.fill")
                            .accessibilityLabel("快速记录梦境")
                    }
                }
                
                Section(header: Text("搜索").accessibilityHidden(true)) {
                    NavigationLink(destination: GlobalSearchView(), tag: "search", selection: $selectedViewId) {
                        Label("全局搜索", systemImage: "magnifyingglass")
                            .accessibilityLabel("全局搜索梦境")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("📖 梦境")
            .accessibilityLabel("梦境功能导航")
        }
    }
}

// MARK: - 📊 分析导航

struct InsightsNavigationView: View {
    @EnvironmentObject var dreamStore: DreamStore
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("核心分析").accessibilityHidden(true)) {
                    NavigationLink(destination: InsightsView()) {
                        Label("数据洞察", systemImage: "chart.bar")
                            .accessibilityLabel("查看数据洞察")
                    }
                    NavigationLink(destination: DreamInsightsDashboardView()) {
                        Label("AI 解析", systemImage: "brain.head.profile")
                            .accessibilityLabel("查看 AI 梦境解析")
                    }
                }
                
                Section(header: Text("高级功能").accessibilityHidden(true)) {
                    NavigationLink(destination: DreamPredictionView()) {
                        Label("梦境预测", systemImage: "crystal.ball")
                            .accessibilityLabel("查看梦境预测")
                    }
                    NavigationLink(destination: DreamWrappedView()) {
                        Label("梦境回顾", systemImage: "sparkles")
                            .accessibilityLabel("查看梦境年度回顾")
                    }
                    NavigationLink(destination: AdvancedDashboardView()) {
                        Label("高级统计", systemImage: "chart.line.uptrend.xyaxis")
                            .accessibilityLabel("查看高级统计数据")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("📊 分析")
            .accessibilityLabel("分析功能导航")
        }
    }
}

// MARK: - 🎮 探索导航

struct ExploreNavigationView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var challengeService: DreamChallengeService
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("社区")) {
                    NavigationLink(destination: CommunityView(dreamStore: dreamStore)) {
                        Label("梦境社区", systemImage: "globe")
                    }
                    NavigationLink(destination: FriendsView(dreamStore: dreamStore)) {
                        Label("好友", systemImage: "person.2.fill")
                    }
                }
                
                Section(header: Text("互动")) {
                    NavigationLink(destination: DreamChallengeView()) {
                        Label("挑战", systemImage: "trophy.fill")
                    }
                    NavigationLink(destination: DreamShareCircleView()) {
                        Label("分享圈", systemImage: "person.3.fill")
                    }
                    NavigationLink(destination: GalleryView()) {
                        Label("梦境画廊", systemImage: "photo.on.rectangle")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("🎮 探索")
        }
    }
}

// MARK: - 🧘 成长导航

struct GrowthNavigationView: View {
    @EnvironmentObject var dreamStore: DreamStore
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("睡眠与健康")) {
                    NavigationLink(destination: SleepDataView()) {
                        Label("睡眠数据", systemImage: "moon.stars.fill")
                    }
                    NavigationLink(destination: MeditationView()) {
                        Label("冥想音乐", systemImage: "music.note.house")
                    }
                }
                
                Section(header: Text("技能提升")) {
                    NavigationLink(destination: LucidTrainingView()) {
                        Label("清醒梦训练", systemImage: "brain.head.profile")
                    }
                    NavigationLink(destination: DreamsGoalView()) {
                        Label("梦境目标", systemImage: "target")
                    }
                    NavigationLink(destination: DreamDictionaryView()) {
                        Label("梦境词典", systemImage: "text.book.closed.fill")
                    }
                }
                
                Section(header: Text("创意")) {
                    NavigationLink(destination: DreamMusicView()) {
                        Label("梦境音乐", systemImage: "music.note.house.fill")
                    }
                }
                
                Section(header: Text("反思与日记")) {
                    if #available(iOS 17.0, *) {
                        NavigationLink(destination: DreamMorningReflectionView()) {
                            Label("晨间反思", systemImage: "sunrise.fill")
                                .accessibilityLabel("晨间反思 - 从梦境中获得洞察")
                        }
                    }
                    
                    NavigationLink(destination: DreamVoiceJournalView()) {
                        Label("语音日记", systemImage: "mic.fill")
                            .accessibilityLabel("语音日记 - 录音记录梦境")
                    }
                }
                
                Section(header: Text("学习")) {
                    if #available(iOS 17.0, *) {
                        NavigationLink(destination: DreamLearningView()) {
                            Label("学习中心", systemImage: "graduationcap.fill")
                                .accessibilityLabel("学习中心 - 探索梦境知识")
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("🧘 成长")
        }
    }
}

// MARK: - ⚙️ 我的导航

struct ProfileNavigationView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var challengeService: DreamChallengeService
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("个人")) {
                    NavigationLink(destination: SettingsView()) {
                        Label("设置", systemImage: "gearshape.fill")
                    }
                    NavigationLink(destination: DreamAssistantView()) {
                        Label("AI 助手", systemImage: "message.fill")
                    }
                    NavigationLink(destination: DreamVoiceCommandView()) {
                        Label("语音命令", systemImage: "mic.circle.fill")
                            .accessibilityLabel("语音命令 - 语音控制应用")
                    }
                }
                
                Section(header: Text("数据管理")) {
                    NavigationLink(destination: DreamBackupView()) {
                        Label("备份恢复", systemImage: "externaldrive.fill")
                    }
                    NavigationLink(destination: DreamTimeCapsuleView()) {
                        Label("时间胶囊", systemImage: "hourglass.badge.fill")
                    }
                }
                
                Section(header: Text("创意功能")) {
                    NavigationLink(destination: DreamStoryView()) {
                        Label("梦境故事", systemImage: "book.closed.fill")
                    }
                    NavigationLink(destination: DreamVideoView()) {
                        Label("梦境视频", systemImage: "film")
                    }
                    NavigationLink(destination: DreamGraphView()) {
                        Label("梦境图谱", systemImage: "network")
                    }
                }
                
                Section(header: Text("社交")) {
                    NavigationLink(destination: DreamSocialFeedView()) {
                        Label("梦境动态", systemImage: "text.bubble.fill")
                    }
                    NavigationLink(destination: DreamShareHubView()) {
                        Label("分享中心", systemImage: "paperplane.fill")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("⚙️ 我的")
        }
    }
}

// MARK: - 预览

#Preview {
    ContentView()
        .environmentObject(DreamStore())
        .environmentObject(SpeechService())
        .environmentObject(AIService())
        .environmentObject(DreamChallengeService.shared)
}
