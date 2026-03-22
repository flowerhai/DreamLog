//
//  FriendProfileView.swift
//  DreamLog
//
//  好友个人主页
//

import SwiftUI

struct FriendProfileView: View {
    let friend: Friend
    @ObservedObject var friendService: FriendService
    @ObservedObject var dreamStore: DreamStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var dreamToShare: Dream?
    @State private var selectedDream: Dream?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头部信息
                headerSection
                
                // 统计数据
                statsSection
                
                // 操作按钮
                actionButtons
                
                Divider()
                
                // 好友的梦境
                dreamsSection
            }
            .padding()
        }
        .navigationTitle(friend.username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        Task {
                            await friendService.toggleFavorite(friend)
                        }
                    }) {
                        Label(friend.isFavorite ? "取消特别关心" : "设为特别关心",
                              systemImage: friend.isFavorite ? "star.slash" : "star")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await friendService.removeFriend(friend)
                            dismiss()
                        }
                    } {
                        Label("删除好友", systemImage: "person.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
    
    // MARK: - 头部
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .blue, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Text(String(friend.username.prefix(1)))
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // 用户名
            Text(friend.username)
                .font(.title)
                .fontWeight(.bold)
            
            // 签名
            if !friend.bio.isEmpty {
                Text(friend.bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 活跃状态
            HStack(spacing: 8) {
                Circle()
                    .fill(isOnline ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(isOnline ? "在线" : lastActiveText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 统计数据
    private var statsSection: some View {
        HStack(spacing: 20) {
            StatView(
                value: "\(friend.dreamCount)",
                label: "梦境",
                icon: "moon.fill"
            )
            
            StatView(
                value: "\(friend.lucidDreamCount)",
                label: "清醒梦",
                icon: "star.fill"
            )
            
            StatView(
                value: "\(friend.streakDays)",
                label: "连续天数",
                icon: "flame.fill"
            )
        }
    }
    
    // MARK: - 操作按钮
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showingShareSheet = true }) {
                Label("分享梦境", systemImage: "paperplane")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                // 发送消息
            }) {
                Label("发消息", systemImage: "message")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - 梦境列表
    private var dreamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("梦境记录")
                .font(.headline)
            
            if friend.dreamCount == 0 {
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("还没有梦境记录")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(0..<min(5, friend.dreamCount), id: \.self) { index in
                    DreamPreviewCard(index: index)
                }
                
                if friend.dreamCount > 5 {
                    Button(action: {
                        // 查看更多
                    }) {
                        Text("查看全部 \(friend.dreamCount) 个梦境")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助属性
    private var isOnline: Bool {
        guard let lastActive = friend.lastActiveAt else { return false }
        return Date().timeIntervalSince(lastActive) < 300 // 5 分钟内
    }
    
    private var lastActiveText: String {
        guard let lastActive = friend.lastActiveAt else { return "未知" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastActive, relativeTo: Date())
    }
}

// MARK: - 统计视图
struct StatView: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 梦境预览卡片
struct DreamPreviewCard: View {
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("梦境 #\(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("这是好友的私密梦境，仅对好友可见...")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label("2026-03-\(7 - index)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.caption)
                    Text("\(Int.random(in: 1...10))")
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 圈子详情视图
struct DreamCircleDetailView: View {
    let circle: DreamCircle
    @ObservedObject var friendService: FriendService
    @Environment(\.dismiss) private var dismiss
    @State private var showingMembers = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部
                VStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                    
                    Text(circle.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if !circle.description.isEmpty {
                        Text(circle.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 16) {
                        Label("\(circle.members.count) 位成员", systemImage: "person.2")
                        Label("\(circle.sharedDreams.count) 个梦境", systemImage: "moon.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // 成员列表
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("成员")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("查看全部") {
                            showingMembers = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(circle.members) { member in
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text(String(member.username.prefix(1)))
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text(member.username)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // 共享梦境
                VStack(alignment: .leading, spacing: 12) {
                    Text("共享梦境")
                        .font(.headline)
                    
                    if circle.sharedDreams.isEmpty {
                        Text("还没有共享梦境")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(circle.sharedDreams, id: \.id) { dream in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(dream.title)
                                    .font(.headline)
                                
                                Text(dream.content)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(circle.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        FriendProfileView(
            friend: Friend(
                userId: "test",
                username: "测试好友",
                bio: "热爱记录梦境",
                dreamCount: 128,
                lucidDreamCount: 23,
                streakDays: 45
            ),
            friendService: FriendService(),
            dreamStore: DreamStore()
        )
    }
}
