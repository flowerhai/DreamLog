//
//  DreamCalendarIntegrationView.swift
//  DreamLog
//
//  Phase 77: Dream Calendar Integration - Main View
//  梦境与日历事件关联分析界面
//

import SwiftUI
import SwiftData

// MARK: - 主视图

struct DreamCalendarIntegrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startDate) private var calendarEvents: [CalendarEvent]
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    
    @StateObject private var service: DreamCalendarIntegrationService
    @State private var showingSettings = false
    @State private var selectedTab = CalendarTab.timeline
    @State private var selectedDate = Date()
    @State private var isSyncing = false
    @State private var syncError: String?
    
    init() {
        // Initialize service with a model context
        // In production, the view should receive modelContext from environment
        do {
            let container = try ModelContainer(for: Dream.self)
            _service = StateObject(wrappedValue: DreamCalendarIntegrationService(modelContext: ModelContext(container)))
        } catch {
            // Fallback for previews with in-memory storage
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: Dream.self, configurations: [config])
            _service = StateObject(wrappedValue: DreamCalendarIntegrationService(modelContext: ModelContext(container)))
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                switch selectedTab {
                case .timeline:
                    TimelineView(service: service, selectedDate: $selectedDate)
                case .correlations:
                    CorrelationsView(service: service)
                case .suggestions:
                    SuggestionsView(service: service)
                case .stats:
                    StatsView(service: service)
                }
            }
            .navigationTitle("梦境日历 📅")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: syncEvents) {
                        Image(systemName: isSyncing ? "arrow.clockwise" : "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(isSyncing ? 360 : 0))
                            .animation(isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSyncing)
                    }
                    .disabled(isSyncing)
                }
            }
            .sheet(isPresented: $showingSettings) {
                CalendarSettingsView(service: service)
            }
            .alert("同步错误", isPresented: .constant(syncError != nil)) {
                Button("确定") { syncError = nil }
            } message: {
                Text(syncError ?? "")
            }
        }
        .onAppear {
            checkPermission()
        }
    }
    
    private func syncEvents() {
        Task {
            isSyncing = true
            defer { isSyncing = false }
            
            do {
                let dateRange = DateRange(
                    start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                    end: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                )
                let count = try await service.syncEvents(dateRange: dateRange)
                print("同步完成：\(count) 个事件")
            } catch {
                syncError = error.localizedDescription
            }
        }
    }
    
    private func checkPermission() {
        Task {
            let status = service.checkPermissionStatus()
            if !status.canAccess {
                // 显示权限请求提示
            }
        }
    }
}

// MARK: - 标签枚举

enum CalendarTab: String, CaseIterable {
    case timeline = "时间线"
    case correlations = "关联分析"
    case suggestions = "智能建议"
    case stats = "统计数据"
    
    var icon: String {
        switch self {
        case .timeline: return "clock"
        case .correlations: return "link"
        case .suggestions: return "lightbulb"
        case .stats: return "chart.bar"
        }
    }
}

// MARK: - 时间线视图

struct TimelineView: View {
    @ObservedObject var service: DreamCalendarIntegrationService
    @Binding var selectedDate: Date
    @State private var timelineItems: [TimelineItem] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载时间线...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if timelineItems.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "暂无时间线数据",
                    subtitle: "同步日历事件后查看梦境与事件的关联时间线"
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 日期选择器
                        DatePicker(
                            "选择日期",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        
                        // 时间线索引
                        ForEach(groupItemsByDate(items: timelineItems)) { dateGroup in
                            DateGroupSection(
                                date: dateGroup.date,
                                items: dateGroup.items
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadTimeline()
        }
    }
    
    private func groupItemsByDate(items: [TimelineItem]) -> [(date: Date, items: [TimelineItem])] {
        let grouped = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.date)
        }
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, items: $0.value) }
    }
    
    private func loadTimeline() {
        Task {
            isLoading = true
            timelineItems = await service.generateTimeline(dateRange: DateRange(
                start: Calendar.current.date(byAdding: .week, value: -1, to: Date()) ?? Date(),
                end: Calendar.current.date(byAdding: .week, value: 1, to: Date()) ?? Date()
            ))
            isLoading = false
        }
    }
}

// MARK: - 日期分组视图

struct DateGroupSection: View {
    let date: Date
    let items: [TimelineItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date, style: .date)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(items) { item in
                    TimelineItemRow(item: item)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 时间线索引项行

struct TimelineItemRow: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Text(item.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(hex: item.color).opacity(0.2))
                .cornerRadius(10)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 关联指示器
            if item.isLinked {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 关联分析视图

struct CorrelationsView: View {
    @ObservedObject var service: DreamCalendarIntegrationService
    @State private var correlations: [DreamEventCorrelation] = []
    @State private var isLoading = true
    @State private var selectedFilter: TimeRelation? = nil
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载关联分析...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if correlations.isEmpty {
                EmptyStateView(
                    icon: "link",
                    title: "暂无关联数据",
                    subtitle: "同步日历事件并记录梦境后自动分析关联"
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 过滤器
                        FilterChipRow(
                            items: TimeRelation.allCases.map { $0.description },
                            selectedItem: selectedFilter?.description,
                            onSelect: { desc in
                                selectedFilter = TimeRelation.allCases.first { $0.description == desc }
                            }
                        )
                        .padding(.horizontal)
                        
                        // 关联列表
                        ForEach(filterCorrelations(), id: \.id) { correlation in
                            CorrelationCard(correlation: correlation)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadCorrelations()
        }
    }
    
    private func filterCorrelations() -> [DreamEventCorrelation] {
        guard let filter = selectedFilter else { return correlations }
        return correlations.filter { $0.timeRelation == filter }
    }
    
    private func loadCorrelations() {
        Task {
            isLoading = true
            correlations = await service.getCorrelations(limit: 50)
            isLoading = false
        }
    }
}

// MARK: - 关联卡片

struct CorrelationCard: View {
    let correlation: DreamEventCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Text(correlation.timeRelation.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                
                Text("关联强度：\(Int(correlation.correlationStrength * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 梦境信息
            DreamSummaryCard(dreamId: correlation.dreamId)
            
            // 事件信息
            EventSummaryCard(eventId: correlation.eventId)
            
            // 分析备注
            if let notes = correlation.analysisNotes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 梦境摘要卡片

struct DreamSummaryCard: View {
    let dreamId: UUID
    @Query(filter: #Predicate<Dream> { $0.id == UUID() }) var dreams: [Dream]
    
    var dream: Dream? {
        dreams.first { $0.id == dreamId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars")
                    .foregroundColor(.purple)
                Text("梦境")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(dream?.title ?? "未知梦境")
                .font(.headline)
            
            Text(dream?.content.prefix(100) ?? "" + "...")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 事件摘要卡片

struct EventSummaryCard: View {
    let eventId: String
    @Query(filter: #Predicate<CalendarEvent> { $0.eventId == "" }) var events: [CalendarEvent]
    
    var event: CalendarEvent? {
        events.first { $0.eventId == eventId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event?.eventType.icon ?? "📌")
                    .font(.title2)
                Text("日历事件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(event?.title ?? "未知事件")
                .font(.headline)
            
            if let location = event?.location {
                HStack {
                    Image(systemName: "mappin")
                        .font(.caption)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 智能建议视图

struct SuggestionsView: View {
    @ObservedObject var service: DreamCalendarIntegrationService
    @State private var suggestions: [CalendarBasedSuggestion] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("生成智能建议...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if suggestions.isEmpty {
                EmptyStateView(
                    icon: "lightbulb",
                    title: "暂无智能建议",
                    subtitle: "基于您的日历和梦境模式生成个性化建议"
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(suggestions) { suggestion in
                            SuggestionCard(suggestion: suggestion)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadSuggestions()
        }
    }
    
    private func loadSuggestions() {
        Task {
            isLoading = true
            suggestions = await service.generateSuggestions()
            isLoading = false
        }
    }
}

// MARK: - 建议卡片

struct SuggestionCard: View {
    let suggestion: CalendarBasedSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Text(suggestion.suggestionType.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.headline)
                    
                    Text(suggestion.suggestionType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 优先级标识
                Image(systemName: "flag.fill")
                    .foregroundColor(Color(hex: suggestion.priority.color))
            }
            
            // 描述
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            // 行动项
            if !suggestion.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("行动建议:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(suggestion.actionItems, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.accentColor)
                            Text(item)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 统计数据视图

struct StatsView: View {
    @ObservedObject var service: DreamCalendarIntegrationService
    @State private var stats: CalendarCorrelationStats?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载统计数据...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let stats = stats {
                ScrollView {
                    VStack(spacing: 20) {
                        // 概览统计
                        OverviewStatsRow(stats: stats)
                        
                        // 事件类型分布
                        EventTypeDistribution(stats: stats)
                        
                        // 时间关系分布
                        TimeRelationDistribution(stats: stats)
                        
                        // 每周模式
                        WeeklyPatternChart(stats: stats)
                        
                        // 最近关联
                        RecentCorrelationsList(stats: stats)
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "暂无统计数据",
                    subtitle: "同步更多数据后查看统计分析"
                )
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        Task {
            isLoading = true
            stats = await service.getCorrelationStats()
            isLoading = false
        }
    }
}

// MARK: - 概览统计行

struct OverviewStatsRow: View {
    let stats: CalendarCorrelationStats
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "关联梦境",
                value: "\(stats.totalLinkedDreams)",
                icon: "moon.stars",
                color: "purple"
            )
            
            StatCard(
                title: "日历事件",
                value: "\(stats.totalEvents)",
                icon: "calendar",
                color: "blue"
            )
            
            StatCard(
                title: "平均强度",
                value: "\(Int(stats.averageCorrelationStrength * 100))%",
                icon: "chart.line",
                color: "green"
            )
        }
    }
}

// MARK: - 事件类型分布

struct EventTypeDistribution: View {
    let stats: CalendarCorrelationStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("事件类型分布")
                .font(.headline)
            
            ForEach(stats.topEventTypes.prefix(5), id: \.type.rawValue) { item in
                HStack {
                    Text(item.type.icon)
                        .font(.title3)
                    Text(item.type.rawValue)
                        .font(.subheadline)
                    Spacer()
                    Text("\(item.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 时间关系分布

struct TimeRelationDistribution: View {
    let stats: CalendarCorrelationStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间关系分布")
                .font(.headline)
            
            ForEach(stats.topTimeRelations.prefix(5), id: \.relation.rawValue) { item in
                HStack {
                    Text(item.relation.rawValue)
                        .font(.subheadline)
                    Spacer()
                    Text("\(item.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 每周模式图表

struct WeeklyPatternChart: View {
    let stats: CalendarCorrelationStats
    let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每周模式")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(Array(stats.weeklyPattern.enumerated()), id: \.offset) { index, count in
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.6))
                            .frame(width: 30, height: max(40, CGFloat(count) * 10))
                            .cornerRadius(4)
                        
                        Text(weekDays[min(index, weekDays.count - 1)])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 最近关联列表

struct RecentCorrelationsList: View {
    let stats: CalendarCorrelationStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近关联")
                .font(.headline)
            
            ForEach(stats.recentCorrelations.prefix(5), id: \.dreamTitle) { info in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.dreamTitle)
                            .font(.subheadline)
                        Text(info.eventTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(info.timeRelation)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 设置视图

struct CalendarSettingsView: View {
    @ObservedObject var service: DreamCalendarIntegrationService
    @Environment(\.dismiss) var dismiss
    @State private var config: CalendarIntegrationConfig
    
    init(service: DreamCalendarIntegrationService) {
        self.service = service
        _config = State(initialValue: CalendarIntegrationConfig.default)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本设置")) {
                    Toggle("启用日历集成", isOn: $config.enabled)
                    Toggle("自动同步", isOn: $config.autoSync)
                    
                    Picker("同步频率", selection: $config.syncFrequency) {
                        ForEach(SyncFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }
                
                Section(header: Text("隐私设置")) {
                    Toggle("隐私模式", isOn: $config.privacyMode)
                    Text("隐私模式下不存储事件详情，仅保留统计信息")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("关联通知", isOn: $config.notifyOnCorrelation)
                }
                
                Section(header: Text("关联设置")) {
                    Stepper("关联时间窗口：\(config.defaultLinkWindow) 小时", value: $config.defaultLinkWindow, in: 1...72, step: 1)
                }
                
                Section {
                    Button("保存设置") {
                        service.updateConfig(config)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("日历设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 辅助视图

struct FilterChipRow: View {
    let items: [String]
    let selectedItem: String?
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 全部选项
                FilterChip(
                    title: "全部",
                    isSelected: selectedItem == nil
                ) {
                    onSelect("")
                }
                
                ForEach(items, id: \.self) { item in
                    FilterChip(
                        title: item,
                        isSelected: selectedItem == item
                    ) {
                        onSelect(item)
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.white.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 预览

#Preview {
    DreamCalendarIntegrationView()
}
