//
//  DreamRecommendationsView.swift
//  DreamLog
//
//  Phase 55 - AI 梦境推荐与智能洞察
//  推荐界面
//

import SwiftUI
import SwiftData

struct DreamRecommendationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamRecommendation.createdAt, order: .reverse) private var recommendations: [DreamRecommendation]
    
    @State private var selectedFilter: RecommendationFilter = .all
    @State private var showingConfig = false
    @State private var refreshTrigger = false
    
    private var filteredRecommendations: [DreamRecommendation] {
        let activeRecs = recommendations.filter { !$0.isDismissed && !$0.isExpired }
        
        switch selectedFilter {
        case .all:
            return activeRecs
        case .unread:
            return activeRecs.filter { !$0.isRead }
        case .liked:
            return activeRecs.filter { $0.isLiked }
        case .meditation:
            return activeRecs.filter { $0.type == .meditation }
        case .music:
            return activeRecs.filter { $0.type == .music }
        case .inspiration:
            return activeRecs.filter { $0.type == .inspiration }
        case .lucidTraining:
            return activeRecs.filter { $0.type == .lucidTraining }
        }
    }
    
    private var unreadCount: Int {
        recommendations.filter { !$0.isRead && !$0.isDismissed && !$0.isExpired }.count
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredRecommendations.isEmpty {
                    EmptyStateView()
                } else {
                    recommendationsList
                }
            }
            .navigationTitle("智能推荐")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if unreadCount > 0 {
                            BadgeView(count: unreadCount)
                                .accessibilityLabel("\(unreadCount) 条未读推荐")
                                .accessibilityHint("查看未读的智能推荐数量")
                        }
                        Button(action: { showingConfig = true }) {
                            Image(systemName: "gearshape")
                                .accessibilityLabel("推荐设置")
                                .accessibilityHint("双击打开推荐配置界面")
                        }
                    }
                }
            }
            .refreshable {
                await refreshRecommendations()
            }
            .sheet(isPresented: $showingConfig) {
                RecommendationConfigView()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("智能推荐页面")
        .accessibilityHint("浏览和管理 AI 生成的梦境推荐")
    }
    
    private var recommendationsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 筛选器
                filterChips
                
                // 推荐列表
                ForEach(filteredRecommendations, id: \.id) { recommendation in
                    RecommendationCard(
                        recommendation: recommendation,
                        onRead: { await markAsRead(recommendation) },
                        onLike: { await markAsLiked(recommendation) },
                        onDismiss: { await markAsDismissed(recommendation) }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecommendationFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                    .accessibilityLabel("\(filter.displayName) 筛选")
                    .accessibilityHint(selectedFilter == filter ? "已选中" : "双击筛选\(filter.displayName)推荐")
                    .accessibilityState(selectedFilter == filter ? .isSelected : .notSelected)
                }
            }
            .accessibilityLabel("推荐筛选器")
            .accessibilityHint("左右滑动浏览筛选选项，双击选择筛选条件")
        }
    }
    
    private func refreshRecommendations() async {
        // 触发刷新逻辑
        refreshTrigger.toggle()
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func markAsRead(_ recommendation: DreamRecommendation) async {
        do {
            recommendation.isRead = true
            try modelContext.save()
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }
    
    private func markAsLiked(_ recommendation: DreamRecommendation) async {
        do {
            recommendation.isLiked = true
            try modelContext.save()
        } catch {
            print("Failed to mark as liked: \(error)")
        }
    }
    
    private func markAsDismissed(_ recommendation: DreamRecommendation) async {
        do {
            recommendation.isDismissed = true
            try modelContext.save()
        } catch {
            print("Failed to dismiss: \(error)")
        }
    }
}

// MARK: - 推荐卡片组件

struct RecommendationCard: View {
    let recommendation: DreamRecommendation
    let onRead: () async -> Void
    let onLike: () async -> Void
    let onDismiss: () async -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Image(systemName: recommendation.type.icon)
                    .font(.title2)
                    .foregroundColor(Color(recommendation.type.color))
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading) {
                    Text(recommendation.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(recommendation.title)
                        .font(.headline)
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                
                // 置信度指示器
                ConfidenceIndicator(confidence: recommendation.confidence)
                    .accessibilityLabel("置信度 \(Int(recommendation.confidence * 100))%")
                    .accessibilityHint("推荐的可信程度")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(recommendation.type.displayName): \(recommendation.title)")
            .accessibilityHint("置信度 \(Int(recommendation.confidence * 100))%")
            
            // 描述
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.primary)
            
            // 推荐理由
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Label("推荐理由", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(recommendation.reason)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 相关梦境
                    if !recommendation.relatedDreamIds.isEmpty {
                        Label("关联梦境：\(recommendation.relatedDreamIds.count)", systemImage: "moon.stars.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity)
            }
            
            // 操作按钮
            HStack {
                Button(action: { Task { await onRead() } }) {
                    Label(recommendation.isRead ? "已读" : "标记为已读", systemName: "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .accessibilityLabel(recommendation.isRead ? "已标记为已读" : "标记为已读")
                .accessibilityHint(recommendation.isRead ? "已阅读此推荐" : "双击标记此推荐为已读")
                
                Button(action: { Task { await onLike() } }) {
                    Image(systemName: recommendation.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(recommendation.isLiked ? .red : .gray)
                }
                .accessibilityLabel(recommendation.isLiked ? "已喜欢" : "喜欢")
                .accessibilityHint(recommendation.isLiked ? "已收藏此推荐" : "双击收藏此推荐")
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(isExpanded ? "收起详情" : "展开详情")
                .accessibilityHint(isExpanded ? "双击收起推荐理由" : "双击展开查看推荐理由")
                
                Button(action: { Task { await onDismiss() } }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("关闭推荐")
                .accessibilityHint("双击关闭并隐藏此推荐")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("推荐操作")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            if !recommendation.isRead {
                Task { await onRead() }
            }
        }
    }
}

// MARK: - 置信度指示器

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        VStack {
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
            
            ProgressView(value: confidence)
                .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))
                .frame(width: 40)
        }
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.7 {
            return .green
        } else if confidence >= 0.4 {
            return .yellow
        } else {
            return .orange
        }
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
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .accessibilityLabel("\(title) 筛选")
        .accessibilityHint(isSelected ? "已选中\(title)筛选" : "双击选择\(title)筛选")
        .accessibilityState(isSelected ? .isSelected : .notSelected)
    }
}

// MARK: - 空状态视图

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .accessibilityHidden(true)
            
            Text("暂无推荐")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("继续记录梦境，获取更多个性化推荐")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("暂无推荐")
        .accessibilityHint("继续记录梦境，获取更多个性化推荐")
    }
}

// MARK: - 徽章视图

struct BadgeView: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red)
            .clipShape(Circle())
    }
}

// MARK: - 推荐筛选枚举

enum RecommendationFilter: String, CaseIterable {
    case all = "全部"
    case unread = "未读"
    case liked = "已喜欢"
    case meditation = "冥想"
    case music = "音乐"
    case inspiration = "灵感"
    case lucidTraining = "清醒梦"
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .unread: return "未读"
        case .liked: return "已喜欢"
        case .meditation: return "冥想"
        case .music: return "音乐"
        case .inspiration: return "灵感"
        case .lucidTraining: return "清醒梦"
        }
    }
}

// MARK: - 推荐配置视图

struct RecommendationConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("enableSimilarDreams") private var enableSimilarDreams = true
    @AppStorage("enableMeditationRecommendations") private var enableMeditation = true
    @AppStorage("enableMusicRecommendations") private var enableMusic = true
    @AppStorage("enableInspirationRecommendations") private var enableInspiration = true
    @AppStorage("enableLucidTrainingRecommendations") private var enableLucid = true
    @AppStorage("minConfidenceThreshold") private var minConfidence = 0.3
    
    var body: some View {
        NavigationStack {
            Form {
                Section("推荐类型") {
                    Toggle("相似梦境", isOn: $enableSimilarDreams)
                    Toggle("冥想推荐", isOn: $enableMeditation)
                    Toggle("音乐推荐", isOn: $enableMusic)
                    Toggle("灵感提示", isOn: $enableInspiration)
                    Toggle("清醒梦训练", isOn: $enableLucid)
                }
                
                Section("高级设置") {
                    Slider(value: $minConfidence, in: 0...1, step: 0.1) {
                        Text("最低置信度：\(Int(minConfidence * 100))%")
                    }
                }
                
                Section {
                    Button("重置为默认") {
                        enableSimilarDreams = true
                        enableMeditation = true
                        enableMusic = true
                        enableInspiration = true
                        enableLucid = true
                        minConfidence = 0.3
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("推荐设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DreamRecommendationsView()
        .modelContainer(for: DreamRecommendation.self, inMemory: true)
}
