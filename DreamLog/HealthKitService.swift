//
//  HealthKitService.swift
//  DreamLog
//
//  HealthKit 集成 - 睡眠数据与梦境关联
//

import Foundation
import HealthKit

// MARK: - 睡眠数据模型

/// 睡眠记录
struct SleepRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval  // 秒
    var quality: SleepQuality
    var source: String
    var stages: [SleepStage]
    
    enum SleepQuality: String, Codable, CaseIterable {
        case excellent = "优秀"
        case good = "良好"
        case fair = "一般"
        case poor = "较差"
        
        var color: String {
            switch self {
            case .excellent: return "4CAF50"
            case .good: return "8BC34A"
            case .fair: return "FFC107"
            case .poor: return "F44336"
            }
        }
        
        var icon: String {
            switch self {
            case .excellent: return "😴"
            case .good: return "🙂"
            case .fair: return "😐"
            case .poor: return "😫"
            }
        }
    }
    
    enum SleepStage: String, Codable {
        case awake = "清醒"
        case core = "核心睡眠"
        case deep = "深度睡眠"
        case rem = "快速眼动"
        case unknown = "未知"
        
        var icon: String {
            switch self {
            case .awake: return "👁️"
            case .core: return "😴"
            case .deep: return "💤"
            case .rem: return "✨"
            case .unknown: return "❓"
            }
        }
        
        var color: String {
            switch self {
            case .awake: return "EF5350"
            case .core: return "42A5F5"
            case .deep: return "7E57C2"
            case .rem: return "FFA726"
            case .unknown: return "9E9E9E"
            }
        }
    }
    
    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
    
    var startTimeFormatted: String {
        startDate.formatted(.dateTime.hour().minute())
    }
    
    var endTimeFormatted: String {
        endDate.formatted(.dateTime.hour().minute())
    }
}

// MARK: - HealthKit 服务

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var sleepRecords: [SleepRecord] = []
    @Published var errorMessage: String?
    @Published var lastSyncDate: Date?
    
    private let healthStore = HKHealthStore()
    private var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    private init() {}
    
    // MARK: - 授权
    
    /// 请求 HealthKit 授权
    func requestAuthorization() async throws -> Bool {
        guard isHealthKitAvailable else {
            errorMessage = "此设备不支持 HealthKit"
            return false
        }
        
        // 定义需要读取的数据类型
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .sleepDuration)!,
            HKObjectType.quantityType(forIdentifier: .timeInBed)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            errorMessage = nil
            return true
        } catch {
            errorMessage = "授权失败：\(error.localizedDescription)"
            isAuthorized = false
            return false
        }
    }
    
    /// 检查授权状态
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let status = healthStore.authorizationStatus(for: sleepType)
        isAuthorized = (status == .sharingAuthorized)
    }
    
    // MARK: - 数据同步
    
    /// 同步睡眠数据
    func syncSleepData(days: Int = 30) async {
        isLoading = true
        errorMessage = nil
        
        guard isAuthorized else {
            errorMessage = "未授权访问健康数据"
            isLoading = false
            return
        }
        
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
            
            let records = try await fetchSleepSamples(from: startDate, to: endDate)
            sleepRecords = records.sorted { $0.startDate > $1.startDate }
            lastSyncDate = Date()
            
        } catch {
            errorMessage = "同步失败：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 获取睡眠样本
    private func fetchSleepSamples(from startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        try await withCheckedThrowingContinuation { continuation in
            let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
            
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
            
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let records = self.parseSleepSamples(samples)
                continuation.resume(returning: records)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// 解析睡眠样本
    private func parseSleepSamples(_ samples: [HKCategorySample]) -> [SleepRecord] {
        // 按日期分组样本
        var groupedSamples: [Date: [HKCategorySample]] = [:]
        
        for sample in samples {
            let day = Calendar.current.startOfDay(for: sample.startDate)
            if groupedSamples[day] == nil {
                groupedSamples[day] = []
            }
            groupedSamples[day]?.append(sample)
        }
        
        // 为每组创建睡眠记录
        var records: [SleepRecord] = []
        
        for (day, daySamples) in groupedSamples {
            guard let firstSample = daySamples.first,
                  let lastSample = daySamples.last else { continue }
            
            let startDate = firstSample.startDate
            let endDate = lastSample.endDate
            let duration = endDate.timeIntervalSince(startDate)
            
            // 分析睡眠阶段
            let stages = analyzeSleepStages(daySamples)
            
            // 计算睡眠质量
            let quality = calculateSleepQuality(stages: stages, duration: duration)
            
            let record = SleepRecord(
                startDate: startDate,
                endDate: endDate,
                duration: duration,
                quality: quality,
                source: firstSample.sourceRevision.source.name,
                stages: stages
            )
            
            records.append(record)
        }
        
        return records
    }
    
    /// 分析睡眠阶段
    private func analyzeSleepStages(_ samples: [HKCategorySample]) -> [SleepRecord.SleepStage] {
        var stages: [SleepRecord.SleepStage] = []
        
        for sample in samples {
            let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
            switch value {
            case .asleepUnspecified, .asleepCore:
                stages.append(.core)
            case .asleepDeep:
                stages.append(.deep)
            case .asleepREM:
                stages.append(.rem)
            case .awake:
                stages.append(.awake)
            default:
                stages.append(.unknown)
            }
        }
        
        return stages
    }
    
    /// 计算睡眠质量
    private func calculateSleepQuality(stages: [SleepRecord.SleepStage], duration: TimeInterval) -> SleepRecord.SleepQuality {
        // 基于睡眠时长和阶段分布计算质量
        let hours = duration / 3600
        
        // 计算各阶段占比
        let totalStages = Double(stages.count)
        let deepSleepRatio = Double(stages.filter { $0 == .deep }.count) / totalStages
        let remSleepRatio = Double(stages.filter { $0 == .rem }.count) / totalStages
        let awakeRatio = Double(stages.filter { $0 == .awake }.count) / totalStages
        
        // 评分逻辑
        var score = 0.0
        
        // 时长评分 (7-9 小时最佳)
        if hours >= 7 && hours <= 9 {
            score += 40
        } else if hours >= 6 && hours < 7 || hours > 9 && hours <= 10 {
            score += 30
        } else {
            score += 20
        }
        
        // 深度睡眠评分 (理想 15-25%)
        if deepSleepRatio >= 0.15 && deepSleepRatio <= 0.25 {
            score += 30
        } else if deepSleepRatio >= 0.1 {
            score += 20
        }
        
        // REM 睡眠评分 (理想 20-25%)
        if remSleepRatio >= 0.20 && remSleepRatio <= 0.25 {
            score += 20
        } else if remSleepRatio >= 0.15 {
            score += 15
        }
        
        // 清醒时间评分 (越少越好)
        if awakeRatio <= 0.05 {
            score += 10
        } else if awakeRatio <= 0.10 {
            score += 5
        }
        
        // 转换为质量等级
        if score >= 85 {
            return .excellent
        } else if score >= 70 {
            return .good
        } else if score >= 50 {
            return .fair
        } else {
            return .poor
        }
    }
    
    // MARK: - 梦境关联
    
    /// 查找与梦境关联的睡眠记录
    func findSleepRecord(for dream: Dream) -> SleepRecord? {
        // 查找梦境日期前一晚的睡眠记录
        let dreamDay = Calendar.current.startOfDay(for: dream.date)
        let previousNight = Calendar.current.date(byAdding: .day, value: -1, to: dreamDay)!
        
        return sleepRecords.first { record in
            let recordDay = Calendar.current.startOfDay(for: record.startDate)
            return recordDay == previousNight
        }
    }
    
    /// 获取睡眠质量统计
    func getSleepQualityStats() -> (averageHours: Double, excellentCount: Int, goodCount: Int) {
        guard !sleepRecords.isEmpty else {
            return (0, 0, 0)
        }
        
        let totalHours = sleepRecords.reduce(0) { $0 + $1.duration } / 3600
        let averageHours = totalHours / Double(sleepRecords.count)
        
        let excellentCount = sleepRecords.filter { $0.quality == .excellent }.count
        let goodCount = sleepRecords.filter { $0.quality == .good || $0.quality == .excellent }.count
        
        return (averageHours, excellentCount, goodCount)
    }
    
    // MARK: - 数据导出
    
    /// 导出睡眠数据
    func exportSleepData() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(sleepRecords)
        } catch {
            print("❌ 导出睡眠数据失败：\(error)")
            return nil
        }
    }
}

// MARK: - 扩展

extension SleepRecord.SleepQuality {
    var uiColor: UIColor {
        UIColor(hex: color)
    }
}

extension SleepRecord.SleepStage {
    var uiColor: UIColor {
        UIColor(hex: color)
    }
}
