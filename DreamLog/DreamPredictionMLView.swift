//
//  DreamPredictionMLView.swift
//  DreamLog
//
//  AI 梦境预测 2.0 - ML 预测可视化界面
//  Phase 35 - Core ML 集成与性能优化 ✨🧠
//

import SwiftUI
import SwiftData
import Charts

// MARK: - ML 预测主界面

/// ML 预测主界面 - 展示基于 Core ML 的梦境预测
struct DreamPredictionMLView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var mlService = DreamPredictionMLService.shared
    @State private var predictions: [MLPredictionResult] = []
    @State private var isRefreshing = false
    @State private var selectedType: MLPredictionType?
    @State private var showConfigSheet = false
    @State private var showAccuracyDetails = false
    @State private var predictionStats: MLPredictionStats = .empty
    
    var body: some View {
        NavigationView {
            Group {
                if predictions.isEmpty && !isRefreshing {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("AI 预测 2.0 🧠")
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
                MLPredictionConfigView()
            }
            .sheet(isPresented: $showAccuracyDetails) {
                PredictionAccuracyDetailView()
            }
            .onAppear {
                loadPredictions()
            }
            .refreshable {
                await refreshPredictions()
            }
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("AI 预测 2.0")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("需要至少 10 条梦境记录\n才能生成 ML 预测")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { }) {
                Label("开始记录梦境", systemImage: "plus.circle")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 内容视图
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 统计概览
                overviewCard
                
                // 准确度追踪
                accuracyCard
                
                // 预测类型筛选
                typeFilter
                
                // 预测详情
                predictionDetails
                
                // 重新生成按钮
                regenerateButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 概览卡片
    
    private var overviewCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ML 预测概览")
                        .font(.headline)
                    Text("基于 Core ML 机器学习模型")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .foregroundColor(.accentColor)
                    Text("Core ML")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            }
            
            Divider()
            
            // 预测类型分布
            HStack(spacing: 12) {
                PredictionTypeStatView(
                    type: .emotionTrend,
                    count: predictionStats.predictionsByType[.emotionTrend] ?? 0,
                    icon: "📈"
                )
                
                PredictionTypeStatView(
                    type: .themeEvolution,
                    count: predictionStats.predictionsByType[.themeEvolution] ?? 0,
                    icon: "🎬"
                )
                
                PredictionTypeStatView(
                    type: .lucidProbability,
                    count: predictionStats.predictionsByType[.lucidProbability] ?? 0,
                    icon: "💡"
                )
                
                PredictionTypeStatView(
                    type: .clarityLevel,
                    count: predictionStats.predictionsByType[.clarityLevel] ?? 0,
                    icon: "✨"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 准确度卡片
    
    private var accuracyCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("预测准确度")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showAccuracyDetails = true }) {
                    Text("详情")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            HStack(spacing: 16) {
                // 整体准确度
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均准确度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", predictionStats.averageAccuracy * 100))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getAccuracyColor(predictionStats.averageAccuracy))
                }
                
                Spacer()
                
                // 预测次数
                VStack(alignment: .trailing, spacing: 4) {
                    Text("已验证预测")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(predictionStats.validatedPredictions)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
            }
            
            // 准确度趋势迷你图
            if !predictionStats.accuracyHistory.isEmpty {
                MiniAccuracyChartView(history: predictionStats.accuracyHistory)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 类型筛选
    
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
                
                ForEach(MLPredictionType.allCases, id: \.self) { type in
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
    
    // MARK: - 预测详情
    
    private var predictionDetails: some View {
        VStack(spacing: 12) {
            ForEach(filteredPredictions, id: \.type) { prediction in
                MLPredictionCard(prediction: prediction)
            }
        }
    }
    
    private var filteredPredictions: [MLPredictionResult] {
        if let selectedType = selectedType {
            return predictions.filter { $0.type == selectedType }
        }
        return predictions
    }
    
    // MARK: - 重新生成按钮
    
    private var regenerateButton: some View {
        Button(action: regeneratePredictions) {
            HStack {
                Image(systemName: "sparkles")
                Text("重新生成预测")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isRefreshing)
    }
    
    // MARK: - 方法
    
    private func loadPredictions() {
        Task {
            isRefreshing = true
            
            do {
                predictions = try await mlService.generateAllPredictions()
                predictionStats = await mlService.getPredictionStats()
            } catch {
                print("❌ 加载预测失败：\(error.localizedDescription)")
            }
            
            isRefreshing = false
        }
    }
    
    private func refreshPredictions() async {
        isRefreshing = true
        
        do {
            predictions = try await mlService.generateAllPredictions(forceRefresh: true)
            predictionStats = await mlService.getPredictionStats()
        } catch {
            print("❌ 刷新预测失败：\(error.localizedDescription)")
        }
        
        isRefreshing = false
    }
    
    private func regeneratePredictions() {
        Task {
            await refreshPredictions()
        }
    }
    
    private func getAccuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 {
            return .green
        } else if accuracy >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - ML 预测卡片

struct MLPredictionCard: View {
    let prediction: MLPredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack {
                Text(prediction.type.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(prediction.type.displayName)
                        .font(.headline)
                    Text(prediction.type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 置信度徽章
                ConfidenceBadge(confidence: prediction.confidence)
            }
            
            Divider()
            
            // 预测内容
            predictionContent
            
            // 特征重要性（如果有）
            if !prediction.featureImportance.isEmpty {
                featureImportanceSection
            }
            
            // 建议
            if !prediction.suggestions.isEmpty {
                suggestionsSection
            }
            
            // 时间戳
            Text("生成于 \(prediction.generatedAt.formatted(.dateTime.hour().minute()))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var predictionContent: some View {
        Group {
            switch prediction.type {
            case .emotionTrend:
                EmotionTrendPredictionView(prediction: prediction)
            case .themeEvolution:
                ThemeEvolutionPredictionView(prediction: prediction)
            case .lucidProbability:
                LucidProbabilityPredictionView(prediction: prediction)
            case .clarityLevel:
                ClarityLevelPredictionView(prediction: prediction)
            case .recallQuality:
                RecallQualityPredictionView(prediction: prediction)
            case .dreamFrequency:
                DreamFrequencyPredictionView(prediction: prediction)
            }
        }
    }
    
    private var featureImportanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关键特征")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(Array(prediction.featureImportance.prefix(3)), id: \.name) { feature in
                HStack {
                    Text(feature.name)
                        .font(.caption)
                    Spacer()
                    FeatureImportanceBar(importance: feature.importance)
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("个性化建议")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(Array(prediction.suggestions.prefix(2)), id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - 置信度徽章

struct ConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.medium")
            Text(String(format: "%.0f%%", confidence * 100))
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(getConfidenceColor(confidence))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(getConfidenceColor(confidence).opacity(0.1))
        .cornerRadius(6)
    }
    
    private func getConfidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - 特征重要性条

struct FeatureImportanceBar: View {
    let importance: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * CGFloat(importance), height: 6)
            }
        }
        .frame(width: 100, height: 6)
    }
}

// MARK: - 预测类型统计视图

struct PredictionTypeStatView: View {
    let type: MLPredictionType
    let count: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            Text(type.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - 迷你准确度图表

struct MiniAccuracyChartView: View {
    let history: [(date: Date, accuracy: Double)]
    
    var body: some View {
        Chart(history, id: \.date) { item in
            LineMark(
                x: .value("日期", item.date),
                y: .value("准确度", item.accuracy)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.accentColor)
        }
        .frame(height: 80)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel(format: .percent)
            }
        }
    }
}

// MARK: - 配置视图

struct MLPredictionConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = DreamPredictionMLService.shared
    @State private var config = MLPredictionConfig.default
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("预测设置")) {
                    Toggle("启用 ML 预测", isOn: $config.enabled)
                    
                    Picker("预测模型", selection: $config.modelType) {
                        Text("自动选择").tag(MLModelType.auto)
                        Text("情绪预测").tag(MLModelType.emotion)
                        Text("主题演变").tag(MLModelType.theme)
                        Text("清醒梦概率").tag(MLModelType.lucid)
                    }
                }
                
                Section(header: Text("数据要求")) {
                    HStack {
                        Text("最小训练数据")
                        Spacer()
                        Text("\(config.minTrainingData) 条梦境")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("数据更新频率")
                        Spacer()
                        Picker("", selection: $config.updateFrequency) {
                            Text("每天").tag(1)
                            Text("每周").tag(7)
                            Text("每月").tag(30)
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("高级选项")) {
                    Toggle("显示特征重要性", isOn: $config.showFeatureImportance)
                    Toggle("包含个性化建议", isOn: $config.includeSuggestions)
                    Toggle("追踪预测准确度", isOn: $config.trackAccuracy)
                }
                
                Section {
                    Button("重置为默认设置") {
                        config = .default
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("ML 预测配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveConfig()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadConfig()
            }
        }
    }
    
    private func loadConfig() {
        // 从服务加载配置
    }
    
    private func saveConfig() {
        service.saveConfig()
    }
}

// MARK: - 准确度详情视图

struct PredictionAccuracyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = DreamPredictionMLService.shared
    @State private var stats = PredictionAccuracyStats()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 总体统计
                    overallStatsCard
                    
                    // 按类型统计
                    statsByTypeCard
                    
                    // 历史趋势
                    accuracyTrendChart
                    
                    // 最近验证记录
                    recentValidations
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("准确度详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadStats()
            }
        }
    }
    
    private var overallStatsCard: some View {
        VStack(spacing: 12) {
            Text("总体统计")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItemView(
                    title: "平均准确度",
                    value: String(format: "%.1f%%", stats.averageAccuracy * 100),
                    icon: "🎯"
                )
                
                StatItemView(
                    title: "已验证预测",
                    value: "\(stats.validatedPredictions)",
                    icon: "✅"
                )
                
                StatItemView(
                    title: "总预测数",
                    value: "\(stats.totalPredictions)",
                    icon: "📊"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var statsByTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("按类型统计")
                .font(.headline)
            
            ForEach(MLPredictionType.allCases, id: \.self) { type in
                HStack {
                    Text("\(type.icon) \(type.displayName)")
                    Spacer()
                    if let typeStats = stats.accuracyByType[type] {
                        Text(String(format: "%.1f%%", typeStats * 100))
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var accuracyTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("准确度趋势")
                .font(.headline)
            
            // 这里可以使用 Charts 框架展示趋势图
            Text("[准确度趋势图表]")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var recentValidations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近验证记录")
                .font(.headline)
            
            ForEach(0..<5, id: \.self) { _ in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("情绪趋势预测")
                            .font(.subheadline)
                        Text("2 小时前")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("准确")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func loadStats() {
        // 从服务加载统计
    }
}

// MARK: - 各种预测类型的具体视图

struct EmotionTrendPredictionView: View {
    let prediction: MLPredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("未来 7 天情绪趋势预测")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 情绪趋势图表占位
            VStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { day in
                    HStack {
                        Text("第 \(day + 1) 天")
                            .font(.caption)
                            .frame(width: 50)
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor.opacity(Double.random(in: 0.3...0.9)))
                            .frame(width: CGFloat.random(in: 50...150), height: 8)
                    }
                }
            }
            .padding()
            .background(Color.accentColor.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

struct ThemeEvolutionPredictionView: View {
    let prediction: MLPredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("梦境主题演变预测")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("预计未来将出现更多「冒险」和「探索」主题")
                .font(.body)
        }
    }
}

struct LucidProbabilityPredictionView: View {
    let prediction: MLPredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("清醒梦概率预测")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("今晚概率:")
                Spacer()
                Text("68%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            ProgressView(value: 0.68)
                .progressViewStyle(.linear)
        }
    }
}

struct ClarityLevelPredictionView: View {
    let prediction: MLPredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("梦境清晰度预测")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("预计清晰度：高（85%）")
                .font(.body)
        }
    }
}

struct RecallQualityPredictionView: View {
    let prediction: MLPredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("梦境回忆质量预测")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("预计回忆质量：中等")
                .font(.body)
        }
    }
}

struct DreamFrequencyPredictionView: View {
    let prediction: MLPredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("梦境频率预测")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("预计本周梦境数量：4-6 个")
                .font(.body)
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
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
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
            .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
            .foregroundColor(isSelected ? .white : .accentColor)
            .cornerRadius(20)
        }
    }
}

// MARK: - 预览

#Preview {
    DreamPredictionMLView()
}
