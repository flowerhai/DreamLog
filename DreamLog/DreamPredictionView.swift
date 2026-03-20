//
//  DreamPredictionView.swift
//  DreamLog
//
//  梦境预测界面
//  展示 AI 生成的梦境预测和洞察
//

import SwiftUI
import SwiftData

// MARK: - 梦境预测主界面

struct DreamPredictionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service = DreamPredictionServiceWrapper()
    @State private var predictions: [DreamPrediction] = []
    @State private var stats: PredictionStats = .empty
    @State private var isRefreshing = false
    @State private var selectedType: DreamPredictionType?
    @State private var showConfigSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if predictions.isEmpty && !isRefreshing {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("梦境预测 🔮")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showConfigSheet = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: refreshPredictions) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                    .disabled(isRefreshing)
                }
            }
            .sheet(isPresented: $showConfigSheet) {
                PredictionConfigView()
            }
            .onAppear {
                loadPredictions()
            }
            .refreshable {
                await refreshPredictions()
            }
        }
    }
    
    // MARK: - 内容视图
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 统计卡片
                statsCard
                
                // 预测类型筛选
                typeFilter
                
                // 预测列表
                predictionsList
                
                // 生成新预测按钮
                generateButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("预测统计")
                        .font(.headline)
                    Text("基于过去 30 天的梦境数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(stats.totalPredictions)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    Text("总预测数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                StatItemView(
                    title: "平均置信度",
                    value: String(format: "%.0f%%", stats.averageConfidence * 100),
                    icon: "📊"
                )
                
                StatItemView(
                    title: "预测类型",
                    value: "\(stats.predictionsByType.count)",
                    icon: "🔮"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChipView(
                    title: "全部",
                    icon: "🔮",
                    isSelected: selectedType == nil
                ) {
                    selectedType = nil
                }
                
                ForEach(DreamPredictionType.allCases, id: \.self) { type in
                    FilterChipView(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
        }
    }
    
    private var predictionsList: some View {
        VStack(spacing: 12) {
            let filteredPredictions = selectedType == nil
                ? predictions
                : predictions.filter { $0.type == selectedType }
            
            ForEach(filteredPredictions.sorted { $0.confidence > $1.confidence }, id: \.id) { prediction in
                PredictionCardView(
                    prediction: prediction,
                    onDelete: {
                        service.deletePrediction(prediction)
                        loadPredictions()
                    }
                )
            }
        }
    }
    
    private var generateButton: some View {
        Button(action: generateNewPredictions) {
            HStack {
                Image(systemName: "sparkles")
                Text("生成新预测")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isRefreshing)
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "crystal.ball")
                .font(.system(size: 80))
                .foregroundColor(.accentColor.opacity(0.5))
            
            Text("暂无预测")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("需要至少 5 条梦境记录才能生成预测")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: generateNewPredictions) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("立即生成预测")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 操作
    
    private func loadPredictions() {
        Task {
            predictions = await service.getPredictions()
            stats = await service.getStats()
        }
    }
    
    private func refreshPredictions() async {
        withAnimation {
            isRefreshing = true
        }
        
        await service.generatePredictions()
        await loadPredictions()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                isRefreshing = false
            }
        }
    }
    
    private func generateNewPredictions() {
        Task {
            await refreshPredictions()
        }
    }
}

// MARK: - 预测卡片视图

struct PredictionCardView: View {
    let prediction: DreamPrediction
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Text(prediction.type.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(prediction.title)
                        .font(.headline)
                    Text(formatDate(prediction.predictionDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 置信度徽章
                ConfidenceBadge(confidence: prediction.confidence)
                
                // 删除按钮
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // 描述
            Text(prediction.description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            // 置信度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("置信度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", prediction.confidence * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(confidenceColor(prediction.confidence))
                            .frame(width: geometry.size.width * prediction.confidence, height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            // 展开详情
            if isExpanded {
                PredictionDetailView(prediction: prediction)
                    .transition(.expand)
            }
            
            // 展开/收起按钮
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Spacer()
                    Text(isExpanded ? "收起" : "查看详情")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .alert("删除预测", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除这条预测吗？")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - 预测详情视图

struct PredictionDetailView: View {
    let prediction: DreamPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            // 标签
            if !prediction.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(prediction.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                    }
                }
            }
            
            // 根据类型显示不同详情
            switch prediction.type {
            case .content:
                ContentPredictionDetailView(data: prediction.details)
            case .emotion:
                EmotionPredictionDetailView(data: prediction.details)
            case .lucidProbability:
                LucidPredictionDetailView(data: prediction.details)
            case .bestTime:
                BestTimePredictionDetailView(data: prediction.details)
            case .pattern:
                PatternPredictionDetailView(data: prediction.details)
            case .warning:
                WarningPredictionDetailView(data: prediction.details)
            }
        }
    }
}

// MARK: - 各类预测详情视图

struct ContentPredictionDetailView: View {
    let data: String
    
    var predictionData: ContentPredictionData {
        (try? JSONDecoder().decode(ContentPredictionData.self, from: Data(data.utf8))) ?? .empty()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !predictionData.likelyThemes.isEmpty {
                DetailSection(title: "可能主题", items: predictionData.likelyThemes)
            }
            
            if !predictionData.likelySymbols.isEmpty {
                DetailSection(title: "可能符号", items: predictionData.likelySymbols)
            }
            
            if !predictionData.likelyScenarios.isEmpty {
                DetailSection(title: "可能场景", items: predictionData.likelyScenarios)
            }
            
            if !predictionData.inspirationSources.isEmpty {
                DetailSection(title: "灵感来源", items: predictionData.inspirationSources)
            }
        }
    }
}

struct EmotionPredictionDetailView: View {
    let data: String
    
    var predictionData: EmotionPredictionData {
        (try? JSONDecoder().decode(EmotionPredictionData.self, from: Data(data.utf8))) ?? .empty()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 趋势方向
            HStack {
                Text("情绪趋势:")
                    .font(.subheadline)
                Text(predictionData.trendDirection.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(trendColor(predictionData.trendDirection))
            }
            
            // 稳定性评分
            HStack {
                Text("稳定性:")
                    .font(.subheadline)
                ProgressView(value: predictionData.stabilityScore)
                    .frame(width: 100)
                Text(String(format: "%.0f%%", predictionData.stabilityScore * 100))
                    .font(.caption)
            }
            
            // 建议
            if !predictionData.recommendations.isEmpty {
                DetailSection(title: "建议", items: predictionData.recommendations)
            }
        }
    }
    
    private func trendColor(_ direction: EmotionPredictionData.TrendDirection) -> Color {
        switch direction {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        case .volatile: return .red
        }
    }
}

struct LucidPredictionDetailView: View {
    let data: String
    
    var predictionData: LucidPredictionData {
        (try? JSONDecoder().decode(LucidPredictionData.self, from: Data(data.utf8))) ?? .empty()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 概率显示
            HStack {
                Text("清醒梦概率:")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.0f%%", predictionData.probability * 100))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(probabilityColor(predictionData.probability))
            }
            
            // 最佳时机
            HStack {
                Image(systemName: "clock")
                Text("最佳时机: \(predictionData.optimalTiming)")
                    .font(.subheadline)
            }
            
            // 推荐技巧
            if !predictionData.recommendedTechniques.isEmpty {
                DetailSection(title: "推荐技巧", items: predictionData.recommendedTechniques)
            }
            
            // 准备建议
            if !predictionData.preparationTips.isEmpty {
                DetailSection(title: "准备建议", items: predictionData.preparationTips)
            }
        }
    }
    
    private func probabilityColor(_ probability: Double) -> Color {
        if probability >= 0.7 {
            return .green
        } else if probability >= 0.4 {
            return .yellow
        } else {
            return .orange
        }
    }
}

struct BestTimePredictionDetailView: View {
    let data: String
    
    var predictionData: BestTimePredictionData {
        (try? JSONDecoder().decode(BestTimePredictionData.self, from: Data(data.utf8))) ?? .empty()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 最佳时间
            if !predictionData.optimalHours.isEmpty {
                HStack {
                    Text("最佳记录时间:")
                        .font(.subheadline)
                    Spacer()
                    Text(formatHours(predictionData.optimalHours))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
            }
            
            // 历史模式
            if !predictionData.historicalPatterns.isEmpty {
                DetailSection(title: "历史模式", items: predictionData.historicalPatterns)
            }
        }
    }
    
    private func formatHours(_ hours: [Int]) -> String {
        hours.map { hour in
            String(format: "%02d:00", hour)
        }.joined(separator: ", ")
    }
}

struct PatternPredictionDetailView: View {
    let data: String
    
    var predictionData: PatternPredictionData {
        (try? JSONDecoder().decode(PatternPredictionData.self, from: Data(data.utf8))) ?? .empty()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 周期长度
            HStack {
                Text("梦境周期:")
                    .font(.subheadline)
                Text("\(predictionData.cycleLength) 天")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // 重复主题
            if !predictionData.recurringThemes.isEmpty {
                DetailSection(title: "重复主题", items: predictionData.recurringThemes)
            }
            
            // 触发因素
            if !predictionData.triggerFactors.isEmpty {
                DetailSection(title: "触发因素", items: predictionData.triggerFactors)
            }
        }
    }
}

struct WarningPredictionDetailView: View {
    let data: String
    
    var predictionData: WarningPredictionData {
        (try? JSONDecoder().decode(WarningPredictionData.self, from: Data(data.utf8))) ?? .empty()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 预警级别
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(warningColor(predictionData.warningLevel))
                Text("预警级别: \(predictionData.warningLevel.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(warningColor(predictionData.warningLevel))
            }
            .padding()
            .background(warningColor(predictionData.warningLevel).opacity(0.1))
            .cornerRadius(8)
            
            // 指标
            if !predictionData.indicators.isEmpty {
                DetailSection(title: "检测指标", items: predictionData.indicators)
            }
            
            // 建议
            if !predictionData.suggestions.isEmpty {
                DetailSection(title: "建议", items: predictionData.suggestions)
            }
            
            // 咨询提示
            if predictionData.shouldConsult {
                HStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                    Text("建议咨询专业人士获取更详细的指导")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
        }
    }
    
    private func warningColor(_ level: WarningPredictionData.WarningLevel) -> Color {
        switch level {
        case .normal: return .green
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - 辅助视图

struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct FilterChipView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct ConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        Text(String(format: "%.0f%%", confidence * 100))
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor(confidence).opacity(0.1))
            .foregroundColor(confidenceColor(confidence))
            .cornerRadius(8)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .yellow
        } else {
            return .orange
        }
    }
}

struct DetailSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ForEach(items, id: \.self) { item in
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .foregroundColor(.accentColor)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
    }
}

// MARK: - 配置视图

struct PredictionConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = DreamPredictionServiceWrapper()
    @State private var config = PredictionConfig.default
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("预测设置")) {
                    Toggle("启用预测", isOn: $config.isEnabled)
                    
                    Stepper("预测天数：\(config.predictionDays) 天", value: $config.predictionDays, in: 1...30)
                    
                    Stepper("置信度阈值：\(Int(config.minConfidenceThreshold * 100))%",
                           value: $config.minConfidenceThreshold,
                           in: 0.3...0.9,
                           step: 0.1)
                }
                
                Section(header: Text("通知设置")) {
                    Toggle("高置信度时通知", isOn: $config.notifyOnHighConfidence)
                    
                    Toggle("包含健康预警", isOn: $config.includeHealthWarnings)
                }
                
                Section(header: Text("数据管理")) {
                    Button("清除旧预测", role: .destructive) {
                        service.clearOldPredictions()
                    }
                }
            }
            .navigationTitle("预测配置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        service.saveConfig(config)
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                config = service.loadConfig()
            }
        }
    }
}

// MARK: - 服务包装器（用于 SwiftUI）

@MainActor
final class DreamPredictionServiceWrapper: ObservableObject {
    private let service = DreamPredictionService.shared
    
    func generatePredictions() async {
        await service.generatePredictions()
    }
    
    func getPredictions() async -> [DreamPrediction] {
        await service.getPredictions(for: Date())
    }
    
    func getStats() async -> PredictionStats {
        await service.getPredictionStats()
    }
    
    func deletePrediction(_ prediction: DreamPrediction) {
        service.deletePrediction(prediction)
    }
    
    func clearOldPredictions() {
        service.clearOldPredictions()
    }
    
    func saveConfig(_ config: PredictionConfig) {
        UserDefaults.standard.set(try? JSONEncoder().encode(config), forKey: "DreamPredictionConfig")
    }
    
    func loadConfig() -> PredictionConfig {
        guard let data = UserDefaults.standard.data(forKey: "DreamPredictionConfig"),
              let config = try? JSONDecoder().decode(PredictionConfig.self, from: data) else {
            return .default
        }
        return config
    }
}

// MARK: - 预览

#Preview {
    DreamPredictionView()
        .modelContainer(for: DreamPrediction.self, inMemory: true)
}
