//
//  DreamTimelineView.swift
//  DreamLog
//
//  梦境时间轴视图 - 可视化梦境在时间轴上的分布
//  Phase 6 - 个性化体验
//

import SwiftUI

struct DreamTimelineView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @State private var filter = TimelineFilter()
    @State private var showingFilterSheet = false
    @State private var selectedGranularity: TimelineGranularity = .week
    @State private var timelineData: [TimelineDataPoint] = []
    @State private var stats: TimelineStats?
    @State private var selectedDataPoint: TimelineDataPoint?
    @State private var showingDreamsSheet = false
    @State private var dreamsForSelectedPoint: [Dream] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 统计卡片
                        statsSection
                        
                        // 分组选择器
                        granularitySelector
                        
                        // 时间轴可视化
                        timelineSection
                        
                        // 梦境密度热力图
                        densityHeatmapSection
                    }
                    .padding()
                }
            }
            .navigationTitle("📅 梦境时间轴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilterSheet.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(filter.isActive ? .yellow : .white)
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                TimelineFilterSheet(filter: $filter)
            }
            .sheet(isPresented: $showingDreamsSheet) {
                if let point = selectedDataPoint {
                    DreamsForPointSheet(dreams: dreamsForSelectedPoint, dataPoint: point)
                        .environmentObject(dreamStore)
                }
            }
            .task {
                await loadData()
            }
            .onChange(of: selectedGranularity) { _ in
                filter.granularity = selectedGranularity
                Task { await loadData() }
            }
            .onChange(of: filter) { _ in
                Task { await loadData() }
            }
        }
    }
    
    // MARK: - 加载数据
    
    @MainActor
    private func loadData() async {
        let service = DreamTimelineService.shared
        timelineData = service.generateTimelineData(dreams: dreamStore.dreams, filter: filter)
        stats = service.getTimelineStats(dreams: dreamStore.dreams, filter: filter)
    }
    
    // MARK: - 统计卡片
    
    private var statsSection: some View {
        Group {
            if let stats = stats {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        TimelineStatCard(
                            icon: "moon.fill",
                            value: "\(stats.totalDreams)",
                            label: "梦境总数",
                            color: .purple
                        )
                        
                        TimelineStatCard(
                            icon: "star.fill",
                            value: "\(stats.totalLucidDreams)",
                            label: "清醒梦",
                            color: .yellow
                        )
                    }
                    
                    HStack(spacing: 16) {
                        TimelineStatCard(
                            icon: "eye.fill",
                            value: String(format: "%.1f", stats.avgClarity),
                            label: "平均清晰度",
                            color: .blue
                        )
                        
                        TimelineStatCard(
                            icon: "bolt.fill",
                            value: String(format: "%.1f", stats.avgIntensity),
                            label: "平均强度",
                            color: .orange
                        )
                    }
                }
            } else {
                EmptyStateView(
                    icon: "timeline.selection",
                    title: "暂无梦境数据",
                    subtitle: "开始记录梦境后，时间轴将在这里展示"
                )
            }
        }
    }
    
    // MARK: - 分组选择器
    
    private var granularitySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间分组")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimelineGranularity.allCases, id: \.self) { granularity in
                        GranularityButton(
                            granularity: granularity,
                            isSelected: selectedGranularity == granularity
                        ) {
                            selectedGranularity = granularity
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 时间轴部分
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间轴")
                .font(.headline)
                .foregroundColor(.white)
            
            if timelineData.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.exclamationmark",
                    title: "没有符合条件的梦境",
                    subtitle: "尝试调整过滤条件"
                )
            } else {
                // 横向滚动的时间轴
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 40) {
                        ForEach(timelineData) { point in
                            TimelineDataPointView(
                                dataPoint: point,
                                granularity: filter.granularity
                            )
                            .onTapGesture {
                                selectedDataPoint = point
                                dreamsForSelectedPoint = getDreamsForPoint(point)
                                showingDreamsSheet.toggle()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - 密度热力图
    
    private var densityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("梦境密度")
                .font(.headline)
                .foregroundColor(.white)
            
            if timelineData.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.fill",
                    title: "暂无数据",
                    subtitle: "记录更多梦境后查看密度分布"
                )
            } else {
                DreamDensityHeatmap(dataPoints: timelineData)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func getDreamsForPoint(_ point: TimelineDataPoint) -> [Dream] {
        let calendar = Calendar.current
        let range: (start: Date, end: Date)
        
        switch filter.granularity {
        case .day:
            let start = calendar.startOfDay(for: point.date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            range = (start, end)
        case .week:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: point.date)) ?? point.date
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
            range = (start, end)
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: point.date)) ?? point.date
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            range = (start, end)
        case .year:
            let start = calendar.date(from: calendar.dateComponents([.year], from: point.date)) ?? point.date
            let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start
            range = (start, end)
        }
        
        return dreamStore.dreams.filter { dream in
            dream.date >= range.start && dream.date < range.end
        }.sorted { $0.date > $1.date }
    }
}

// MARK: - 统计卡片组件

struct TimelineStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 分组按钮

struct GranularityButton: View {
    let granularity: TimelineGranularity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: granularity.icon)
                    .font(.title3)
                Text(granularity.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.purple : Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - 时间轴数据点视图

struct TimelineDataPointView: View {
    let dataPoint: TimelineDataPoint
    let granularity: TimelineGranularity
    
    var body: some View {
        VStack(spacing: 8) {
            // 梦境数量圆圈
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: dreamCountColor,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: circleSize, height: circleSize)
                
                Text("\(dataPoint.dreamCount)")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // 日期标签
            Text(dateLabel)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
            
            // 清醒梦指示器
            if dataPoint.lucidDreamCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("\(dataPoint.lucidDreamCount)")
                        .font(.caption2)
                }
                .foregroundColor(.yellow)
            }
        }
    }
    
    private var circleSize: CGFloat {
        let base: CGFloat = 50
        let multiplier = min(CGFloat(dataPoint.dreamCount), 5)
        return base + (multiplier * 8)
    }
    
    private var fontSize: CGFloat {
        dataPoint.dreamCount > 99 ? 12 : (dataPoint.dreamCount > 9 ? 16 : 20)
    }
    
    private var dreamCountColor: [Color] {
        switch dataPoint.dreamCount {
        case 0: return [Color.gray, Color.gray]
        case 1..<3: return [Color.blue, Color.purple]
        case 3..<5: return [Color.purple, Color.pink]
        case 5..<10: return [Color.pink, Color.red]
        default: return [Color.red, Color.orange]
        }
    }
    
    private var dateLabel: String {
        let formatter = DateFormatter()
        switch granularity {
        case .day:
            formatter.dateFormat = "MM/dd"
        case .week:
            formatter.dateFormat = "MM/ww"
        case .month:
            formatter.dateFormat = "yyyy/MM"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: dataPoint.date)
    }
}

// MARK: - 梦境密度热力图

struct DreamDensityHeatmap: View {
    let dataPoints: [TimelineDataPoint]
    
    var body: some View {
        VStack(spacing: 4) {
            // 颜色图例
            HStack {
                Text("低")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(heatColor(for: Double(i) / 4.0))
                            .frame(width: 20, height: 8)
                            .cornerRadius(2)
                    }
                }
                
                Text("高")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // 热力条
            HStack(spacing: 2) {
                ForEach(dataPoints) { point in
                    let normalizedDensity = min(Double(point.dreamCount) / 10.0, 1.0)
                    Rectangle()
                        .fill(heatColor(for: normalizedDensity))
                        .frame(height: 30)
                        .cornerRadius(2)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func heatColor(for value: Double) -> Color {
        if value < 0.2 { return Color.blue.opacity(0.6) }
        if value < 0.4 { return Color.purple.opacity(0.7) }
        if value < 0.6 { return Color.pink.opacity(0.8) }
        if value < 0.8 { return Color.red.opacity(0.9) }
        return Color.orange
    }
}

// MARK: - 过滤表

struct TimelineFilterSheet: View {
    @Binding var filter: TimelineFilter
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    
    var allTags: [String] {
        Set(dreamStore.dreams.flatMap { $0.tags }).sorted()
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 日期范围
                Section(header: Text("日期范围")) {
                    DatePicker("开始日期", selection: Binding(
                        get: { filter.startDate ?? Date.distantPast },
                        set: { filter.startDate = $0 == Date.distantPast ? nil : $0 }
                    ), displayedComponents: .date)
                    
                    DatePicker("结束日期", selection: Binding(
                        get: { filter.endDate ?? Date.distantFuture },
                        set: { filter.endDate = $0 == Date.distantFuture ? nil : $0 }
                    ), displayedComponents: .date)
                }
                
                // 标签过滤
                Section(header: Text("标签")) {
                    ForEach(allTags, id: \.self) { tag in
                        Button(action: {
                            if filter.selectedTags.contains(tag) {
                                filter.selectedTags.remove(tag)
                            } else {
                                filter.selectedTags.insert(tag)
                            }
                        }) {
                            HStack {
                                Text(tag)
                                Spacer()
                                if filter.selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                // 情绪过滤
                Section(header: Text("情绪")) {
                    ForEach(Emotion.allCases, id: \.self) { emotion in
                        Button(action: {
                            if filter.selectedEmotions.contains(emotion) {
                                filter.selectedEmotions.remove(emotion)
                            } else {
                                filter.selectedEmotions.insert(emotion)
                            }
                        }) {
                            HStack {
                                Text(emotion.icon + " " + emotion.rawValue)
                                Spacer()
                                if filter.selectedEmotions.contains(emotion) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                // 清醒梦过滤
                Section(header: Text("特殊过滤")) {
                    Toggle("仅显示清醒梦", isOn: $filter.lucidOnly)
                    
                    HStack {
                        Text("最低清晰度")
                        Spacer()
                        Stepper("\(filter.minClarity)", value: $filter.minClarity, in: 1...5)
                    }
                }
                
                // 重置按钮
                Section {
                    Button(action: resetFilter) {
                        Text("重置过滤条件")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("过滤选项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func resetFilter() {
        filter = TimelineFilter()
    }
}

// MARK: - 梦境列表表

struct DreamsForPointSheet: View {
    let dreams: [Dream]
    let dataPoint: TimelineDataPoint
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedDream: Dream?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            List(dreams) { dream in
                Button(action: {
                    selectedDream = dream
                    showingDetail = true
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dream.title)
                            .font(.headline)
                        
                        Text(dream.content.prefix(100))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack {
                            ForEach(dream.emotions.prefix(3), id: \.self) { emotion in
                                Text(emotion.icon)
                            }
                            
                            if dream.isLucid {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
            .navigationTitle("📅 \(dateRangeLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let dream = selectedDream {
                    DreamDetailView(dream: dream)
                        .environmentObject(dreamStore)
                }
            }
        }
    }
    
    private var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: dataPoint.date)
    }
}

// MARK: - 预览

#Preview {
    DreamTimelineView()
        .environmentObject(DreamStore.preview)
}
