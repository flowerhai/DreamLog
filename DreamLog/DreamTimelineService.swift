//
//  DreamTimelineService.swift
//  DreamLog
//
//  梦境时间轴服务 - 可视化梦境在时间轴上的分布
//  Phase 6 - 个性化体验
//

import Foundation
import SwiftUI

/// 时间轴数据点
struct TimelineDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let dreamCount: Int
    let avgClarity: Double
    let avgIntensity: Double
    let dominantEmotion: Emotion?
    let lucidDreamCount: Int
    let tags: [String]
}

/// 时间轴分组级别
enum TimelineGranularity: String, CaseIterable {
    case day = "天"
    case week = "周"
    case month = "月"
    case year = "年"
    
    var icon: String {
        switch self {
        case .day: return "calendar"
        case .week: return "calendar.badge.week"
        case .month: return "calendar.badge.month"
        case .year: return "calendar.badge.year"
        }
    }
}

/// 时间轴过滤选项
struct TimelineFilter {
    var startDate: Date?
    var endDate: Date?
    var selectedTags: Set<String> = []
    var selectedEmotions: Set<Emotion> = []
    var lucidOnly: Bool = false
    var minClarity: Int = 1
    var granularity: TimelineGranularity = .week
    
    var isActive: Bool {
        startDate != nil || endDate != nil || !selectedTags.isEmpty || 
        !selectedEmotions.isEmpty || lucidOnly || minClarity > 1
    }
}

/// 梦境时间轴服务
class DreamTimelineService {
    static let shared = DreamTimelineService()
    
    private init() {}
    
    // MARK: - 生成时间轴数据
    
    /// 生成时间轴数据点
    /// - Parameters:
    ///   - dreams: 梦境列表
    ///   - filter: 过滤选项
    /// - Returns: 时间轴数据点数组
    func generateTimelineData(
        dreams: [Dream],
        filter: TimelineFilter = TimelineFilter()
    ) -> [TimelineDataPoint] {
        // 应用过滤
        let filteredDreams = applyFilter(dreams: dreams, filter: filter)
        
        guard !filteredDreams.isEmpty else { return [] }
        
        // 确定时间范围
        let dates = filteredDreams.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else {
            return []
        }
        
        // 根据分组级别生成时间区间
        let dateRanges = generateDateRanges(
            from: minDate,
            to: maxDate,
            granularity: filter.granularity
        )
        
        // 为每个区间生成数据点
        return dateRanges.map { range in
            let dreamsInRange = filteredDreams.filter { range.contains($0.date) }
            return createDataPoint(dreams: dreamsInRange, date: range.lowerBound)
        }
    }
    
    // MARK: - 过滤梦境
    
    /// 应用过滤条件
    private func applyFilter(dreams: [Dream], filter: TimelineFilter) -> [Dream] {
        return dreams.filter { dream in
            // 日期范围过滤
            if let startDate = filter.startDate, dream.date < startDate {
                return false
            }
            if let endDate = filter.endDate, dream.date > endDate {
                return false
            }
            
            // 标签过滤
            if !filter.selectedTags.isEmpty {
                let hasMatchingTag = filter.selectedTags.contains { tag in
                    dream.tags.contains { $0.localizedCaseInsensitiveContains(tag) }
                }
                if !hasMatchingTag { return false }
            }
            
            // 情绪过滤
            if !filter.selectedEmotions.isEmpty {
                let hasMatchingEmotion = dream.emotions.contains { filter.selectedEmotions.contains($0) }
                if !hasMatchingEmotion { return false }
            }
            
            // 清醒梦过滤
            if filter.lucidOnly && !dream.isLucid {
                return false
            }
            
            // 清晰度过滤
            if dream.clarity < filter.minClarity {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - 生成日期区间
    
    /// 生成日期区间
    private func generateDateRanges(
        from startDate: Date,
        to endDate: Date,
        granularity: TimelineGranularity
    ) -> [(lowerBound: Date, upperBound: Date)] {
        var ranges: [(Date, Date)] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            let range: (Date, Date)
            
            switch granularity {
            case .day:
                let start = calendar.startOfDay(for: currentDate)
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
                range = (start, end)
                currentDate = end
                
            case .week:
                let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)) ?? currentDate
                let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
                range = (start, end)
                currentDate = end
                
            case .month:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
                let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
                range = (start, end)
                currentDate = end
                
            case .year:
                let start = calendar.date(from: calendar.dateComponents([.year], from: currentDate)) ?? currentDate
                let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start
                range = (start, end)
                currentDate = end
            }
            
            ranges.append(range)
        }
        
        return ranges
    }
    
    // MARK: - 创建数据点
    
    /// 创建时间轴数据点
    private func createDataPoint(dreams: [Dream], date: Date) -> TimelineDataPoint {
        let calendar = Calendar.current
        
        // 计算平均清晰度
        let avgClarity = dreams.isEmpty ? 0 : Double(dreams.map { $0.clarity }.reduce(0, +)) / Double(dreams.count)
        
        // 计算平均强度
        let avgIntensity = dreams.isEmpty ? 0 : Double(dreams.map { $0.intensity }.reduce(0, +)) / Double(dreams.count)
        
        // 统计清醒梦数量
        let lucidCount = dreams.filter { $0.isLucid }.count
        
        // 找出主导情绪
        let emotionCounts: [Emotion: Int] = {
            var counts: [Emotion: Int] = [:]
            for dream in dreams {
                for emotion in dream.emotions {
                    counts[emotion, default: 0] += 1
                }
            }
            return counts
        }()
        
        let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key
        
        // 收集所有标签
        let allTags = Set(dreams.flatMap { $0.tags })
        
        return TimelineDataPoint(
            date: date,
            dreamCount: dreams.count,
            avgClarity: avgClarity,
            avgIntensity: avgIntensity,
            dominantEmotion: dominantEmotion,
            lucidDreamCount: lucidCount,
            tags: Array(allTags).prefix(5).map { String($0) }
        )
    }
    
    // MARK: - 统计信息
    
    /// 获取时间轴统计信息
    func getTimelineStats(dreams: [Dream], filter: TimelineFilter = TimelineFilter()) -> TimelineStats {
        let filteredDreams = applyFilter(dreams: dreams, filter: filter)
        
        guard !filteredDreams.isEmpty else {
            return TimelineStats(
                totalDreams: 0,
                totalLucidDreams: 0,
                avgClarity: 0,
                avgIntensity: 0,
                mostCommonTag: nil,
                mostCommonEmotion: nil,
                dateRange: nil
            )
        }
        
        let totalDreams = filteredDreams.count
        let totalLucidDreams = filteredDreams.filter { $0.isLucid }.count
        
        let avgClarity = Double(filteredDreams.map { $0.clarity }.reduce(0, +)) / Double(totalDreams)
        let avgIntensity = Double(filteredDreams.map { $0.intensity }.reduce(0, +)) / Double(totalDreams)
        
        // 最常见标签
        let tagCounts: [String: Int] = {
            var counts: [String: Int] = [:]
            for dream in filteredDreams {
                for tag in dream.tags {
                    counts[tag, default: 0] += 1
                }
            }
            return counts
        }()
        let mostCommonTag = tagCounts.max(by: { $0.value < $1.value })?.key
        
        // 最常见情绪
        let emotionCounts: [Emotion: Int] = {
            var counts: [Emotion: Int] = [:]
            for dream in filteredDreams {
                for emotion in dream.emotions {
                    counts[emotion, default: 0] += 1
                }
            }
            return counts
        }()
        let mostCommonEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key
        
        // 日期范围
        let dates = filteredDreams.map { $0.date }
        let dateRange = (min: dates.min(), max: dates.max())
        
        return TimelineStats(
            totalDreams: totalDreams,
            totalLucidDreams: totalLucidDreams,
            avgClarity: avgClarity,
            avgIntensity: avgIntensity,
            mostCommonTag: mostCommonTag,
            mostCommonEmotion: mostCommonEmotion,
            dateRange: dateRange
        )
    }
}

/// 时间轴统计信息
struct TimelineStats {
    let totalDreams: Int
    let totalLucidDreams: Int
    let avgClarity: Double
    let avgIntensity: Double
    let mostCommonTag: String?
    let mostCommonEmotion: Emotion?
    let dateRange: (min: Date?, max: Date?)
    
    var lucidDreamPercentage: Double {
        guard totalDreams > 0 else { return 0 }
        return Double(totalLucidDreams) / Double(totalDreams) * 100
    }
}
