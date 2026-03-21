//
//  DreamSmartInsightsView.swift
//  DreamLog
//
//  Phase 78: Smart Dream Insights & Notifications
//  智能梦境洞察与通知界面
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct DreamSmartInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: InsightsViewModel
    @State private var selectedFilter: InsightFilter = .all
    @State private var showingSettings = false
    
    enum InsightFilter: String, CaseIterable {
        case all = "全部"
        case unread = "未读"
        case saved = "已保存"
        case highPriority = "高优先级"
    }
    
    init() {
        _viewModel = StateObject(wrappedValue: InsightsViewModel())
    }
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: InsightsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.insights.isEmpty {
                    emptyView
                } else {
                    insightsList
                }
            }
            .navigationTitle("智能洞察")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.insights.isEmpty && selectedFilter == .unread {
                        Button("全部已读") {
                            viewModel.markAllAsRead()
                        }
                        .font(.caption)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                InsightSettingsView()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadInsights(filter: selectedFilter)
            }
        }
        .onChange(of: selectedFilter) { _, newFilter in
            Task {
                await viewModel.loadInsights(filter: newFilter)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在生成洞察...")
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无洞察")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("继续记录梦境，智能洞察会基于你的梦境数据生成个性化分析")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink("立即记录", destination: QuickAddView())
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 100)
    }
    
    private var insightsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 统计卡片
                statisticsCard
                
                // 筛选器
                filterChips
                
                // 洞察列表
                ForEach(filteredInsights, id: \.id) { insight in
                    InsightCard(
                        insight: insight,
                        onRead: { viewModel.markAsRead(insightId: insight.id) },
                        onSave: { viewModel.toggleSave(insightId: insight.id) },
                        onDelete: { viewModel.deleteInsight(insightId: insight.id) }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var statisticsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("洞察概览")
                        .font(.headline)
                    Text("共 \(viewModel.statistics.totalInsights) 个洞察")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    StatBadge(
                        value: viewModel.statistics.unreadCount,
                        label: "未读",
                        color: .blue
                    )
                    StatBadge(
                        value: viewModel.statistics.savedCount,
                        label: "已保存",
                        color: .orange
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InsightFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var filteredInsights: [DreamSmartInsight] {
        switch selectedFilter {
        case .all:
            return viewModel.insights
        case .unread:
            return viewModel.insights.filter { !$0.isRead }
        case .saved:
            return viewModel.insights.filter { $0.isSaved }
        case .highPriority:
            return viewModel.insights.filter { $0.priority == .high || $0.priority == .urgent }
        }
    }
    
    private func countForFilter(_ filter: InsightFilter) -> Int {
        switch filter {
        case .all:
            return viewModel.insights.count
        case .unread:
            return viewModel.insights.filter { !$0.isRead }.count
        case .saved:
            return viewModel.insights.filter { $0.isSaved }.count
        case .highPriority:
            return viewModel.insights.filter { $0.priority == .high || $0.priority == .urgent }.count
        }
    }
}

// MARK: - 洞察卡片组件

@available(iOS 17.0, *)
struct InsightCard: View {
    let insight: DreamSmartInsight
    let onRead: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDetail = false
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                // 类型图标
                Text(insight.type.icon)
                    .font(.title2)
                    .padding(8)
                    .background(Color(insight.type.color).opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // 优先级标识
                        PriorityBadge(priority: insight.priority)
                        
                        // 置信度
                        Text("\(Int(insight.confidence * 100))% 置信")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(insight.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 8) {
                    Button(action: onSave) {
                        Image(systemName: insight.isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundColor(insight.isSaved ? .orange : .gray)
                    }
                    
                    Button(action: { showingDeleteConfirm = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // 内容
            Text(insight.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
            
            // 行动建议
            if let suggestion = insight.actionSuggestion {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("建议")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                    }
                    
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 标签
            if !insight.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(insight.tags.prefix(5), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
            
            // 未读标识
            if !insight.isRead {
                Button("标记为已读") {
                    onRead()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            InsightDetailView(insight: insight)
        }
        .alert("删除洞察", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除这条洞察吗？此操作不可撤销。")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 优先级徽章

struct PriorityBadge: View {
    let priority: InsightPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(priority.color).opacity(0.1))
            .foregroundColor(Color(priority.color))
            .cornerRadius(4)
    }
}

// MARK: - 统计徽章

struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 筛选芯片

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("(\(count))")
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .cornerRadius(16)
        }
    }
}

// MARK: - 洞察详情视图

@available(iOS 17.0, *)
struct InsightDetailView: View {
    let insight: DreamSmartInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部
                    HStack {
                        Text(insight.type.icon)
                            .font(.system(size: 40))
                        VStack(alignment: .leading) {
                            Text(insight.title)
                                .font(.title)
                                .fontWeight(.bold)
                            Text(insight.type.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 内容
                    Text(insight.content)
                        .font(.body)
                        .lineSpacing(4)
                    
                    // 行动建议
                    if let suggestion = insight.actionSuggestion {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("行动建议")
                                    .font(.headline)
                            }
                            
                            Text(suggestion)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // 关联梦境
                    if !insight.relatedDreamIds.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("关联梦境")
                                .font(.headline)
                            Text("\(insight.relatedDreamIds.count) 个梦境")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 元数据
                    VStack(alignment: .leading, spacing: 8) {
                        Text("洞察详情")
                            .font(.headline)
                        
                        MetadataRow(label: "创建时间", value: insight.createdAt.formatted())
                        MetadataRow(label: "优先级", value: insight.priority.displayName)
                        MetadataRow(label: "置信度", value: "\(Int(insight.confidence * 100))%")
                        MetadataRow(label: "状态", value: insight.isRead ? "已读" : "未读")
                    }
                }
                .padding()
            }
            .navigationTitle("洞察详情")
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

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 设置视图

@available(iOS 17.0, *)
struct InsightSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var enabled = true
    @State private var minConfidence: Double = 0.6
    @State private var maxDailyInsights = 5
    @State private var notifyOnHighPriority = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基础设置") {
                    Toggle("启用智能洞察", isOn: $enabled)
                    Toggle("高优先级通知", isOn: $notifyOnHighPriority)
                }
                
                Section("质量设置") {
                    VStack(alignment: .leading) {
                        Text("最低置信度：\(Int(minConfidence * 100))%")
                        Slider(value: $minConfidence, in: 0.3...0.9, step: 0.1)
                        Text("低于此值的洞察将不会生成")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("每日最大洞察数：\(maxDailyInsights)", value: $maxDailyInsights, in: 1...10)
                }
                
                Section("说明") {
                    Text("智能洞察会分析你的梦境数据，发现模式、趋势和机会。高优先级的洞察会通过通知提醒你。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("洞察设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        let config = InsightGenerationConfig(
            enabled: enabled,
            minConfidence: minConfidence,
            checkInterval: 3600,
            enabledTypes: DreamInsightType.allTypes.map { $0.nameKey },
            quietHoursStart: 23,
            quietHoursEnd: 8,
            maxDailyInsights: maxDailyInsights,
            notifyOnHighPriority: notifyOnHighPriority
        )
        
        do {
            let service = DreamSmartInsightsService(modelContext: modelContext)
            try service.updateSettings(enabled: enabled, config: config)
        } catch {
            print("Failed to save insight settings: \(error)")
        }
    }
}

// MARK: - ViewModel

@available(iOS 17.0, *)
@MainActor
class InsightsViewModel: ObservableObject {
    @Published var insights: [DreamSmartInsight] = []
    @Published var statistics = InsightStatistics()
    @Published var isLoading = false
    
    private let service: DreamSmartInsightsService
    
    init(modelContext: ModelContext) {
        self.service = DreamSmartInsightsService(modelContext: modelContext)
    }
    
    convenience init() {
        // Create in-memory model context for previews/standalone use
        // In production, prefer the init(modelContext:) initializer
        let container = (try? ModelContainer(for: DreamSmartInsight.self, configurations: [.init(isStoredInMemoryOnly: true)]))
            ?? (try! ModelContainer(for: DreamSmartInsight.self, configurations: [.init(isStoredInMemoryOnly: true)]))
        let modelContext = ModelContext(container)
        self.init(modelContext: modelContext)
    }
    
    func loadInsights(filter: DreamSmartInsightsView.InsightFilter) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            insights = try service.getAllInsights()
            statistics = try service.getStatistics()
        } catch {
            print("Failed to load insights: \(error)")
        }
    }
    
    func refresh() async {
        do {
            _ = try await service.generateInsights()
            await loadInsights(filter: .all)
        } catch {
            print("Failed to refresh: \(error)")
        }
    }
    
    func markAsRead(insightId: UUID) {
        do {
            try service.markAsRead(insightId: insightId)
            if let index = insights.firstIndex(where: { $0.id == insightId }) {
                insights[index].isRead = true
            }
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }
    
    func markAllAsRead() {
        do {
            try service.markAllAsRead()
            for index in insights.indices {
                insights[index].isRead = true
            }
        } catch {
            print("Failed to mark all as read: \(error)")
        }
    }
    
    func toggleSave(insightId: UUID) {
        do {
            try service.toggleSave(insightId: insightId)
            if let index = insights.firstIndex(where: { $0.id == insightId }) {
                insights[index].isSaved.toggle()
            }
        } catch {
            print("Failed to toggle save: \(error)")
        }
    }
    
    func deleteInsight(insightId: UUID) {
        do {
            try service.deleteInsight(insightId: insightId)
            insights.removeAll { $0.id == insightId }
        } catch {
            print("Failed to delete: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    DreamSmartInsightsView()
}
