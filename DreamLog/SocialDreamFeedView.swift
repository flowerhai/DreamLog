//
//  SocialDreamFeedView.swift
//  DreamLog
//
//  社交梦境 Feed 流视图 - 展示公开梦境列表
//  Phase 63: 社交功能增强
//
//  Created by DreamLog Dev on 2026-03-18.
//

import SwiftUI
import SwiftData

/// 社交梦境 Feed 流视图
struct SocialDreamFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var socialDreams: [SocialDream] = []
    @State private var isLoading = false
    @State private var sortBy: SocialDreamSortOption = .popular
    @State private var showingFilters = false
    @State private var selectedMood: String?
    @State private var searchQuery = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if socialDreams.isEmpty {
                    emptyStateView
                } else {
                    dreamFeedList
                }
            }
            .navigationTitle("发现")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    refreshButton
                }
            }
            .searchable(text: $searchQuery, prompt: "搜索梦境...")
            .refreshable {
                await loadSocialDreams()
            }
            .task {
                await loadSocialDreams()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// 加载状态视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载梦境...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("还没有公开的梦境")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("成为第一个分享梦境的人吧！")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                // TODO: Navigate to share dream
            }) {
                Label("分享梦境", systemImage: "square.and.arrow.up")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 梦境 Feed 列表
    private var dreamFeedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 排序选项芯片
                sortChips
                
                // 梦境卡片列表
                ForEach(filteredDreams, id: \.id) { dream in
                    SocialDreamCard(dream: dream)
                        .onTapGesture {
                            // TODO: Navigate to dream detail
                        }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    /// 排序选项芯片
    private var sortChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SocialDreamSortOption.allCases, id: \.self) { option in
                    ChipView(
                        title: option.displayName,
                        isSelected: sortBy == option
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            sortBy = option
                            Task {
                                await loadSocialDreams()
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 筛选按钮
    private var filterButton: some View {
        Button(action: {
            showingFilters.toggle()
        }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title3)
        }
    }
    
    /// 刷新按钮
    private var refreshButton: some View {
        Button(action: {
            Task {
                await loadSocialDreams()
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.title3)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 筛选后的梦境列表
    private var filteredDreams: [SocialDream] {
        var dreams = socialDreams
        
        // 按搜索词筛选
        if !searchQuery.isEmpty {
            dreams = dreams.filter { dream in
                dream.title.localizedCaseInsensitiveContains(searchQuery) ||
                dream.preview.localizedCaseInsensitiveContains(searchQuery) ||
                dream.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
        
        // 按情绪筛选
        if let mood = selectedMood {
            dreams = dreams.filter { $0.mood == mood }
        }
        
        return dreams
    }
    
    // MARK: - Methods
    
    /// 加载社交梦境
    @MainActor
    private func loadSocialDreams() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchDescriptor = FetchDescriptor<SocialDream>(
                predicate: #Predicate { $0.isPublic },
                sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
            )
            
            let allDreams = try modelContext.fetch(fetchDescriptor)
            
            // 根据排序选项处理
            switch sortBy {
            case .latest:
                socialDreams = Array(allDreams.prefix(50))
            case .popular:
                socialDreams = allDreams
                    .sorted { $0.likeCount > $1.likeCount }
                    .prefix(50)
                    .map { $0 }
            case .mostCommented:
                socialDreams = allDreams
                    .sorted { $0.commentCount > $1.commentCount }
                    .prefix(50)
                    .map { $0 }
            case .mostViewed:
                socialDreams = allDreams
                    .sorted { $0.viewCount > $1.viewCount }
                    .prefix(50)
                    .map { $0 }
            }
        } catch {
            print("Failed to load social dreams: \(error)")
        }
    }
}

// MARK: - SocialDreamCard

/// 社交梦境卡片组件
struct SocialDreamCard: View {
    let dream: SocialDream
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部：作者信息
            authorHeader
            
            Divider()
            
            // 梦境内容
            dreamContent
            
            // 标签
            if !dream.tags.isEmpty {
                tagsSection
            }
            
            Divider()
            
            // 底部：统计和操作
            footerStats
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Subviews
    
    /// 作者信息头部
    private var authorHeader: some View {
        HStack(spacing: 12) {
            // 作者头像
            if let avatarURL = dream.authorAvatar, !avatarURL.isEmpty {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.purple.opacity(0.2)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                // 默认头像
                Text(dream.authorName.prefix(1).uppercased())
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Color.purple.opacity(0.2))
                    .clipShape(Circle())
            }
            
            // 作者信息
            VStack(alignment: .leading, spacing: 2) {
                Text(dream.authorName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let publishedAt = dream.publishedAt {
                    Text(publishedAt.relativeTimeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 清醒梦标识
            if dream.isLucid {
                Label("清醒梦", systemImage: "eye.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    /// 梦境内容
    private var dreamContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dream.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(dream.preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
    }
    
    /// 标签部分
    private var tagsSection: some View {
        FlowLayout(spacing: 6) {
            ForEach(dream.tags.prefix(5), id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
    
    /// 底部统计
    private var footerStats: some View {
        HStack(spacing: 20) {
            // 点赞
            Label("\(dream.likeCount)", systemImage: "heart.fill")
                .font(.caption)
                .foregroundColor(.pink)
            
            // 评论
            Label("\(dream.commentCount)", systemImage: "message.fill")
                .font(.caption)
                .foregroundColor(.blue)
            
            // 收藏
            Label("\(dream.bookmarkCount)", systemImage: "bookmark.fill")
                .font(.caption)
                .foregroundColor(.orange)
            
            // 浏览
            Label("\(dream.viewCount)", systemImage: "eye.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // 分享按钮
            Button(action: {
                // TODO: Share dream
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
        }
    }
}

// MARK: - Helpers

extension SocialDreamSortOption {
    var displayName: String {
        switch self {
        case .latest:
            return "最新"
        case .popular:
            return "热门"
        case .mostCommented:
            return "最多评论"
        case .mostViewed:
            return "最多浏览"
        }
    }
}

extension Date {
    var relativeTimeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - FlowLayout

/// 简单的流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            let point = result.locations[index]
            subview.place(at: point, proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var locations: [CGPoint] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                locations.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - ChipView

/// 芯片按钮组件
struct ChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .purple)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.purple.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Preview

#Preview {
    SocialDreamFeedView()
        .modelContainer(for: SocialDream.self, inMemory: true)
}
