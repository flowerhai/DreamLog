//
//  DreamWritingPromptsView.swift
//  DreamLog - Phase 80: Dream Writing Prompts & Creative Exercises
//
//  Created by DreamLog Team on 2026-03-21.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import SwiftData

// MARK: - 主界面

struct DreamWritingPromptsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamWritingPromptsService?
    @State private var prompts: [WritingPrompt] = []
    @State private var stats: WritingStatistics?
    @State private var showingCreateSheet = false
    @State private var selectedPrompt: WritingPrompt?
    @State private var selectedType: WritingPromptType?
    @State private var searchQuery = ""
    @State private var showingStatsSheet = false
    @State private var dailyPrompt: WritingPrompt?
    
    var body: some View {
        NavigationStack {
            Group {
                if let stats = stats {
                    promptsList(stats: stats)
                } else {
                    loadingView
                }
            }
            .navigationTitle("✍️ 写作提示")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingStatsSheet = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !searchQuery.isEmpty {
                        Button("取消") {
                            searchQuery = ""
                        }
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "搜索写作提示...")
            .sheet(isPresented: $showingStatsSheet) {
                WritingStatsView(stats: stats, achievements: getAchievements())
            }
            .sheet(item: $selectedPrompt) { prompt in
                PromptDetailView(prompt: prompt, service: service)
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    // MARK: - Prompts List
    
    @ViewBuilder
    private func promptsList(stats: WritingStats) -> some View {
        if prompts.isEmpty && searchQuery.isEmpty {
            emptyState(stats: stats)
        } else {
            LazyVStack(spacing: 12) {
                // 每日提示
                if searchQuery.isEmpty, let daily = dailyPrompt {
                    DailyPromptCard(prompt: daily, onTap: { selectedPrompt = daily })
                }
                
                // 统计概览
                if searchQuery.isEmpty {
                    statsOverview(stats: stats)
                }
                
                // 类型筛选
                if searchQuery.isEmpty {
                    typeFilter
                }
                
                // 提示列表
                if prompts.isEmpty {
                    noResultsView
                } else {
                    ForEach(prompts, id: \.id) { prompt in
                        PromptCard(
                            prompt: prompt,
                            onTap: { selectedPrompt = prompt }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Stats Overview
    
    private func statsOverview(stats: WritingStatistics) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    value: "\(stats.completedPrompts)",
                    label: "已完成",
                    icon: "checkmark.circle.fill",
                    color: "#34C759"
                )
                
                StatCard(
                    value: "\(stats.streakDays)",
                    label: "连续天数",
                    icon: "flame.fill",
                    color: "#FF9500"
                )
                
                StatCard(
                    value: "\(stats.totalWords)",
                    label: "总字数",
                    icon: "text.alignleft",
                    color: "#007AFF"
                )
            }
            
            // 本周进度
            if stats.weeklyGoal > 0 {
                ProgressCard(
                    title: "本周目标",
                    current: stats.weeklyProgress,
                    total: stats.weeklyGoal,
                    unit: "次"
                )
            }
        }
    }
    
    // MARK: - Type Filter
    
    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "全部",
                    isSelected: selectedType == nil,
                    onTap: { selectedType = nil }
                )
                
                ForEach(WritingPromptType.allCases) { type in
                    FilterChip(
                        title: type.displayName,
                        icon: type.iconName,
                        isSelected: selectedType == type,
                        onTap: { selectedType = type }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Empty State
    
    private func emptyState(stats: WritingStatistics) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("开始你的写作之旅")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("选择一个写作提示，探索梦境的深层含义")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingCreateSheet = true
            } label: {
                Label("创建提示", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载中...")
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundColor(.secondary)
            Text("没有找到匹配的提示")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Data Loading
    
    @MainActor
    private func loadData() async {
        do {
            service = DreamWritingPromptsService(modelContainer: ModelContainer.shared)
            
            // 获取每日提示
            dailyPrompt = try await service?.generateDailyPrompt()
            
            // 获取所有提示
            prompts = try service?.getAllPrompts() ?? []
            
            // 获取统计
            stats = try service?.getStatistics()
            
            // 应用筛选
            if let selectedType = selectedType {
                prompts = prompts.filter { $0.type == selectedType.rawValue }
            }
            
            // 应用搜索
            if !searchQuery.isEmpty {
                prompts = prompts.filter {
                    $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                    $0.content.localizedCaseInsensitiveContains(searchQuery)
                }
            }
        } catch {
            print("加载数据失败：\(error)")
        }
    }
    
    private func getAchievements() -> [WritingAchievement] {
        do {
            return try service?.checkAchievements() ?? []
        } catch {
            return []
        }
    }
}

// MARK: - Daily Prompt Card

struct DailyPromptCard: View {
    let prompt: WritingPrompt
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("每日推荐", systemImage: "star.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text(prompt.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(prompt.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(prompt.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(prompt.difficulty.displayName, systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundColor(colorForDifficulty(prompt.difficulty))
                    
                    Spacer()
                    
                    Label("\(prompt.estimatedMinutes) 分钟", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func colorForDifficulty(_ difficulty: String) -> Color {
        switch difficulty {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .gray
        }
    }
}

// MARK: - Prompt Card

struct PromptCard: View {
    let prompt: WritingPrompt
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: promptTypeIcon(prompt.type))
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prompt.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(prompt.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if prompt.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(prompt.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(prompt.estimatedMinutes) 分钟", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if prompt.wordCount > 0 {
                        Label("\(prompt.wordCount) 字", systemImage: "text.alignleft")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(prompt.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func promptTypeIcon(_ type: String) -> String {
        WritingPromptType(rawValue: type)?.iconName ?? "pencil"
    }
}

// MARK: - Prompt Detail View

struct WritingPromptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let prompt: WritingPrompt
    var service: DreamWritingPromptsService?
    
    @State private var showingEditor = false
    @State private var showingCompleteSheet = false
    @State private var wordCount = 0
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 类型和难度
                    HStack {
                        Label(prompt.type.displayName, systemImage: promptTypeIcon(prompt.type))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        Label(prompt.difficulty.displayName, systemImage: "flag.fill")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(difficultyColor(prompt.difficulty).opacity(0.1))
                            .foregroundColor(difficultyColor(prompt.difficulty))
                            .cornerRadius(8)
                    }
                    
                    // 标题
                    Text(prompt.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // 内容
                    Text(prompt.content)
                        .font(.body)
                        .lineSpacing(4)
                    
                    // 标签
                    if !prompt.tags.isEmpty {
                        WritingPromptsFlowLayout(spacing: 8) {
                            ForEach(prompt.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // 估计时间
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("预计 \(prompt.estimatedMinutes) 分钟")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // 完成状态
                    if prompt.isCompleted {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("已完成", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            if let completedAt = prompt.completedAt {
                                Text("完成时间：\(completedAt, style: .date)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if prompt.wordCount > 0 {
                                Text("字数：\(prompt.wordCount)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let userNotes = prompt.userNotes, !userNotes.isEmpty {
                                Text("笔记：\(userNotes)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(12)
                    } else {
                        Button {
                            showingCompleteSheet = true
                        } label: {
                            Label("标记为完成", systemImage: "checkmark.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("写作提示")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !prompt.isCompleted {
                        Button {
                            showingEditor = true
                        } label: {
                            Image(systemName: "pencil.and.outline")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCompleteSheet) {
                CompletePromptSheet(
                    prompt: prompt,
                    service: service,
                    onComplete: dismiss.callAsFunction
                )
            }
        }
    }
    
    private func promptTypeIcon(_ type: String) -> String {
        WritingPromptType(rawValue: type)?.iconName ?? "pencil"
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .gray
        }
    }
}

// MARK: - Complete Prompt Sheet

struct CompletePromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    let prompt: WritingPrompt
    var service: DreamWritingPromptsService?
    let onComplete: () -> Void
    
    @State private var wordCount = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("写作统计")) {
                    HStack {
                        Text("字数")
                        Spacer()
                        TextField("输入字数", text: $wordCount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("笔记")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("完成提示")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        completePrompt()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func completePrompt() {
        do {
            let count = Int(wordCount) ?? 0
            try service?.completePrompt(prompt, wordCount: count, notes: notes.isEmpty ? nil : notes)
            onComplete()
            dismiss()
        } catch {
            print("完成提示失败：\(error)")
        }
    }
}

// MARK: - Writing Stats View

struct WritingStatsView: View {
    @Environment(\.dismiss) private var dismiss
    let stats: WritingStatistics?
    let achievements: [WritingAchievement]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let stats = stats {
                        // 总体统计
                        statsSection(stats: stats)
                        
                        // 类型分布
                        typeDistribution(stats: stats)
                        
                        // 成就
                        if !achievements.isEmpty {
                            achievementsSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("写作统计")
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
    
    private func statsSection(stats: WritingStatistics) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    value: "\(stats.totalPrompts)",
                    label: "总提示",
                    icon: "list.bullet.rectangle",
                    color: "#007AFF"
                )
                
                StatCard(
                    value: "\(stats.completedPrompts)",
                    label: "已完成",
                    icon: "checkmark.circle.fill",
                    color: "#34C759"
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    value: "\(stats.streakDays)",
                    label: "连续天数",
                    icon: "flame.fill",
                    color: "#FF9500"
                )
                
                StatCard(
                    value: "\(stats.totalWords)",
                    label: "总字数",
                    icon: "text.alignleft",
                    color: "#BF5AF2"
                )
            }
            
            if stats.averageWordsPerSession > 0 {
                StatCard(
                    value: "\(stats.averageWordsPerSession)",
                    label: "平均字数",
                    icon: "chart.bar.fill",
                    color: "#5AC8FA"
                )
            }
        }
    }
    
    private func typeDistribution(stats: WritingStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("类型分布")
                .font(.headline)
            
            ForEach(stats.promptsByType.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                HStack {
                    Text(WritingPromptType(rawValue: type)?.displayName ?? type)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(count) 次")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就")
                .font(.headline)
            
            ForEach(achievements) { achievement in
                AchievementRow(achievement: achievement)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Achievement Row

struct AchievementRow: View {
    let achievement: WritingAchievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked {
                    ProgressView(value: Double(achievement.progress), total: Double(achievement.requirement))
                        .progressViewStyle(.linear)
                }
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Text("\(achievement.progress)/\(achievement.requirement)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color) ?? .blue)
            
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

// MARK: - Progress Card

struct ProgressCard: View {
    let title: String
    let current: Int
    let total: Int
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(current)/\(total) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(current), total: Double(total))
                .progressViewStyle(.linear)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct WritingPromptsFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            let origin = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: origin, proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
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
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    DreamWritingPromptsView()
        .modelContainer(for: [WritingPrompt.self, WritingSession.self, WritingPreferences.self], inMemory: true)
}
