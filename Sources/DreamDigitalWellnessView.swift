//
//  DreamDigitalWellnessView.swift
//  DreamLog
//
//  数字健康 UI 界面 - 展示屏幕使用与梦境关联分析
//

import SwiftUI
import SwiftData

// MARK: - 主视图

struct DreamDigitalWellnessView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamDigitalWellnessService?
    @State private var stats: DigitalWellnessStats?
    @State private var insights: [DigitalWellnessInsight] = []
    @State private var recommendations: [String] = []
    @State private var isLoading = false
    @State private var selectedPeriod = 7
    @State private var showingConfig = false
    @State private var showingEnableGuide = false
    
    private let periods = [7, 14, 30]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 统计概览
                    if let stats = stats {
                        OverviewCards(stats: stats)
                        
                        // 趋势图表
                        TrendChart(stats: stats)
                        
                        // 问题类别
                        if !stats.topProblematicCategories.isEmpty {
                            ProblematicCategories(categories: stats.topProblematicCategories)
                        }
                    }
                    
                    // 智能洞察
                    if !insights.isEmpty {
                        InsightsSection(insights: insights)
                    }
                    
                    // 个性化建议
                    if !recommendations.isEmpty {
                        RecommendationsSection(recommendations: recommendations)
                    }
                    
                    // 空状态
                    if stats == nil && !isLoading {
                        EmptyStateView()
                    }
                }
                .padding()
            }
            .navigationTitle("数字健康")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingConfig = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("周期", selection: $selectedPeriod) {
                        ForEach(periods, id: \.self) { days in
                            Text("\(days)天").tag(days)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedPeriod) { _, newValue in
                        Task {
                            await loadData(days: newValue)
                        }
                    }
                }
            }
            .task {
                await loadData(days: selectedPeriod)
            }
            .sheet(isPresented: $showingConfig) {
                DigitalWellnessConfigView()
            }
        }
    }
    
    private func loadData(days: Int) async {
        isLoading = true
        
        do {
            service = DreamDigitalWellnessService()
            
            async let statsTask = service!.analyzeScreenTimeImpact(days: days)
            async let insightsTask = service!.generateInsights(days: days)
            async let recommendationsTask = service!.getPersonalizedRecommendations()
            
            stats = try await statsTask
            insights = try await insightsTask
            recommendations = try await recommendationsTask
            
        } catch {
            print("加载数字健康数据失败：\(error)")
        }
        
        isLoading = false
    }
}

// MARK: - 概览卡片

struct OverviewCards: View {
    let stats: DigitalWellnessStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "平均睡前屏幕时间",
                    value: "\(stats.avgScreenTimeBeforeSleep)",
                    unit: "分钟",
                    icon: "📱",
                    color: .orange
                )
                
                StatCard(
                    title: "高使用天数",
                    value: "\(stats.highScreenTimeDays)",
                    unit: "天",
                    icon: "📊",
                    color: .red
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "梦境质量相关",
                    value: String(format: "%.1f", stats.correlationWithDreamQuality * 100),
                    unit: "%",
                    icon: "💤",
                    color: stats.correlationWithDreamQuality < 0 ? .red : .green,
                    isNegative: stats.correlationWithDreamQuality < 0
                )
                
                StatCard(
                    title: "健康评分",
                    value: String(format: "%.0f", stats.weeklyStats.qualityScore),
                    unit: "分",
                    icon: "💚",
                    color: scoreColor(stats.weeklyStats.qualityScore)
                )
            }
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    var isNegative: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isNegative ? .red : color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - 趋势图表

struct TrendChart: View {
    let stats: DigitalWellnessStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用趋势")
                .font(.headline)
            
            HStack(spacing: 8) {
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                
                Text(trendText)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(stats.improvementTrend)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trendColor.opacity(0.1))
                    .foregroundColor(trendColor)
                    .cornerRadius(8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5)
            )
        }
    }
    
    private var trendIcon: String {
        switch stats.improvementTrend {
        case "improving": return "arrow.down.right"
        case "declining": return "arrow.up.right"
        default: return "minus"
        }
    }
    
    private var trendColor: Color {
        switch stats.improvementTrend {
        case "improving": return .green
        case "declining": return .red
        default: return .gray
        }
    }
    
    private var trendText: String {
        switch stats.improvementTrend {
        case "improving": return "数字习惯正在改善"
        case "declining": return "需要注意数字使用习惯"
        default: return "保持稳定"
        }
    }
}

// MARK: - 问题类别

struct ProblematicCategories: View {
    let categories: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("需要注意的应用类别")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(category: category)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

struct CategoryChip: View {
    let category: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(categoryIcon)
            Text(category)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.1))
        .foregroundColor(.red)
        .cornerRadius(8)
    }
    
    private var categoryIcon: String {
        switch category {
        case "社交网络": return "📱"
        case "娱乐": return "🎬"
        case "游戏": return "🎮"
        case "新闻": return "📰"
        default: return "⚠️"
        }
    }
}

// MARK: - 洞察部分

struct InsightsSection: View {
    let insights: [DigitalWellnessInsight]
    @State private var expandedInsight: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智能洞察")
                .font(.headline)
            
            ForEach(insights, id: \.id) { insight in
                InsightCard(
                    insight: insight,
                    isExpanded: expandedInsight == insight.id
                ) {
                    withAnimation {
                        expandedInsight = expandedInsight == insight.id ? nil : insight.id
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

struct InsightCard: View {
    let insight: DigitalWellnessInsight
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insightTypeIcon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                SeverityBadge(severity: insight.severity)
            }
            
            if isExpanded && !insight.recommendations.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("建议：")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(insight.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundColor(.accentColor)
                            Text(rec)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(insightTypeColor.opacity(0.05))
        )
        .onTapGesture(perform: onTap)
    }
    
    private var insightTypeIcon: String {
        WellnessInsightType(rawValue: insight.type)?.icon ?? "💡"
    }
    
    private var insightTypeColor: Color {
        guard let type = WellnessInsightType(rawValue: insight.type) else { return .gray }
        return Color(hex: type.color) ?? .gray
    }
}

struct SeverityBadge: View {
    let severity: String
    
    var body: some View {
        Text(severityText)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severityColor.opacity(0.1))
            .foregroundColor(severityColor)
            .cornerRadius(4)
    }
    
    private var severityText: String {
        switch severity {
        case "high": return "高"
        case "medium": return "中"
        default: return "低"
        }
    }
    
    private var severityColor: Color {
        switch severity {
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
}

// MARK: - 建议部分

struct RecommendationsSection: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("个性化建议")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recommendations, id: \.self) { rec in
                    HStack(alignment: .top, spacing: 8) {
                        Text("✨")
                        Text(rec)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
        )
    }
}

// MARK: - 空状态

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("暂无数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("开始记录屏幕使用数据后，\n您将在这里看到梦境与数字健康的关联分析")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("开始追踪") {
                showingEnableGuide = true
            }
            .buttonStyle(.borderedProminent)
            .alert("启用屏幕时间追踪", isPresented: $showingEnableGuide) {
                Button("打开设置", role: .cancel) {
                    openScreenTimeSettings()
                }
                Button("稍后再说", role: .destructive) {
                }
            } message: {
                Text("要在 DreamLog 中追踪屏幕使用时间，您需要在 iOS 设置中启用屏幕时间 API 访问权限。\n\n1. 打开 iOS 设置\n2. 找到"屏幕使用时间"\n3. 启用"App 限制"和"内容限制"\n4. 返回 DreamLog 开始记录数据")
            }
        }
        .padding(.vertical, 40)
    }
    
    private func openScreenTimeSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 配置视图

struct DigitalWellnessConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("wellness_targetBedtime") private var targetBedtime = "23:00"
    @AppStorage("wellness_screenTimeLimit") private var screenTimeLimit = 30
    @AppStorage("wellness_blueLightReminder") private var blueLightReminder = true
    @AppStorage("wellness_windDownReminder") private var windDownReminder = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("目标设置")) {
                    HStack {
                        Text("目标就寝时间")
                        Spacer()
                        TextField("HH:mm", text: $targetBedtime)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("睡前屏幕时间限制")
                        Spacer()
                        Stepper("\(screenTimeLimit)分钟", value: $screenTimeLimit, in: 15...120, step: 15)
                    }
                }
                
                Section(header: Text("提醒设置")) {
                    Toggle("蓝光过滤提醒", isOn: $blueLightReminder)
                    Toggle("睡前放松提醒", isOn: $windDownReminder)
                }
                
                Section(header: Text("说明")) {
                    Text("数字健康功能会分析您的屏幕使用习惯与梦境质量之间的关联，帮助您建立更健康的数字生活习惯。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("数字健康设置")
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

// MARK: - 辅助组件

struct FlowLayout: Layout {
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
            
            positions.reserveCapacity(subviews.count)
            
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
    DreamDigitalWellnessView()
        .modelContainer(for: [DreamDigitalWellnessInsight.self, ScreenTimeRecord.self, PreSleepScreenTime.self])
}
