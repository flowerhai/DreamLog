//
//  ContentView.swift
//  DreamLog
//
//  Phase 43 - 导航重构：5 个主标签
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @StateObject private var challengeService = DreamChallengeService.shared
    @StateObject private var favoriteManager = FavoriteManager.shared
    @AppStorage("selectedMainTab") private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 📖 梦境
            DreamsNavigationView()
                .environmentObject(dreamStore)
                .tabItem {
                    Image(systemName: MainTab.dreams.icon)
                    Text(MainTab.dreams.title)
                }
                .tag(0)
            
            // 📊 分析
            InsightsNavigationView()
                .environmentObject(dreamStore)
                .tabItem {
                    Image(systemName: MainTab.insights.icon)
                    Text(MainTab.insights.title)
                }
                .tag(1)
            
            // 🎮 探索
            ExploreNavigationView()
                .environmentObject(dreamStore)
                .environmentObject(challengeService)
                .tabItem {
                    Image(systemName: MainTab.explore.icon)
                    Text(MainTab.explore.title)
                }
                .tag(2)
            
            // 🧘 成长
            GrowthNavigationView()
                .environmentObject(dreamStore)
                .tabItem {
                    Image(systemName: MainTab.growth.icon)
                    Text(MainTab.growth.title)
                }
                .tag(3)
            
            // ⚙️ 我的
            ProfileNavigationView()
                .environmentObject(dreamStore)
                .environmentObject(challengeService)
                .tabItem {
                    Image(systemName: MainTab.profile.icon)
                    Text(MainTab.profile.title)
                }
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
    }
}

// MARK: - 📖 梦境导航

struct DreamsNavigationView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedViewId: String = "home"
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("常用功能")) {
                    NavigationLink(destination: HomeView(), tag: "home", selection: $selectedViewId) {
                        Label("梦境列表", systemImage: "list.bullet")
                    }
                    NavigationLink(destination: CalendarView(), tag: "calendar", selection: $selectedViewId) {
                        Label("日历视图", systemImage: "calendar")
                    }
                    NavigationLink(destination: QuickAddView(), tag: "quick-add", selection: $selectedViewId) {
                        Label("快速记录", systemImage: "plus.circle.fill")
                    }
                }
                
                Section(header: Text("搜索")) {
                    NavigationLink(destination: GlobalSearchView(), tag: "search", selection: $selectedViewId) {
                        Label("全局搜索", systemImage: "magnifyingglass")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("📖 梦境")
        }
    }
}

// MARK: - 📊 分析导航

struct InsightsNavigationView: View {
    @EnvironmentObject var dreamStore: DreamStore
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("核心分析")) {
                    NavigationLink(destination: InsightsView()) {
                        Label("数据洞察", systemImage: "chart.bar")
                    }
                    NavigationLink(destination: DreamInsightsDashboardView()) {
                        Label("AI 解析", systemImage: "brain.head.profile")
                    }
                }
                
                Section(header: Text("高级功能")) {
                    NavigationLink(destination: DreamPredictionView()) {
                        Label("梦境预测", systemImage: "crystal.ball")
                    }
                    NavigationLink(destination: DreamWrappedView()) {
                        Label("梦境回顾", systemImage: "sparkles")
                    }
                    NavigationLink(destination: AdvancedDashboardView()) {
                        Label("高级统计", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("📊 分析")
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
