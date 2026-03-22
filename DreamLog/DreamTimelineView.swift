//
//  DreamTimelineView.swift
//  DreamLog
//
//  Phase 86: Dream Timeline & Life Events UI
//  Visual timeline interface
//

import SwiftUI
import SwiftData
import Charts

struct DreamTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var timelineEntries: [TimelineEntry] = []
    @State private var statistics: TimelineStatistics?
    @State private var correlations: [DreamLifeCorrelation] = []
    @State private var isLoading = false
    @State private var config = TimelineConfig.default
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingCreateEvent = false
    @State private var selectedEntry: TimelineEntry?
    
    private var service: DreamTimelineService {
        DreamTimelineService(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if timelineEntries.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("梦境时间线")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("配置") {
                        showingConfig = true
                    }
                    .sheet(isPresented: $showingConfig) {
                        configSheet
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                refresh()
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateLifeEventView {
                    refresh()
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("生成时间线中...")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "timeline.selection")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无时间线数据")
                .font(.title2)
                .fontWeight(.semibold)
            Text("记录梦境或标记生活事件，构建您的梦境时间线")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Button("记录梦境") {
                    // Navigate to record
                }
                .buttonStyle(.borderedProminent)
                
                Button("标记事件") {
                    showingCreateEvent = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Statistics Overview
                if let stats = statistics {
                    statisticsOverview(stats)
                }
                
                // Timeline
                timelineView
                
                // Correlations
                if !correlations.isEmpty {
                    correlationsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    private func statisticsOverview(_ stats: TimelineStatistics) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                TimelineStatCard(
                    title: "梦境",
                    value: "\(stats.totalDreams)",
                    icon: "moon",
                    color: .purple
                )
                
                TimelineStatCard(
                    title: "生活事件",
                    value: "\(stats.totalLifeEvents)",
                    icon: "star",
                    color: .orange
                )
                
                TimelineStatCard(
                    title: "关联发现",
                    value: "\(stats.topCorrelations.count)",
                    icon: "link",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
                TimelineStatCard(
                    title: "每月梦境",
                    value: String(format: "%.1f", stats.dreamsPerMonth),
                    icon: "chart.bar",
                    color: .green
                )
                
                TimelineStatCard(
                    title: "趋势",
                    value: stats.dreamFrequencyTrend.displayName,
                    icon: stats.dreamFrequencyTrend.icon,
                    color: .pink
                )
                
                TimelineStatCard(
                    title: "平均关联",
                    value: String(format: "%.0f%%", stats.averageCorrelationScore * 100),
                    icon: "sparkles",
                    color: .indigo
                )
            }
        }
    }
    
    private var timelineView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("时间线")
                .font(.headline)
                .padding(.bottom, 12)
            
            VStack(alignment: .center, spacing: 0) {
                // Timeline line
                Rectangle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 2)
                
                ForEach(Array(timelineEntries.enumerated()), id: \.element.id) { index, entry in
                    TimelineEntryRow(entry: entry, isSelected: selectedEntry == entry)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                    
                    if index < timelineEntries.count - 1 {
                        Rectangle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 2, height: 40)
                    }
                }
                
                Rectangle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 2)
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var correlationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("发现的关联")
                .font(.headline)
            
            ForEach(Array(correlations.prefix(5).enumerated()), id: \.element.lifeEvent.id) { index, correlation in
                CorrelationCard(correlation: correlation)
            }
        }
    }
    
    private var configSheet: some View {
        NavigationStack {
            Form {
                Section("显示选项") {
                    Toggle("显示梦境", isOn: $config.showDreams)
                    Toggle("显示生活事件", isOn: $config.showLifeEvents)
                }
                
                Section("时间范围") {
                    Picker("范围", selection: $config.dateRange) {
                        ForEach(TimelineConfig.DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }
                
                Section("分组方式") {
                    Picker("分组", selection: $config.groupByTime) {
                        ForEach(TimelineConfig.TimeGrouping.allCases, id: \.self) { grouping in
                            Text(grouping.rawValue).tag(grouping)
                        }
                    }
                }
                
                Section("事件类别") {
                    ForEach(LifeEventCategory.allCases, id: \.self) { category in
                        HStack {
                            Text("\(category.icon) \(category.displayName)")
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { config.selectedCategories.contains(category) },
                                set: { isSelected in
                                    if isSelected {
                                        config.selectedCategories.insert(category)
                                    } else {
                                        config.selectedCategories.remove(category)
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section("最低影响等级") {
                    Picker("等级", selection: $config.minImpactLevel) {
                        ForEach(ImpactLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
            }
            .navigationTitle("时间线配置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showingConfig = false
                        refresh()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func refresh() {
        isLoading = true
        
        Task {
            do {
                guard let dateRange = config.dateRange.dateRange else {
                    throw TimelineError.invalidDateRange
                }
                
                async let entries = service.generateTimeline(config: config)
                async let stats = service.getStatistics(dateRange: dateRange)
                async let corrs = service.analyzeCorrelations(dateRange: dateRange)
                
                self.timelineEntries = try await entries
                self.statistics = try await stats
                self.correlations = try await corrs
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
            isLoading = false
        }
    }
    
    @State private var showingConfig = false
}

// MARK: - Subviews

struct TimelineStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TimelineEntryRow: View {
    let entry: TimelineEntry
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Date
            VStack(spacing: 4) {
                Text(formatDate(entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatTime(entry.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            // Timeline point
            ZStack {
                Circle()
                    .fill(entry.type == .dream ? Color.purple : Color.orange)
                    .frame(width: 16, height: 16)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.type.icon)
                    Text(entry.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let impactLevel = entry.impactLevel {
                        Circle()
                            .fill(Color(hex: impactLevel.color))
                            .frame(width: 8, height: 8)
                    }
                }
                
                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !entry.emotions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.emotions.prefix(3), id: \.self) { emotion in
                            Text(emotion.icon)
                                .font(.caption)
                        }
                    }
                }
                
                if let description = entry.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(isSelected ? Color.purple.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: isSelected ? Color.purple.opacity(0.3) : Color.clear, radius: 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct CorrelationCard: View {
    let correlation: DreamLifeCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(correlation.lifeEvent.category.icon)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(correlation.lifeEvent.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(correlation.patternType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(String(format: "%.0f%%", correlation.correlationScore * 100))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("关联度")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if !correlation.insights.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(correlation.insights, id: \.self) { insight in
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(insight)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

// MARK: - Create Life Event View

struct CreateLifeEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var category: LifeEventCategory = .personal
    @State private var impactLevel: ImpactLevel = .medium
    @State private var selectedEmotions: Set<Emotion> = []
    @State private var tagsText = ""
    
    let onSuccess: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("事件标题", text: $title)
                    TextField("描述（可选）", text: $description, axis: .vertical)
                }
                
                Section("时间与类别") {
                    DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                    
                    Picker("类别", selection: $category) {
                        ForEach(LifeEventCategory.allCases, id: \.self) { cat in
                            Text("\(cat.icon) \(cat.displayName)").tag(cat)
                        }
                    }
                    
                    Picker("影响程度", selection: $impactLevel) {
                        ForEach(ImpactLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
                
                Section("情绪标签") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 8) {
                        ForEach(Emotion.allCases, id: \.self) { emotion in
                            Button(action: {
                                if selectedEmotions.contains(emotion) {
                                    selectedEmotions.remove(emotion)
                                } else {
                                    selectedEmotions.insert(emotion)
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text(emotion.icon)
                                        .font(.title2)
                                    Text(emotion.displayName)
                                        .font(.caption)
                                }
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(selectedEmotions.contains(emotion) ? Color.purple.opacity(0.2) : Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Section("标签") {
                    TextField("标签（用逗号分隔）", text: $tagsText)
                }
            }
            .navigationTitle("标记生活事件")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveEvent() {
        let tags = tagsText.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        let event = LifeEvent(
            title: title,
            description: description.isEmpty ? nil : description,
            date: selectedDate,
            category: category,
            impactLevel: impactLevel,
            emotions: Array(selectedEmotions),
            tags: tags
        )
        
        modelContext.insert(event)
        
        try? modelContext.save()
        onSuccess()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    DreamTimelineView()
        .modelContainer(for: [Dream.self, LifeEvent.self])
}
