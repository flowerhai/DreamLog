//
//  FriendsView.swift
//  DreamLog
//
//  好友列表页面
//

import SwiftUI

struct FriendsView: View {
    @StateObject private var friendService: FriendService
    @ObservedObject var dreamStore: DreamStore
    @State private var selectedTab: FriendTab = .list
    @State private var showingAddFriend = false
    @State private var showingCreateCircle = false
    @State private var searchText = ""
    @State private var selectedFriend: Friend?
    @State private var showingShareSheet = false
    @State private var dreamToShare: Dream?
    
    enum FriendTab: String, CaseIterable {
        case list = "好友"
        case feed = "动态"
        case circles = "圈子"
        
        var icon: String {
            switch self {
            case .list: return "person.2"
            case .feed: return "newspaper"
            case .circles: return "person.3"
            }
        }
    }
    
    init(dreamStore: DreamStore) {
        _dreamStore = ObservedObject(wrappedValue: dreamStore)
        _friendService = StateObject(wrappedValue: FriendService())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部筛选器
                segmentPicker
                
                Divider()
                
                // 内容区域
                tabContent
            }
            .navigationTitle("好友")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == .list {
                        Button(action: { showingAddFriend = true }) {
                            Image(systemName: "person.badge.plus")
                        }
                    } else if selectedTab == .circles {
                        Button(action: { showingCreateCircle = true }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(friendService: friendService)
            }
            .sheet(isPresented: $showingCreateCircle) {
                CreateCircleView(friendService: friendService)
            }
            .sheet(item: $selectedFriend) { friend in
                FriendProfileView(friend: friend, friendService: friendService, dreamStore: dreamStore)
            }
        }
    }
    
    // MARK: - 分段选择器
    private var segmentPicker: some View {
        Picker("标签", selection: $selectedTab) {
            ForEach(FriendTab.allCases, id: \.self) { tab in
                Image(systemName: tab.icon)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    // MARK: - 标签内容
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .list:
            friendListView
        case .feed:
            friendFeedView
        case .circles:
            circlesView
        }
    }
    
    // MARK: - 好友列表
    private var friendListView: some View {
        Group {
            if friendService.friends.isEmpty {
                emptyStateView(
                    icon: "person.crop.circle.badge.plus",
                    title: "还没有好友",
                    subtitle: "添加好友，分享你的梦境"
                )
            } else {
                List {
                    // 特别关心
                    if friendService.friends.contains(where: { $0.isFavorite }) {
                        Section("特别关心 ⭐") {
                            ForEach(friendService.friends.filter { $0.isFavorite }) { friend in
                                FriendRowView(friend: friend) {
                                    selectedFriend = friend
                                }
                            }
                        }
                    }
                    
                    // 所有好友
                    Section("好友 (\(friendService.friends.count))") {
                        ForEach(friendService.friends.filter { !$0.isFavorite }) { friend in
                            FriendRowView(friend: friend) {
                                selectedFriend = friend
                            }
                        }
                    }
                    
                    // 待处理请求
                    if !friendService.pendingRequests.isEmpty {
                        Section("好友请求 (\(friendService.pendingRequests.count))") {
                            ForEach(friendService.pendingRequests) { request in
                                FriendRequestRowView(request: request, friendService: friendService)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText, prompt: "搜索好友")
    }
    
    // MARK: - 好友动态
    private var friendFeedView: some View {
        VStack(spacing: 0) {
            // 筛选器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FriendDreamFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.icon + " " + filter.rawValue,
                            isSelected: false
                        ) {
                            Task {
                                await friendService.fetchFriendDreams(filter: filter)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            
            if friendService.friendDreams.isEmpty {
                emptyStateView(
                    icon: "newspaper",
                    title: "暂无动态",
                    subtitle: "好友分享梦境后会显示在这里"
                )
            } else {
                List {
                    ForEach(friendService.friendDreams) { sharedDream in
                        FriendDreamRowView(
                            dream: sharedDream,
                            friendService: friendService
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            await friendService.fetchFriendDreams()
        }
    }
    
    // MARK: - 梦境圈
    private var circlesView: some View {
        Group {
            if friendService.dreamCircles.isEmpty {
                emptyStateView(
                    icon: "person.3",
                    title: "还没有梦境圈",
                    subtitle: "创建圈子，与好友私密分享"
                )
            } else {
                List {
                    ForEach(friendService.dreamCircles) { circle in
                        NavigationLink(destination: CircleDetailView(circle: circle, friendService: friendService)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "person.3.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                    
                                    VStack(alignment: .leading) {
                                        Text(circle.name)
                                            .font(.headline)
                                        Text("\(circle.members.count) 位成员 · \(circle.sharedDreams.count) 个梦境")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                
                                if !circle.description.isEmpty {
                                    Text(circle.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    // MARK: - 空状态视图
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if selectedTab == .list {
                Button(action: { showingAddFriend = true }) {
                    Label("添加好友", systemImage: "person.badge.plus")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 好友行视图
struct FriendRowView: View {
    let friend: Friend
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 头像
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 50, height: 50)
                
                if let avatar = friend.avatar {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                } else {
                    Text(String(friend.username.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.username)
                        .font(.headline)
                    
                    if friend.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                if !friend.bio.isEmpty {
                    Text(friend.bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    Label("\(friend.dreamCount)", systemImage: "moon.fill")
                    Label("\(friend.lucidDreamCount)", systemImage: "star.fill")
                    Label("\(friend.streakDays) 天", systemImage: "flame.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.purple, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 好友请求行视图
struct FriendRequestRowView: View {
    let request: FriendRequest
    @ObservedObject var friendService: FriendService
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(request.fromUsername.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromUsername)
                    .font(.headline)
                
                if !request.message.isEmpty {
                    Text(request.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("\(formatDate(request.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        await friendService.handleFriendRequest(request, accept: false)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    Task {
                        await friendService.handleFriendRequest(request, accept: true)
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 好友梦境行视图
struct FriendDreamRowView: View {
    let dream: SharedDream
    @ObservedObject var friendService: FriendService
    @State private var showingComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(dream.friendName.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading) {
                    Text(dream.friendName)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Text(formatDate(dream.sharedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if dream.isLucid {
                            Label("清醒梦", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        
                        Image(systemName: visibilityIcon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 8) {
                Text(dream.title)
                    .font(.headline)
                
                Text(dream.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                
                // 标签
                if !dream.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(dream.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // 互动
            HStack(spacing: 20) {
                Button(action: {
                    Task {
                        await friendService.addReaction(to: dream.dreamId, emoji: "❤️")
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("\(dream.reactionCount)")
                    }
                    .foregroundColor(.red)
                }
                
                Button(action: { showingComments = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                        Text("\(dream.commentCount)")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if let reaction = dream.userReaction {
                    Text(reaction)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var visibilityIcon: String {
        switch dream.visibility {
        case .friends: return "person.2.fill"
        case .circle: return "person.3.fill"
        case .publicShare: return "globe"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 预览
#Preview {
    FriendsView(dreamStore: DreamStore())
}
