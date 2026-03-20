//
//  SocialInteractionView.swift
//  DreamLog
//
//  Phase 60: 社交功能增强
//  社交互动主界面：活动动态、评论、收藏、关注、成就
//

import SwiftUI
import SwiftData

/// 社交互动主界面
struct SocialInteractionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [SocialActivity]
    @Query private var bookmarks: [SocialBookmarkCollection]
    
    @ObservedObject private var service = SocialInteractionService.shared
    @State private var selectedTab = 0
    @State private var showingCreateCollection = false
    @State private var selectedActivityFilter: ActivityType?
    
    private var userId: String {
        UserDefaults.standard.string(forKey: "userId") ?? "unknown"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标签页选择器
                Picker("社交", selection: $selectedTab) {
                    Text("动态").tag(0)
                    Text("收藏").tag(1)
                    Text("成就").tag(2)
                    Text("统计").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    ActivityFeedView(activities: activities, filter: $selectedActivityFilter)
                        .tag(0)
                    
                    BookmarkCollectionView(collections: bookmarks)
                        .tag(1)
                    
                    SocialAchievementView()
                        .tag(2)
                    
                    SocialStatsView()
                        .tag(3)
                }
            }
            .navigationTitle("社交")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if selectedTab == 1 {
                        Button(action: { showingCreateCollection = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateCollection) {
                CreateBookmarkCollectionView()
            }
        }
        .onAppear {
            Task {
                await service.refreshActivities()
            }
        }
    }
}

// MARK: - 活动动态 Feed

struct ActivityFeedView: View {
    let activities: [SocialActivity]
    @Binding var filter: ActivityType?
    @State private var showingFilterSheet = false
    
    private var filteredActivities: [SocialActivity] {
        guard let filter = filter else { return activities }
        return activities.filter { $0.type == filter.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            HStack {
                Text("活动动态")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingFilterSheet = true }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("筛选")
                            .font(.caption)
                    }
                }
            }
            .padding()
            
            if filteredActivities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("暂无动态")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("关注其他用户后，他们的活动将显示在这里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredActivities) { activity in
                            ActivityRowView(activity: activity)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            ActivityFilterSheet(selectedFilter: $filter)
        }
    }
}

struct ActivityRowView: View {
    let activity: SocialActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 用户头像
                AsyncImage(url: URL(string: activity.userAvatar ?? "")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(activityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(activity.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 梦境预览
            if let dreamTitle = activity.dreamTitle {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dreamTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let dreamExcerpt = activity.dreamExcerpt {
                        Text(dreamExcerpt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // 互动按钮
            HStack(spacing: 20) {
                Button(action: {}) {
                    Label(activity.likeCount.description, systemImage: "heart")
                }
                .foregroundColor(.red)
                
                Button(action: {}) {
                    Label(activity.commentCount.description, systemImage: "message")
                }
                .foregroundColor(.blue)
                
                Spacer()
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var activityDescription: String {
        switch activity.type {
        case "dreamPublished": return "发布了新梦境"
        case "dreamLiked": return "点赞了梦境"
        case "dreamCommented": return "评论了梦境"
        case "dreamBookmarked": return "收藏了梦境"
        case "userFollowed": return "关注了"
        case "achievementUnlocked": return "解锁了成就"
        case "challengeCompleted": return "完成了挑战"
        default: return "进行了互动"
        }
    }
}

struct ActivityFilterSheet: View {
    @Binding var selectedFilter: ActivityType?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("活动类型") {
                    Button("全部") {
                        selectedFilter = nil
                        dismiss()
                    }
                    .foregroundColor(selectedFilter == nil ? .accentColor : .primary)
                    
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            selectedFilter = type
                            dismiss()
                        }
                        .foregroundColor(selectedFilter == type ? .accentColor : .primary)
                    }
                }
            }
            .navigationTitle("筛选动态")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 收藏夹管理

struct BookmarkCollectionView: View {
    let collections: [SocialBookmarkCollection]
    @State private var showingCollectionDetail = false
    @State private var selectedCollection: SocialBookmarkCollection?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if collections.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("暂无收藏夹")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("点击右上角 + 创建第一个收藏夹")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(collections) { collection in
                        BookmarkCollectionCard(collection: collection)
                            .onTapGesture {
                                selectedCollection = collection
                                showingCollectionDetail = true
                            }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingCollectionDetail) {
            if let collection = selectedCollection {
                BookmarkCollectionDetailView(collection: collection)
            }
        }
    }
}

struct BookmarkCollectionCard: View {
    let collection: SocialBookmarkCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(collection.emoji)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.name)
                        .font(.headline)
                    
                    Text("\(collection.dreamIds.count) 个梦境")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: collection.isPublic ? "globe" : "lock")
                    .foregroundColor(.secondary)
            }
            
            if !collection.dreamIds.isEmpty {
                HStack(spacing: 8) {
                    ForEach(collection.dreamIds.prefix(3), id: \.self) { dreamId in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray4))
                            .aspectRatio(1, contentMode: .fit)
                    }
                    
                    if collection.dreamIds.count > 3 {
                        Text("+\(collection.dreamIds.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 60)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct CreateBookmarkCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var description = ""
    @State private var emoji = "🔖"
    @State private var isPublic = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("收藏夹名称", text: $name)
                    
                    TextField("描述 (可选)", text: $description)
                    
                    HStack {
                        Text("封面")
                        Spacer()
                        TextField("Emoji", text: $emoji)
                            .frame(width: 50)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("隐私设置") {
                    Toggle("公开收藏夹", isOn: $isPublic)
                    
                    if isPublic {
                        Text("公开收藏夹可被其他人查看和关注")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("私密收藏夹仅自己可见")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("新建收藏夹")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createCollection()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createCollection() {
        let collection = SocialBookmarkCollection(
            name: name,
            description: description,
            emoji: emoji,
            isPublic: isPublic
        )
        
        modelContext.insert(collection)
        
        try? modelContext.save()
        dismiss()
    }
}

struct BookmarkCollectionDetailView: View {
    let collection: SocialBookmarkCollection
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 头部信息
                VStack(spacing: 12) {
                    Text(collection.emoji)
                        .font(.system(size: 60))
                    
                    Text(collection.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if !collection.description.isEmpty {
                        Text(collection.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        Label("\(collection.dreamIds.count)", systemImage: "bookmark")
                        Label(collection.isPublic ? "公开" : "私密", systemImage: collection.isPublic ? "globe" : "lock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // 梦境列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(collection.dreamIds, id: \.self) { dreamId in
                            BookmarkDreamRow(dreamId: dreamId)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("收藏夹")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
    }
}

struct BookmarkDreamRow: View {
    let dreamId: UUID
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray4))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("梦境标题")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("2026 年 3 月 17 日")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "bookmark.fill")
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 社交统计视图

struct SocialStatsView: View {
    @State private var stats: SocialStats?
    @ObservedObject private var service = SocialInteractionService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 概览卡片
                StatsOverviewCard(stats: stats)
                
                // 详细统计
                DetailedStatsSection(stats: stats)
                
                // 成就进度
                AchievementProgressSection(stats: stats)
            }
            .padding()
        }
        .navigationTitle("社交统计")
        .task {
            await loadStats()
        }
    }
    
    private func loadStats() async {
        do {
            stats = try await service.getSocialStats()
        } catch {
            print("加载社交统计失败：\(error)")
            // 使用默认空统计
            stats = SocialStats(userId: "unknown")
        }
    }
}

struct StatsOverviewCard: View {
    let stats: SocialStats?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                SocialInteractStatItem(icon: "heart", value: "\(stats?.totalLikesReceived ?? 0)", label: "收到的赞")
                SocialInteractStatItem(icon: "message", value: "\(stats?.totalComments ?? 0)", label: "评论数")
                SocialInteractStatItem(icon: "bookmark", value: "\(stats?.totalBookmarks ?? 0)", label: "收藏数")
            }
            
            HStack(spacing: 20) {
                SocialInteractStatItem(icon: "person.2", value: "\(stats?.followersCount ?? 0)", label: "粉丝")
                SocialInteractStatItem(icon: "person.badge.plus", value: "\(stats?.followingCount ?? 0)", label: "关注")
                SocialInteractStatItem(icon: "star", value: "\(stats?.socialLevel ?? 1)", label: "等级")
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

struct SocialInteractStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailedStatsSection: View {
    let stats: SocialStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细统计")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatRow(label: "总互动次数", value: "\(stats?.totalInteractions ?? 0)")
                StatRow(label: "梦境被收藏次数", value: "\(stats?.dreamsBookmarkedByOthers ?? 0)")
                StatRow(label: "互相关注数", value: "\(stats?.mutualFollowsCount ?? 0)")
                StatRow(label: "影响力评分", value: "\(Int(stats?.influenceScore ?? 0))")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct AchievementProgressSection: View {
    let stats: SocialStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就进度")
                .font(.headline)
            
            HStack {
                ProgressView(value: Double(stats?.totalAchievements ?? 0), total: 8)
                    .progressViewStyle(.linear)
                
                Text("\(stats?.totalAchievements ?? 0)/8")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("已解锁 \(stats?.totalAchievements ?? 0) 个成就，共获得 \(stats?.socialPoints ?? 0) 积分")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - 预览

#Preview {
    SocialInteractionView()
        .modelContainer(for: SocialActivity.self, inMemory: true)
}
