//
//  DreamPerformanceDashboardView.swift
//  DreamLog
//
//  Phase 89 Session 2: 性能监控仪表板
//  创建时间：2026-03-22
//

import SwiftUI
import os

// MARK: - 性能监控仪表板视图

/// 性能监控仪表板 - 开发者模式
struct DreamPerformanceDashboardView: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    
    @State private var selectedTab = 0
    @State private var isRecording = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // 概览标签页
                OverviewTab(monitor: monitor)
                    .tabItem {
                        Label("概览", systemImage: "gauge")
                    }
                    .tag(0)
                
                // 内存标签页
                MemoryTab(monitor: monitor)
                    .tabItem {
                        Label("内存", systemImage: "memorychip")
                    }
                    .tag(1)
                
                // 查询标签页
                QueryTab(monitor: monitor)
                    .tabItem {
                        Label("查询", systemImage: "list.bullet")
                    }
                    .tag(2)
                
                // 设置标签页
                SettingsTab(monitor: monitor)
                    .tabItem {
                        Label("设置", systemImage: "gear")
                    }
                    .tag(3)
            }
            .navigationTitle("性能监控")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                            .foregroundColor(isRecording ? .red : .gray)
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button(action: exportReport) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            monitor.startRecording()
        } else {
            monitor.stopRecording()
        }
    }
    
    private func exportReport() {
        let report = monitor.generateReport()
        // 这里可以添加分享功能
        print(report)
    }
}

// MARK: - 概览标签页

struct OverviewTab: View {
    @ObservedObject var monitor: PerformanceMonitor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 启动时间卡片
                LaunchTimeCard(launchTime: monitor.launchTime)
                
                // 帧率卡片
                FPSCard(currentFPS: monitor.currentFPS)
                
                // CPU 使用率
                CPUUsageCard(usage: monitor.cpuUsage)
                
                // 网络请求统计
                NetworkStatsCard(stats: monitor.networkStats)
                
                // 慢查询警告
                if monitor.slowQueryCount > 0 {
                    SlowQueryWarningCard(count: monitor.slowQueryCount)
                }
            }
            .padding()
        }
    }
}

// MARK: - 内存标签页

struct MemoryTab: View {
    @ObservedObject var monitor: PerformanceMonitor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 内存使用卡片
                MemoryUsageCard(
                    used: monitor.memoryUsage.used,
                    total: monitor.memoryUsage.total,
                    purgeable: monitor.memoryUsage.purgeable
                )
                
                // 缓存统计
                CacheStatsCard(
                    imageCacheSize: monitor.cacheStats.imageCacheSize,
                    queryCacheSize: monitor.cacheStats.queryCacheSize,
                    totalCacheSize: monitor.cacheStats.totalCacheSize
                )
                
                // 内存分配历史
                MemoryHistoryChart(history: monitor.memoryHistory)
                
                // 清理建议
                MemoryCleanupSuggestions(suggestions: monitor.getCleanupSuggestions())
            }
            .padding()
        }
    }
}

// MARK: - 查询标签页

struct QueryTab: View {
    @ObservedObject var monitor: PerformanceMonitor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 查询统计摘要
                QuerySummaryCard(
                    totalQueries: monitor.queryStats.totalQueries,
                    avgExecutionTime: monitor.queryStats.avgExecutionTime,
                    slowQueries: monitor.queryStats.slowQueries
                )
                
                // 慢查询列表
                SlowQueriesList(queries: monitor.slowQueries)
                
                // 查询类型分布
                QueryTypeDistribution(distribution: monitor.queryTypeDistribution)
            }
            .padding()
        }
    }
}

// MARK: - 设置标签页

struct SettingsTab: View {
    @ObservedObject var monitor: PerformanceMonitor
    
    @AppStorage("performanceOverlayEnabled") private var overlayEnabled = false
    @AppStorage("slowQueryThreshold") private var slowQueryThreshold = 0.1
    @AppStorage("enableQueryCache") private var enableQueryCache = true
    
    var body: some View {
        Form {
            Section("显示选项") {
                Toggle("性能叠加层", isOn: $overlayEnabled)
                    .description("在主界面显示 FPS 和内存使用")
            }
            
            Section("查询优化") {
                Toggle("启用查询缓存", isOn: $enableQueryCache)
                
                HStack {
                    Text("慢查询阈值")
                    Spacer()
                    TextField("秒", value: $slowQueryThreshold, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                .description("执行时间超过此值的查询将被标记")
            }
            
            Section("数据管理") {
                Button("清除查询缓存", action: clearQueryCache)
                Button("清除所有性能数据", action: clearAllData)
                    .foregroundColor(.red)
            }
            
            Section("关于") {
                HStack {
                    Text("监控版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
    }
    
    private func clearQueryCache() {
        Task {
            await DreamDataQueryOptimizer.shared.clearCache()
        }
    }
    
    private func clearAllData() {
        monitor.clearAllData()
    }
}

// MARK: - 性能卡片组件

struct LaunchTimeCard: View {
    let launchTime: TimeInterval
    
    var body: some View {
        PerformanceCard(
            title: "启动时间",
            icon: "timer",
            value: String(format: "%.2f", launchTime),
            unit: "秒",
            status: launchTime < 2.0 ? .good : (launchTime < 3.0 ? .warning : .bad)
        )
    }
}

struct FPSCard: View {
    let currentFPS: Int
    
    var body: some View {
        PerformanceCard(
            title: "帧率",
            icon: "video",
            value: "\(currentFPS)",
            unit: "FPS",
            status: currentFPS >= 55 ? .good : (currentFPS >= 30 ? .warning : .bad)
        )
    }
}

struct CPUUsageCard: View {
    let usage: Double
    
    var body: some View {
        PerformanceCard(
            title: "CPU 使用率",
            icon: "cpu",
            value: String(format: "%.1f", usage * 100),
            unit: "%",
            status: usage < 0.3 ? .good : (usage < 0.6 ? .warning : .bad)
        )
    }
}

struct MemoryUsageCard: View {
    let used: UInt64
    let total: UInt64
    let purgeable: UInt64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("内存使用")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                // 使用进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(memoryColor)
                            .frame(width: geometry.size.width * usagePercentage)
                    }
                }
                .frame(height: 8)
                
                // 详细数据
                HStack {
                    VStack(alignment: .leading) {
                        Text("已使用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatBytes(used))
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("总计")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatBytes(total))
                            .font(.headline)
                    }
                }
                
                HStack {
                    Text("可清除：\(formatBytes(purgeable))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", usagePercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(memoryColor)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
    
    private var memoryColor: Color {
        let percentage = usagePercentage
        if percentage < 0.5 { return .green }
        if percentage < 0.75 { return .yellow }
        return .red
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct PerformanceCard: View {
    let title: String
    let icon: String
    let value: String
    let unit: String
    let status: PerformanceStatus
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(status.color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 状态指示器
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

enum PerformanceStatus {
    case good, warning, bad
    
    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .yellow
        case .bad: return .red
        }
    }
}

// MARK: - 其他卡片组件 (简化版)

struct NetworkStatsCard: View {
    let stats: NetworkStats
    
    var body: some View {
        PerformanceCard(
            title: "网络请求",
            icon: "network",
            value: "\(stats.totalRequests)",
            unit: "次",
            status: stats.avgResponseTime < 1.0 ? .good : .warning
        )
    }
}

struct SlowQueryWarningCard: View {
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            
            Text("发现 \(count) 个慢查询")
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CacheStatsCard: View {
    let imageCacheSize: UInt64
    let queryCacheSize: Int
    let totalCacheSize: UInt64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("缓存统计")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("图片缓存")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatBytes(imageCacheSize))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("查询缓存")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(queryCacheSize) 条")
                        .font(.subheadline)
                }
            }
            
            Divider()
            
            HStack {
                Text("总缓存大小")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatBytes(totalCacheSize))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MemoryHistoryChart: View {
    let history: [MemorySample]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("内存历史")
                .font(.headline)
                .padding(.bottom, 8)
            
            // 简化版图表 - 实际项目中可用 SwiftCharts
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(history.suffix(30), id: \.timestamp) { sample in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(0.6))
                        .frame(height: CGFloat(sample.usedMB) * 0.5)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MemoryCleanupSuggestions: View {
    let suggestions: [CleanupSuggestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("清理建议")
                .font(.headline)
            
            ForEach(suggestions, id: \.id) { suggestion in
                HStack {
                    Image(systemName: suggestion.icon)
                        .foregroundColor(.blue)
                    
                    Text(suggestion.description)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(suggestion.potentialSavings)
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuerySummaryCard: View {
    let totalQueries: Int
    let avgExecutionTime: TimeInterval
    let slowQueries: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("查询统计")
                .font(.headline)
            
            HStack {
                StatItem(label: "总查询", value: "\(totalQueries)")
                StatItem(label: "平均耗时", value: String(format: "%.3fs", avgExecutionTime))
                StatItem(label: "慢查询", value: "\(slowQueries)", valueColor: slowQueries > 0 ? .red : .green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(valueColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SlowQueriesList: View {
    let queries: [SlowQueryInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("慢查询列表")
                .font(.headline)
            
            ForEach(queries.prefix(10), id: \.id) { query in
                HStack {
                    VStack(alignment: .leading) {
                        Text(query.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(query.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.3fs", query.executionTime))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            if queries.isEmpty {
                Text("暂无慢查询 ✅")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QueryTypeDistribution: View {
    let distribution: [String: Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("查询类型分布")
                .font(.headline)
            
            ForEach(distribution.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                HStack {
                    Text(type)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(count) 次")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 数据模型

struct NetworkStats {
    let totalRequests: Int
    let avgResponseTime: TimeInterval
    let failedRequests: Int
}

struct MemorySample {
    let timestamp: Date
    let usedMB: Double
}

struct CleanupSuggestion {
    let id: String
    let description: String
    let icon: String
    let potentialSavings: String
}

struct SlowQueryInfo {
    let id: String
    let name: String
    let description: String
    let executionTime: TimeInterval
}

// MARK: - 性能监控器

class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var launchTime: TimeInterval = 0
    @Published var currentFPS: Int = 60
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: MemoryUsage = MemoryUsage(used: 0, total: 0, purgeable: 0)
    @Published var networkStats: NetworkStats = NetworkStats(totalRequests: 0, avgResponseTime: 0, failedRequests: 0)
    @Published var cacheStats: CacheStats = CacheStats(imageCacheSize: 0, queryCacheSize: 0, totalCacheSize: 0)
    @Published var memoryHistory: [MemorySample] = []
    @Published var queryStats: QueryStats = QueryStats(totalQueries: 0, avgExecutionTime: 0, slowQueries: 0)
    @Published var slowQueries: [SlowQueryInfo] = []
    @Published var queryTypeDistribution: [String: Int] = [:]
    
    @Published var isRecording = false
    
    struct MemoryUsage {
        let used: UInt64
        let total: UInt64
        let purgeable: UInt64
    }
    
    struct CacheStats {
        let imageCacheSize: UInt64
        let queryCacheSize: Int
        let totalCacheSize: UInt64
    }
    
    struct QueryStats {
        let totalQueries: Int
        let avgExecutionTime: TimeInterval
        let slowQueries: Int
    }
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // 启动性能监控
        // 实际项目中会集成 Instruments 或自定义监控
    }
    
    func startRecording() {
        isRecording = true
    }
    
    func stopRecording() {
        isRecording = false
    }
    
    func generateReport() -> String {
        var report = "=== DreamLog 性能报告 ===\n\n"
        report += "启动时间：\(String(format: "%.2f", launchTime))s\n"
        report += "当前 FPS: \(currentFPS)\n"
        report += "CPU 使用率：\(String(format: "%.1f", cpuUsage * 100))%\n"
        report += "内存使用：\(memoryUsage.used / 1024 / 1024)MB\n"
        report += "总查询数：\(queryStats.totalQueries)\n"
        report += "慢查询数：\(queryStats.slowQueries)\n"
        return report
    }
    
    func getCleanupSuggestions() -> [CleanupSuggestion] {
        // 返回清理建议
        return []
    }
    
    func clearAllData() {
        // 清除所有性能数据
    }
}

// MARK: - 预览

#Preview {
    DreamPerformanceDashboardView()
}
