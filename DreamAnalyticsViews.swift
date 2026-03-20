//
//  DreamAnalyticsViews.swift
//  DreamLog
//
//  Phase 74: 梦境数据分析增强 📊🔍
//  高级分析可视化组件
//
//  Created: 2026-03-20
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - 高级分析仪表板

/// 高级分析仪表板视图
public struct DreamAnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var overview: AnalyticsOverview?
    @State private var loading = true
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // 概览标签
                OverviewTab(overview: overview, loading: $loading)
                    .tabItem {
                        Label("概览", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                
                // 交叉分析标签
                CrossAnalysisTab()
                    .tabItem {
                        Label("交叉分析", systemImage: "tablecells")
                    }
                    .tag(1)
                
                // 趋势预测标签
                ForecastTab()
                    .tabItem {
                        Label("趋势预测", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(2)
                
                // 聚类分析标签
                ClusteringTab()
                    .tabItem {
                        Label("聚类分析", systemImage: "circle.grid.2x2")
                    }
                    .tag(3)
            }
            .navigationTitle("数据分析")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadOverview()
            }
            .refreshable {
                await loadOverview()
            }
        }
    }
    
    private func loadOverview() async {
        loading = true
        do {
            overview = try await DreamAdvancedAnalyticsService.shared.getAnalyticsOverview(
                in: modelContext
            )
        } catch {
            print("加载概览失败：\(error)")
        }
        loading = false
    }
}

// MARK: - 概览标签页

struct OverviewTab: View {
    let overview: AnalyticsOverview?
    @Binding var loading: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if loading {
                    ProgressView("加载分析数据...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let overview = overview {
                    // 统计卡片
                    StatsCards(overview: overview)
                    
                    // 快速洞察
                    QuickInsights(overview: overview)
                    
                    // 最近趋势
                    RecentTrendCard(trend: overview.recentTrend)
                } else {
                    ContentUnavailableView(
                        "暂无数据",
                        systemImage: "chart.bar.xaxis",
                        description: Text("开始记录梦境后，这里会显示分析数据")
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 统计卡片

struct StatsCards: View {
    let overview: AnalyticsOverview
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "总梦境数",
                value: "\(overview.totalDreams)",
                icon: "moon.fill",
                color: .purple
            )
            
            StatCard(
                title: "平均清晰度",
                value: "\(Int(overview.averageClarity * 100))%",
                icon: "eye.fill",
                color: .blue
            )
            
            StatCard(
                title: "清醒梦",
                value: "\(overview.lucidDreamCount)",
                icon: "brain.head.profile",
                color: .green
            )
            
            StatCard(
                title: "主导情绪",
                value: overview.dominantEmotion,
                icon: "face.smiling",
                color: .orange
            )
        }
    }
}

// MARK: - 统计卡片组件

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - 快速洞察

struct QuickInsights: View {
    let overview: AnalyticsOverview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速洞察")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "记录趋势",
                    value: overview.recentTrend,
                    color: overview.recentTrend.contains("上升") ? .green : 
                           overview.recentTrend.contains("下降") ? .red : .gray
                )
                
                InsightRow(
                    icon: "moon.stars.fill",
                    title: "清醒梦比例",
                    value: "\(Int(Double(overview.lucidDreamCount) / Double(overview.totalDreams) * 100))%",
                    color: .purple
                )
                
                InsightRow(
                    icon: "face.smiling",
                    title: "积极情绪",
                    value: "保持良好",
                    color: .green
                )
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

// MARK: - 洞察行

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - 近期趋势卡片

struct RecentTrendCard: View {
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("近期趋势")
                .font(.headline)
            
            HStack {
                Spacer()
                
                Text(trend)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(trend.contains("上升") ? .green : 
                                    trend.contains("下降") ? .red : .blue)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

// MARK: - 交叉分析标签页

struct CrossAnalysisTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDimension: CrossAnalysisDimension = .emotionSymbol
    @State private var analysisResult: CrossAnalysisResult?
    @State private var loading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 维度选择器
                DimensionPicker(selectedDimension: $selectedDimension)
                    .onChange(of: selectedDimension) { _, newValue in
                        Task {
                            await performAnalysis(dimension: newValue)
                        }
                    }
                
                // 分析结果
                if loading {
                    ProgressView("分析中...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let result = analysisResult {
                    HeatmapView(result: result)
                    
                    if !result.significantCorrelations.isEmpty {
                        SignificantCorrelationsView(correlations: result.significantCorrelations)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .task {
            await performAnalysis(dimension: selectedDimension)
        }
    }
    
    private func performAnalysis(dimension: CrossAnalysisDimension) async {
        loading = true
        do {
            analysisResult = try await DreamAdvancedAnalyticsService.shared.performCrossAnalysis(
                dimension: dimension,
                in: modelContext
            )
        } catch {
            print("分析失败：\(error)")
        }
        loading = false
    }
}

// MARK: - 维度选择器

struct DimensionPicker: View {
    @Binding var selectedDimension: CrossAnalysisDimension
    
    var body: some View {
        Picker("分析维度", selection: $selectedDimension) {
            ForEach(CrossAnalysisDimension.allCases, id: \.self) { dimension in
                Text(dimension.displayName).tag(dimension)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - 热力图视图

struct HeatmapView: View {
    let result: CrossAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关联热力图")
                .font(.headline)
            
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 2) {
                    // 列标题
                    HStack(spacing: 2) {
                        Spacer().frame(width: 80)
                        ForEach(result.columnLabels, id: \.self) { label in
                            Text(label)
                                .font(.caption2)
                                .frame(width: 40)
                                .lineLimit(1)
                        }
                    }
                    
                    // 数据行
                    ForEach(Array(result.rowLabels.enumerated()), id: \.offset) { rowIndex, rowLabel in
                        HStack(spacing: 2) {
                            Text(rowLabel)
                                .font(.caption2)
                                .frame(width: 80)
                                .lineLimit(1)
                            
                            ForEach(Array(result.correlationMatrix[rowIndex].enumerated()), id: \.offset) { colIndex, value in
                                Rectangle()
                                    .fill(heatmapColor(for: value))
                                    .frame(width: 40, height: 30)
                                    .overlay(
                                        Text(String(format: "%.1f", value))
                                            .font(.caption2)
                                            .foregroundColor(value > 0.5 ? .white : .black)
                                    )
                            }
                        }
                    }
                }
            }
            
            // 图例
            HStack {
                Text("低")
                    .font(.caption2)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.6), .blue.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 10)
                
                Text("高")
                    .font(.caption2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
    
    private func heatmapColor(for value: Double) -> Color {
        let intensity = min(1.0, max(0.0, value))
        return Color.blue.opacity(0.3 + intensity * 0.6)
    }
}

// MARK: - 显著关联视图

struct SignificantCorrelationsView: View {
    let correlations: [CrossAnalysisResult.SignificantCorrelation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("显著关联")
                .font(.headline)
            
            ForEach(correlations, id: \.columnLabel) { correlation in
                HStack {
                    Text("\(correlation.rowLabel)")
                        .fontWeight(.medium)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    
                    Text("\(correlation.columnLabel)")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(correlation.strengthLevel)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(correlation.strengthColor)
                        )
                }
                .padding(.vertical, 4)
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

extension CrossAnalysisResult.SignificantCorrelation {
    var strengthColor: Color {
        switch strengthLevel {
        case "极强": return .red.opacity(0.2)
        case "很强": return .orange.opacity(0.2)
        case "强": return .yellow.opacity(0.2)
        default: return .green.opacity(0.2)
        }
    }
}

// MARK: - 趋势预测标签页

struct ForecastTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedType: TimeSeriesForecast.ForecastType = .dreamFrequency
    @State private var forecast: TimeSeriesForecast?
    @State private var loading = false
    @State private var forecastDays = 7
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 类型选择器
                TypePicker(selectedType: $selectedType)
                    .onChange(of: selectedType) { _, newValue in
                        Task {
                            await generateForecast(type: newValue)
                        }
                    }
                
                // 天数选择
                Stepper("预测 \(forecastDays) 天", value: $forecastDays, in: 1...30)
                    .onChange(of: forecastDays) { _, newValue in
                        Task {
                            await generateForecast(type: selectedType)
                        }
                    }
                
                // 预测结果
                if loading {
                    ProgressView("生成预测...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let forecast = forecast {
                    ForecastChart(forecast: forecast)
                    
                    ForecastSummary(forecast: forecast)
                }
                
                Spacer()
            }
            .padding()
        }
        .task {
            await generateForecast(type: selectedType)
        }
    }
    
    private func generateForecast(type: TimeSeriesForecast.ForecastType) async {
        loading = true
        do {
            forecast = try await DreamAdvancedAnalyticsService.shared.generateTimeSeriesForecast(
                type: type,
                days: forecastDays,
                in: modelContext
            )
        } catch {
            print("预测失败：\(error)")
        }
        loading = false
    }
}

// MARK: - 类型选择器

struct TypePicker: View {
    @Binding var selectedType: TimeSeriesForecast.ForecastType
    
    var body: some View {
        Picker("预测类型", selection: $selectedType) {
            ForEach(TimeSeriesForecast.ForecastType.allCases, id: \.self) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - 预测图表

struct ForecastChart: View {
    let forecast: TimeSeriesForecast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("趋势预测")
                .font(.headline)
            
            Chart {
                // 历史数据
                ForEach(forecast.historicalData, id: \.timestamp) { point in
                    LineMark(
                        x: .value("日期", point.timestamp),
                        y: .value("数值", point.value)
                    )
                    .foregroundStyle(.blue)
                }
                
                // 预测数据
                ForEach(forecast.forecastedData, id: \.timestamp) { point in
                    LineMark(
                        x: .value("日期", point.timestamp),
                        y: .value("数值", point.value)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(dash: [5, 5]))
                }
                
                // 置信区间
                ForEach(Array(forecast.forecastedData.enumerated()), id: \.offset) { index, point in
                    RuleMark(
                        x: .value("日期", point.timestamp)
                    )
                    .annotation(position: .overlay) {
                        VStack {
                            Text(String(format: "%.1f", forecast.upperBound[index]))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%.1f", forecast.lowerBound[index]))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day))
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

// MARK: - 预测摘要

struct ForecastSummary: View {
    let forecast: TimeSeriesForecast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("预测摘要")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("趋势方向")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(forecast.trendDirection.displayName)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("趋势强度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(forecast.trendStrength * 100))%")
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

// MARK: - 聚类分析标签页

struct ClusteringTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var clusteringResult: ClusteringResult?
    @State private var loading = false
    @State private var selectedAlgorithm: ClusteringResult.ClusteringAlgorithm = .kmeans
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 算法选择器
                AlgorithmPicker(selectedAlgorithm: $selectedAlgorithm)
                    .onChange(of: selectedAlgorithm) { _, newValue in
                        Task {
                            await performClustering(algorithm: newValue)
                        }
                    }
                
                // 聚类结果
                if loading {
                    ProgressView("聚类分析中...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let result = clusteringResult {
                    ClusteringQualityCard(qualityScore: result.qualityScore)
                    
                    ForEach(result.clusters) { cluster in
                        ClusterCard(cluster: cluster)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .task {
            await performClustering(algorithm: selectedAlgorithm)
        }
    }
    
    private func performClustering(algorithm: ClusteringResult.ClusteringAlgorithm) async {
        loading = true
        do {
            clusteringResult = try await DreamAdvancedAnalyticsService.shared.performClustering(
                algorithm: algorithm,
                in: modelContext
            )
        } catch {
            print("聚类失败：\(error)")
        }
        loading = false
    }
}

// MARK: - 算法选择器

struct AlgorithmPicker: View {
    @Binding var selectedAlgorithm: ClusteringResult.ClusteringAlgorithm
    
    var body: some View {
        Picker("聚类算法", selection: $selectedAlgorithm) {
            ForEach(ClusteringResult.ClusteringAlgorithm.allCases, id: \.self) { algorithm in
                Text(algorithm.displayName).tag(algorithm)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - 聚类质量卡片

struct ClusteringQualityCard: View {
    let qualityScore: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("聚类质量")
                .font(.headline)
            
            ProgressView(value: qualityScore)
                .tint(qualityScore > 0.7 ? .green : qualityScore > 0.5 ? .yellow : .red)
            
            Text("质量分数：\(String(format: "%.1f", qualityScore * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

// MARK: - 聚类卡片

struct ClusterCard: View {
    let cluster: ClusteringResult.DreamCluster
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(cluster.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(cluster.size) 个梦境")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.2))
                    )
            }
            
            if let emotion = cluster.dominantEmotion {
                Label(emotion.displayName, systemImage: emotion.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !cluster.commonSymbols.isEmpty {
                Text("常见符号：\(cluster.commonSymbols.prefix(5).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            ForEach(cluster.characteristics, id: \.self) { characteristic in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(characteristic)
                        .font(.caption)
                        .foregroundColor(.secondary)
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

// MARK: - 预览

#Preview {
    DreamAnalyticsDashboardView()
        .modelContainer(for: DreamEntry.self, inMemory: true)
}
