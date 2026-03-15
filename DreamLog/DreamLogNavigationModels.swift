//
//  DreamLogNavigationModels.swift
//  DreamLog
//
//  Phase 43 - 导航重构数据模型
//

import SwiftUI

// MARK: - 主标签枚举

/// 5 个主标签分类
enum MainTab: Int, CaseIterable {
    case dreams      // 📖 梦境
    case insights    // 📊 分析
    case explore     // 🎮 探索
    case growth      // 🧘 成长
    case profile     // ⚙️ 我的
    
    /// 标签标题
    var title: String {
        switch self {
        case .dreams: return "梦境"
        case .insights: return "分析"
        case .explore: return "探索"
        case .growth: return "成长"
        case .profile: return "我的"
        }
    }
    
    /// 标签图标
    var icon: String {
        switch self {
        case .dreams: return "book.fill"
        case .insights: return "chart.bar.fill"
        case .explore: return "compass.fill"
        case .growth: return "leaf.fill"
        case .profile: return "person.circle.fill"
        }
    }
    
    /// 标签颜色
    var color: Color {
        switch self {
        case .dreams: return Color(hex: "9B7EBD")
        case .insights: return Color(hex: "5B9BD5")
        case .explore: return Color(hex: "ED7D31")
        case .growth: return Color(hex: "70AD47")
        case .profile: return Color(hex: "FFC000")
        }
    }
    
    /// 该分类下的所有视图
    var views: [NavigationViewItem] {
        switch self {
        case .dreams:
            return [
                NavigationViewItem(id: "home", title: "梦境列表", icon: "list.bullet", destination: AnyView(HomeView()), isFavorite: true),
                NavigationViewItem(id: "calendar", title: "日历视图", icon: "calendar", destination: AnyView(CalendarView()), isFavorite: true),
                NavigationViewItem(id: "quick-add", title: "快速记录", icon: "plus.circle.fill", destination: AnyView(QuickAddView()), isFavorite: true),
                NavigationViewItem(id: "search", title: "搜索", icon: "magnifyingglass", destination: AnyView(GlobalSearchView()), isFavorite: false)
            ]
        case .insights:
            return [
                NavigationViewItem(id: "insights", title: "数据洞察", icon: "chart.bar", destination: AnyView(InsightsView()), isFavorite: true),
                NavigationViewItem(id: "ai-analysis", title: "AI 解析", icon: "brain.head.profile", destination: AnyView(DreamInsightsDashboardView()), isFavorite: true),
                NavigationViewItem(id: "prediction", title: "梦境预测", icon: "crystal.ball", destination: AnyView(DreamPredictionView()), isFavorite: false),
                NavigationViewItem(id: "wrapped", title: "梦境回顾", icon: "sparkles", destination: AnyView(DreamWrappedView()), isFavorite: false),
                NavigationViewItem(id: "advanced-stats", title: "高级统计", icon: "chart.line.uptrend.xyaxis", destination: AnyView(AdvancedDashboardView()), isFavorite: false)
            ]
        case .explore:
            return [
                NavigationViewItem(id: "community", title: "梦境社区", icon: "globe", destination: AnyView(CommunityView()), isFavorite: true),
                NavigationViewItem(id: "friends", title: "好友", icon: "person.2.fill", destination: AnyView(FriendsView()), isFavorite: false),
                NavigationViewItem(id: "challenges", title: "挑战", icon: "trophy.fill", destination: AnyView(DreamChallengeView()), isFavorite: true),
                NavigationViewItem(id: "share-circle", title: "分享圈", icon: "person.3.fill", destination: AnyView(DreamShareCircleView()), isFavorite: false),
                NavigationViewItem(id: "gallery", title: "梦境画廊", icon: "photo.on.rectangle", destination: AnyView(GalleryView()), isFavorite: false)
            ]
        case .growth:
            return [
                NavigationViewItem(id: "sleep", title: "睡眠数据", icon: "moon.stars.fill", destination: AnyView(SleepDataView()), isFavorite: true),
                NavigationViewItem(id: "meditation", title: "冥想音乐", icon: "music.note.house", destination: AnyView(MeditationView()), isFavorite: false),
                NavigationViewItem(id: "incubation", title: "梦境孵育", icon: "sparkles", destination: AnyView(DreamIncubationView()), isFavorite: false),
                NavigationViewItem(id: "lucid-training", title: "清醒梦训练", icon: "brain.head.profile", destination: AnyView(LucidTrainingView()), isFavorite: false),
                NavigationViewItem(id: "goals", title: "梦境目标", icon: "target", destination: AnyView(DreamsGoalView()), isFavorite: false),
                NavigationViewItem(id: "dictionary", title: "梦境词典", icon: "text.book.closed.fill", destination: AnyView(DreamDictionaryView()), isFavorite: false),
                NavigationViewItem(id: "music", title: "梦境音乐", icon: "music.note.house.fill", destination: AnyView(DreamMusicView()), isFavorite: false),
                NavigationViewItem(id: "reflections", title: "反思日记", icon: "book.closed.fill", destination: AnyView(DreamReflectionView()), isFavorite: false)
            ]
        case .profile:
            return [
                NavigationViewItem(id: "settings", title: "设置", icon: "gearshape.fill", destination: AnyView(SettingsView()), isFavorite: true),
                NavigationViewItem(id: "backup", title: "备份恢复", icon: "externaldrive.fill", destination: AnyView(DreamBackupView()), isFavorite: false),
                NavigationViewItem(id: "time-capsule", title: "时间胶囊", icon: "hourglass.badge.fill", destination: AnyView(DreamTimeCapsuleView()), isFavorite: false),
                NavigationViewItem(id: "story", title: "梦境故事", icon: "book.closed.fill", destination: AnyView(DreamStoryView()), isFavorite: false),
                NavigationViewItem(id: "video", title: "梦境视频", icon: "film", destination: AnyView(DreamVideoView()), isFavorite: false),
                NavigationViewItem(id: "assistant", title: "AI 助手", icon: "message.fill", destination: AnyView(DreamAssistantView()), isFavorite: false),
                NavigationViewItem(id: "graph", title: "梦境图谱", icon: "network", destination: AnyView(DreamGraphView()), isFavorite: false)
            ]
        }
    }
    
    /// 获取默认视图
    var defaultView: NavigationViewItem {
        views.first ?? NavigationViewItem(id: "home", title: "首页", icon: "house", destination: AnyView(HomeView()), isFavorite: true)
    }
}

// MARK: - 导航视图项

/// 单个导航视图项
struct NavigationViewItem: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let destination: AnyView
    var isFavorite: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NavigationViewItem, rhs: NavigationViewItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 收藏夹管理

/// 收藏夹管理器
class FavoriteManager: ObservableObject {
    static let shared = FavoriteManager()
    
    @AppStorage("favoriteViewIds") private var favoriteViewIds: String = ""
    
    @Published var favorites: Set<String> = []
    
    init() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        favorites = Set(favoriteViewIds.components(separatedBy: ",").filter { !$0.isEmpty })
    }
    
    func toggleFavorite(_ viewId: String) {
        if favorites.contains(viewId) {
            favorites.remove(viewId)
        } else {
            favorites.insert(viewId)
        }
        saveFavorites()
    }
    
    func isFavorite(_ viewId: String) -> Bool {
        favorites.contains(viewId)
    }
    
    private func saveFavorites() {
        favoriteViewIds = favorites.joined(separator: ",")
    }
}

// MARK: - 导航历史

/// 导航历史管理器
class NavigationHistory: ObservableObject {
    static let shared = NavigationHistory()
    
    @Published var history: [String] = []
    @Published var currentIndex: Int = -1
    
    func push(_ viewId: String) {
        if currentIndex < history.count - 1 {
            history.removeSubrange((currentIndex + 1)...)
        }
        history.append(viewId)
        currentIndex = history.count - 1
    }
    
    func pop() -> String? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        return history[currentIndex]
    }
    
    func clear() {
        history.removeAll()
        currentIndex = -1
    }
}

// MARK: - 快捷操作

/// 快捷操作类型
enum QuickAction: String, CaseIterable {
    case addDream = "add_dream"
    case voiceRecord = "voice_record"
    case scanQR = "scan_qr"
    case arCapture = "ar_capture"
    case todayStats = "today_stats"
    case weeklyReport = "weekly_report"
    
    var title: String {
        switch self {
        case .addDream: return "记录梦境"
        case .voiceRecord: return "语音记录"
        case .scanQR: return "扫描二维码"
        case .arCapture: return "AR 捕获"
        case .todayStats: return "今日统计"
        case .weeklyReport: return "周报"
        }
    }
    
    var icon: String {
        switch self {
        case .addDream: return "plus.circle.fill"
        case .voiceRecord: return "mic.fill"
        case .scanQR: return "qrcode.viewfinder"
        case .arCapture: return "viewfinder"
        case .todayStats: return "chart.bar.fill"
        case .weeklyReport: return "doc.richtext.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .addDream: return Color(hex: "9B7EBD")
        case .voiceRecord: return Color(hex: "5B9BD5")
        case .scanQR: return Color(hex: "ED7D31")
        case .arCapture: return Color(hex: "70AD47")
        case .todayStats: return Color(hex: "FFC000")
        case .weeklyReport: return Color(hex: "FF6B6B")
        }
    }
}

// MARK: - 搜索结果

/// 搜索结果类型
enum SearchResultType {
    case dream(Dream)
    case tag(String)
    case emotion(String)
    case communityPost(SharedDream)
    case challenge(DreamChallenge)
    
    var title: String {
        switch self {
        case .dream(let dream): return dream.title.isEmpty ? "无标题梦境" : dream.title
        case .tag(let tag): return "#\(tag)"
        case .emotion(let emotion): return emotion
        case .communityPost(let post): return post.dreamTitle
        case .challenge(let challenge): return challenge.title
        }
    }
    
    var subtitle: String {
        switch self {
        case .dream(let dream):
            return dream.formattedDate
        case .tag(let tag):
            return "\(DreamStore.shared.dreams.filter { $0.tags.contains(tag) }.count) 个梦境"
        case .emotion(let emotion):
            return "\(DreamStore.shared.dreams.filter { $0.emotions.contains(where: { $0.rawValue == emotion }) }.count) 个梦境"
        case .communityPost(let post):
            return "社区帖子 • \(post.author?.anonymousId ?? "匿名用户")"
        case .challenge(let challenge):
            return challenge.type.displayName
        }
    }
    
    var icon: String {
        switch self {
        case .dream: return "moon.fill"
        case .tag: return "tag.fill"
        case .emotion: return "heart.fill"
        case .communityPost: return "globe"
        case .challenge: return "trophy.fill"
        }
    }
}

/// 搜索结果
struct SearchResult: Identifiable {
    let id = UUID()
    let type: SearchResultType
    let relevance: Double
    
    var title: String { type.title }
    var subtitle: String { type.subtitle }
    var icon: String { type.icon }
}
