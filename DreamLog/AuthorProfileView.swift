//
//  AuthorProfileView.swift
//  DreamLog
//
//  作者个人主页视图 - 展示作者统计和梦境列表
//  Phase 63: 社交功能增强
//
//  Created by DreamLog Dev on 2026-03-18.
//

import SwiftUI
import SwiftData

/// 作者个人主页视图
struct AuthorProfileView: View {
    let authorId: String
    @Environment(\.modelContext) private var modelContext
    @State private var author: SocialAuthor?
    @State private var authorDreams: [SocialDream] = []
    @State private var isLoading = false
    @State private var isFollowing = false
    @State private var showingStats = false
    @State private var showingMessageAlert = false
    @State private var showingShareSheet = false
    @State private var showingReportAlert = false
    @State private var shareText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    loadingView
                } else if let author = author {
                    // 头部信息
                    profileHeader(author: author)
                    
                    // 统计卡片
                    statsCards(author: author)
                    
                    // 操作按钮
                    actionButtons(author: author)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 作者梦境列表
                    authorDreamsSection
                } else {
                    errorView
                }
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("作者主页")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
        .alert("举报用户", isPresented: $showingReportAlert) {
            Button("取消", role: .cancel) { }
            Button("举报", role: .destructive) {
                // TODO: Submit report to server
                print("Report submitted for user: \(authorId)")
            }
        } message: {
            Text("确定要举报此用户吗？我们将审核该账户。")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
    }
    
    // MARK: - Subviews
    
    /// 加载状态
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载作者信息...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    /// 错误状态
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.5))
            
            Text("无法加载作者信息")
                .font(.headline)
            
            Button("重试") {
                Task {
                    await loadData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    /// 个人资料头部
    private func profileHeader(author: SocialAuthor) -> some View {
        VStack(spacing: 16) {
            // 头像
            if let avatarURL = author.avatarUrl, !avatarURL.isEmpty {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.purple.opacity(0.2)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            } else {
                Text(author.displayName.prefix(1).uppercased())
                    .font(.system(size: 40, weight: .bold))
                    .frame(width: 100, height: 100)
                    .background(Color.purple.opacity(0.2))
                    .clipShape(Circle())
            }
            
            // 用户名和简介
            VStack(spacing: 8) {
                Text(author.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let bio = author.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                // 加入时间
                Text("加入于 \(author.joinedAt.formatted(.dateTime.year().month()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 认证标识
            if author.isVerified {
                Label("认证创作者", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    /// 统计卡片
    private func statsCards(author: SocialAuthor) -> some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(author.dreamCount)",
                label: "梦境",
                icon: "moon.fill",
                color: .purple
            )
            
            StatCard(
                value: "\(author.followerCount)",
                label: "粉丝",
                icon: "person.2.fill",
                color: .blue
            )
            
            StatCard(
                value: "\(author.followingCount)",
                label: "关注",
                icon: "person.badge.plus",
                color: .green
            )
            
            StatCard(
                value: "\(author.influenceScore, specifier: "%.0f")",
                label: "影响力",
                icon: "star.fill",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
    
    /// 操作按钮
    private func actionButtons(author: SocialAuthor) -> some View {
        HStack(spacing: 12) {
            // 关注/取消关注按钮
            Button(action: toggleFollow) {
                Label(
                    isFollowing ? "已关注" : "关注",
                    systemImage: isFollowing ? "checkmark" : "person.badge.plus"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isFollowing ? .green : .purple)
            
            // 发消息按钮
            Button(action: {
                showingMessageAlert = true
            }) {
                Label("消息", systemImage: "message.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .alert("消息功能", isPresented: $showingMessageAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text("消息功能即将推出，敬请期待！")
            }
            
            // 更多选项
            Menu {
                Button("分享主页", systemImage: "square.and.arrow.up") {
                    shareProfile()
                }
                
                Button("举报用户", systemImage: "exclamationmark.triangle") {
                    showingReportAlert = true
                }
                
                if isFollowing {
                    Divider()
                    
                    Button("取消关注", systemImage: "person.badge.minus", role: .destructive) {
                        toggleFollow()
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    /// 作者梦境列表
    private var authorDreamsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TA 的梦境")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(authorDreams.count) 个梦境")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if authorDreams.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("还没有分享梦境")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(authorDreams.prefix(10), id: \.id) { dream in
                        SocialDreamCard(dream: dream)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Methods
    
    /// 加载数据
    @MainActor
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 获取作者信息
            let fetchDescriptor = FetchDescriptor<SocialAuthor>(
                predicate: #Predicate { $0.userId == authorId }
            )
            
            if let fetchedAuthor = try modelContext.fetch(fetchDescriptor).first {
                author = fetchedAuthor
                
                // 获取作者的梦境
                let dreamsDescriptor = FetchDescriptor<SocialDream>(
                    predicate: #Predicate { $0.authorId == authorId && $0.isPublic },
                    sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
                )
                
                authorDreams = try modelContext.fetch(dreamsDescriptor)
            }
        } catch {
            print("Failed to load author data: \(error)")
        }
    }
    
    /// 切换关注状态
    private func toggleFollow() {
        guard let author = author else { return }
        
        withAnimation {
            isFollowing.toggle()
        }
        
        // 更新 SwiftData
        Task {
            do {
                if isFollowing {
                    author.followerCount += 1
                } else {
                    author.followerCount = max(0, author.followerCount - 1)
                }
                modelContext.save()
            } catch {
                print("Failed to update follow status: \(error)")
                // 回滚
                withAnimation {
                    isFollowing.toggle()
                }
            }
        }
    }
    
    /// 分享主页
    private func shareProfile() {
        guard let author = author else { return }
        shareText = "来看看 @\(author.displayName) 在 DreamLog 上的梦境分享！"
        showingShareSheet = true
    }
}

// MARK: - StatCard

/// 统计卡片组件
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AuthorProfileView(authorId: "test-user-id")
    }
    .modelContainer(for: [SocialDream.self, SocialAuthor.self], inMemory: true)
}
