//
//  SleepDataView.swift
//  DreamLog
//
//  睡眠数据可视化视图
//

import SwiftUI
import HealthKit

// MARK: - 睡眠数据主视图

struct SleepDataView: View {
    @ObservedObject private var healthKitService = HealthKitService.shared
    @State private var showingAuthRequest = false
    @State private var selectedRecord: SleepRecord?
    
    var body: some View {
        NavigationView {
            Group {
                if !healthKitService.isAuthorized {
                    AuthorizationView(onAuthorize: {
                        showingAuthRequest = true
                    })
                } else if healthKitService.isLoading {
                    SleepDataLoadingView()
                } else if healthKitService.sleepRecords.isEmpty {
                    EmptySleepDataView(onSync: {
                        Task {
                            await healthKitService.syncSleepData()
                        }
                    })
                } else {
                    SleepDataListView(
                        records: healthKitService.sleepRecords,
                        onSelectRecord: { selectedRecord = $0 }
                    )
                }
            }
            .navigationTitle("睡眠数据")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if healthKitService.isAuthorized && !healthKitService.sleepRecords.isEmpty {
                        Button(action: {
                            Task {
                                await healthKitService.syncSleepData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAuthRequest) {
                AuthRequestView()
            }
            .sheet(item: $selectedRecord) { record in
                SleepRecordDetailView(record: record)
            }
        }
    }
}

// MARK: - 授权视图

struct AuthorizationView: View {
    let onAuthorize: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("连接健康 App")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("DreamLog 可以读取您的睡眠数据，帮助分析梦境与睡眠质量的关系。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "moon.stars", text: "分析梦境与睡眠阶段的关系")
                BenefitRow(icon: "chart.bar", text: "追踪睡眠质量趋势")
                BenefitRow(icon: "brain.head.profile", text: "发现最佳做梦时段")
                BenefitRow(icon: "lock.shield", text: "数据仅存储在本地，保护隐私")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Button(action: onAuthorize) {
                Label("授权访问健康数据", systemImage: "heart")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

// MARK: - 授权请求视图

struct AuthRequestView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var healthKitService = HealthKitService.shared
    @State private var isRequesting = false
    @State private var success = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isRequesting {
                    ProgressView("请求授权...")
                        .scaleEffect(1.5)
                } else if success {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("授权成功")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("现在可以同步您的睡眠数据了")
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("需要授权")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("请在健康 App 中允许 DreamLog 读取睡眠数据")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("HealthKit 授权")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if success {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    isRequesting = true
                    success = try await healthKitService.requestAuthorization()
                    isRequesting = false
                }
            }
        }
    }
}

// MARK: - 加载视图

struct SleepDataLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("同步睡眠数据中...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 空数据视图

struct EmptySleepDataView: View {
    let onSync: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("暂无睡眠数据")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("点击按钮同步 HealthKit 中的睡眠记录")
                .foregroundColor(.secondary)
            
            Button(action: onSync) {
                Label("同步数据", systemImage: "arrow.down.circle")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - 睡眠数据列表

struct SleepDataListView: View {
    let records: [SleepRecord]
    let onSelectRecord: (SleepRecord) -> Void
    
    var body: some View {
        List {
            // 统计摘要
            Section {
                SleepStatsCard(records: records)
            }
            
            // 睡眠记录列表
            Section("最近睡眠") {
                ForEach(records) { record in
                    SleepRecordRow(record: record)
                        .onTapGesture {
                            onSelectRecord(record)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - 睡眠统计卡片

struct SleepStatsCard: View {
    let records: [SleepRecord]
    
    private var averageDuration: TimeInterval {
        guard !records.isEmpty else { return 0 }
        return records.reduce(0) { $0 + $1.duration } / Double(records.count)
    }
    
    private var averageHours: Double {
        averageDuration / 3600
    }
    
    private var qualityDistribution: (excellent: Int, good: Int, fair: Int, poor: Int) {
        (
            excellent: records.filter { $0.quality == .excellent }.count,
            good: records.filter { $0.quality == .good }.count,
            fair: records.filter { $0.quality == .fair }.count,
            poor: records.filter { $0.quality == .poor }.count
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                SleepDataStatItem(
                    icon: "bed.double",
                    value: String(format: "%.1f", averageHours),
                    label: "平均时长 (小时)"
                )
                
                SleepDataStatItem(
                    icon: "moon.stars",
                    value: "\(records.count)",
                    label: "记录天数"
                )
                
                SleepDataStatItem(
                    icon: "heart",
                    value: qualityDistribution.excellent.description,
                    label: "优质睡眠"
                )
            }
            
            // 质量分布条
            VStack(alignment: .leading, spacing: 8) {
                Text("睡眠质量分布")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    if !records.isEmpty {
                        QualityBarSegment(
                            count: qualityDistribution.excellent,
                            total: records.count,
                            color: SleepRecord.SleepQuality.excellent.color
                        )
                        QualityBarSegment(
                            count: qualityDistribution.good,
                            total: records.count,
                            color: SleepRecord.SleepQuality.good.color
                        )
                        QualityBarSegment(
                            count: qualityDistribution.fair,
                            total: records.count,
                            color: SleepRecord.SleepQuality.fair.color
                        )
                        QualityBarSegment(
                            count: qualityDistribution.poor,
                            total: records.count,
                            color: SleepRecord.SleepQuality.poor.color
                        )
                    }
                }
                .frame(height: 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
                
                HStack(spacing: 12) {
                    QualityLegendItem(color: SleepRecord.SleepQuality.excellent.color, label: "优秀")
                    QualityLegendItem(color: SleepRecord.SleepQuality.good.color, label: "良好")
                    QualityLegendItem(color: SleepRecord.SleepQuality.fair.color, label: "一般")
                    QualityLegendItem(color: SleepRecord.SleepQuality.poor.color, label: "较差")
                }
                .font(.caption2)
            }
        }
        .padding()
    }
}

struct SleepDataStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QualityBarSegment: View {
    let count: Int
    let total: Int
    let color: String
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: color))
            .frame(width: CGFloat(count) / CGFloat(total) * 200)
    }
}

struct QualityLegendItem: View {
    let color: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - 睡眠记录行

struct SleepRecordRow: View {
    let record: SleepRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // 质量图标
            VStack {
                Text(record.quality.icon)
                    .font(.title2)
            }
            .frame(width: 44, height: 44)
            .background(Color(hex: record.quality.color).opacity(0.2))
            .cornerRadius(22)
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(record.startDate.formatted(.dateTime.month().day().weekday(.short)))
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Label(record.durationFormatted, systemImage: "clock")
                    Label("\(record.startTimeFormatted) - \(record.endTimeFormatted)", systemImage: "bed.double")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 质量标签
            Text(record.quality.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: record.quality.color).opacity(0.2))
                .foregroundColor(Color(hex: record.quality.color))
                .cornerRadius(12)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 睡眠记录详情

struct SleepRecordDetailView: View {
    let record: SleepRecord
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var healthKitService = HealthKitService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 头部信息
                    SleepHeaderCard(record: record)
                    
                    // 睡眠阶段
                    SleepStagesCard(stages: record.stages)
                    
                    // 质量分析
                    QualityAnalysisCard(record: record)
                    
                    // 关联的梦境
                    if let dream = findAssociatedDream() {
                        AssociatedDreamCard(dream: dream)
                    }
                    
                    // 建议
                    SleepSuggestionsCard(record: record)
                }
                .padding()
            }
            .navigationTitle("睡眠详情")
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
    
    private func findAssociatedDream() -> Dream? {
        // 查找关联的梦境 (简化实现)
        return nil
    }
}

struct SleepHeaderCard: View {
    let record: SleepRecord
    
    var body: some View {
        VStack(spacing: 16) {
            Text(record.quality.icon)
                .font(.system(size: 60))
            
            VStack(spacing: 4) {
                Text(record.quality.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(record.startDate.formatted(.dateTime.weekday().month().day()))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 30) {
                DetailSleepDataStatItem(
                    icon: "clock",
                    value: record.durationFormatted,
                    label: "总时长"
                )
                
                DetailSleepDataStatItem(
                    icon: "bed.double",
                    value: "\(record.startTimeFormatted) - \(record.endTimeFormatted)",
                    label: "睡眠时间"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct DetailStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SleepStagesCard: View {
    let stages: [SleepRecord.SleepStage]
    
    private var stageCounts: [SleepRecord.SleepStage: Int] {
        Dictionary(grouping: stages, by: { $0 })
            .mapValues { $0.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("睡眠阶段")
                .font(.headline)
            
            ForEach(SleepRecord.SleepStage.allCases, id: \.self) { stage in
                if let count = stageCounts[stage] {
                    StageRow(stage: stage, count: count, total: stages.count)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct StageRow: View {
    let stage: SleepRecord.SleepStage
    let count: Int
    let total: Int
    
    var percentage: Double {
        Double(count) / Double(total) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(stage.icon) \(stage.rawValue)")
                    .font(.body)
                Spacer()
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(Color(hex: stage.color))
                        .frame(width: geometry.size.width * percentage / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct QualityAnalysisCard: View {
    let record: SleepRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("质量分析")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                AnalysisRow(
                    icon: "checkmark.circle",
                    text: "睡眠时长充足",
                    show: record.duration >= 7 * 3600
                )
                
                AnalysisRow(
                    icon: "moon.stars",
                    text: "深度睡眠比例良好",
                    show: Double(record.stages.filter { $0 == .deep }.count) / Double(record.stages.count) >= 0.15
                )
                
                AnalysisRow(
                    icon: "sparkles",
                    text: "REM 睡眠正常",
                    show: Double(record.stages.filter { $0 == .rem }.count) / Double(record.stages.count) >= 0.20
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct AnalysisRow: View {
    let icon: String
    let text: String
    let show: Bool
    
    var body: some View {
        if show {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.green)
                Text(text)
                    .font(.body)
            }
        }
    }
}

struct AssociatedDreamCard: View {
    let dream: Dream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关联梦境")
                .font(.headline)
            
            HStack {
                Text(dream.title)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(dream.date.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(dream.content.prefix(100))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct SleepSuggestionsCard: View {
    let record: SleepRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("改善建议")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if record.duration < 7 * 3600 {
                    SuggestionRow(
                        icon: "moon",
                        text: "尝试提前入睡，保证 7-8 小时睡眠"
                    )
                }
                
                if Double(record.stages.filter { $0 == .awake }.count) / Double(record.stages.count) > 0.1 {
                    SuggestionRow(
                        icon: "wifi.slash",
                        text: "减少睡前使用电子设备，保持环境安静"
                    )
                }
                
                if record.quality == .excellent {
                    SuggestionRow(
                        icon: "star",
                        text: "保持当前的睡眠习惯，非常棒！"
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.body)
        }
    }
}

// MARK: - 预览

#Preview {
    SleepDataView()
}
