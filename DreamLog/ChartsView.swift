//
//  ChartsView.swift
//  DreamLog
//
//  数据统计图表 - 可视化梦境数据分析
//  包含：饼图、柱状图、折线图、热力图
//

import SwiftUI
import UIKit

// MARK: - 主图表视图
struct ChartsView: View {
    @EnvironmentObject var dreamStore: DreamStore
    
    var stats: DreamStatistics {
        dreamStore.getStatistics()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 情绪分布饼图
                EmotionPieChartSection(stats: stats)
                
                // 每周梦境趋势折线图
                WeeklyTrendLineChartSection(stats: stats)
                
                // 时间段分布柱状图
                TimeDistributionBarChartSection(stats: stats)
                
                // 清晰度分布柱状图
                ClarityDistributionBarChartSection(stats: stats)
                
                // 梦境热力图
                DreamHeatMapSection(stats: stats)
                
                // 标签云
                TagCloudSection(stats: stats)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("数据图表 📈")
    }
}

// MARK: - 情绪分布饼图
struct EmotionPieChartSection: View {
    let stats: DreamStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("情绪分布")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(alignment: .top, spacing: 24) {
                // 饼图
                PieChartView(
                    data: stats.topEmotions.map { item in
                        PieChartData(
                            label: item.emotion.rawValue,
                            value: Double(item.count),
                            color: emotionColor(item.emotion)
                        )
                    }
                )
                .frame(width: 180, height: 180)
                
                // 图例
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(stats.topEmotions.prefix(6), id: \.emotion) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(emotionColor(item.emotion))
                                .frame(width: 12, height: 12)
                            
                            Text(item.emotion.rawValue)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Text("\(item.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if stats.totalDreams > 0 {
                Text("基于 \(stats.totalDreams) 个梦境分析")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func emotionColor(_ emotion: Emotion) -> Color {
        switch emotion {
        case .calm: return Color(hex: "6BB6FF")
        case .happy: return Color(hex: "FFD93D")
        case .anxious: return Color(hex: "FF6B6B")
        case .fearful: return Color(hex: "9B59B6")
        case .confused: return Color(hex: "95A5A6")
        case .excited: return Color(hex: "FF9F43")
        case .sad: return Color(hex: "54A0FF")
        case .angry: return Color(hex: "EE5A5A")
        case .surprised: return Color(hex: "FDCB6E")
        case .neutral: return Color(hex: "B2BEC3")
        }
    }
}

// MARK: - 饼图组件
struct PieChartView: View {
    let data: [PieChartData]
    
    var total: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: item.color
                )
            }
            
            // 中心圆 - 显示总数
            VStack(spacing: 4) {
                Text("\(Int(total))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("梦境")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let precedingValues = data.prefix(index).reduce(0) { $0 + $1.value }
        let ratio = precedingValues / total
        return Angle(degrees: ratio * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let precedingValues = data.prefix(index + 1).reduce(0) { $0 + $1.value }
        let ratio = precedingValues / total
        return Angle(degrees: ratio * 360 - 90)
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var color: Color
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

struct PieChartData {
    let label: String
    let value: Double
    let color: Color
}

// MARK: - 每周趋势折线图
struct WeeklyTrendLineChartSection: View {
    @EnvironmentObject var dreamStore: DreamStore
    let stats: DreamStatistics
    
    var weeklyData: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let today = Date()
        var data: [(day: String, count: Int)] = []
        
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            let count = dreamStore.dreams.filter { dream in
                calendar.isDate(dream.date, inSameDayAs: date)
            }.count
            data.append((day: dayName, count: count))
        }
        
        return data
    }
    
    var maxCount: Int {
        weeklyData.map { $0.count }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("近 7 天梦境趋势")
                .font(.headline)
                .foregroundColor(.white)
            
            // 折线图
            LineChartView(
                data: weeklyData.map { Double($0.count) },
                labels: weeklyData.map { $0.day },
                color: Color(hex: "9B7EBD")
            )
            .frame(height: 180)
            
            HStack {
                Text("最高：\(maxCount) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("平均：\(String(format: "%.1f", Double(weeklyData.reduce(0) { $0 + $1.count }) / 7.0)) 个/天")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 折线图组件
struct LineChartView: View {
    let data: [Double]
    let labels: [String]
    let color: Color
    
    var maxValue: Double {
        data.max() ?? 1
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 40
            
            ZStack(alignment: .bottom) {
                // 网格线
                ForEach(0..<5, id: \.self) { i in
                    let y = padding + (height - padding * 2) * CGFloat(i) / 4
                    Line(
                        start: CGPoint(x: padding, y: y),
                        end: CGPoint(x: width - padding, y: y)
                    )
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
                
                // 折线
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = padding + (width - padding * 2) * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let y = height - padding - (height - padding * 2) * (value / max(maxValue, 1))
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 3)
                
                // 数据点
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    let x = padding + (width - padding * 2) * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                    let y = height - padding - (height - padding * 2) * (value / max(maxValue, 1))
                    
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                    
                    // 数值标签
                    Text("\(Int(value))")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .position(x: x, y: y - 15)
                }
                
                // X 轴标签
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .offset(y: 20)
            }
        }
    }
}

struct Line: Shape {
    var start: CGPoint
    var end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

// MARK: - 时间段分布柱状图
struct TimeDistributionBarChartSection: View {
    let stats: DreamStatistics
    
    var maxCount: Int {
        stats.dreamsByTimeOfDay.values.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("做梦时间段分布")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(TimeOfDay.allCases, id: \.self) { time in
                    let count = stats.dreamsByTimeOfDay[time] ?? 0
                    let heightRatio = Double(count) / Double(max(maxCount, 1))
                    
                    VStack(spacing: 8) {
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6B4E9A"), Color(hex: "9B7EBD")],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 40, height: heightRatio * 120)
                            .animation(.easeOut(duration: 0.5), value: heightRatio)
                        
                        Text(time.shortName)
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 清晰度分布柱状图
struct ClarityDistributionBarChartSection: View {
    @EnvironmentObject var dreamStore: DreamStore
    let stats: DreamStatistics
    
    var clarityDistribution: [Int: Int] {
        var distribution: [Int: Int] = [:]
        for dream in dreamStore.dreams {
            distribution[dream.clarity, default: 0] += 1
        }
        return distribution
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("梦境清晰度分布")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(1...5, id: \.self) { clarity in
                    let count = clarityDistribution[clarity] ?? 0
                    let maxCount = clarityDistribution.values.max() ?? 1
                    let heightRatio = Double(count) / Double(max(maxCount, 1))
                    
                    VStack(spacing: 8) {
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(clarityColor(clarity))
                            .frame(width: 40, height: heightRatio * 120)
                            .animation(.easeOut(duration: 0.5), value: heightRatio)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<clarity, id: \.self) { _ in
                                Text("⭐")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func clarityColor(_ clarity: Int) -> Color {
        switch clarity {
        case 1: return Color(hex: "95A5A6")
        case 2: return Color(hex: "54A0FF")
        case 3: return Color(hex: "6BB6FF")
        case 4: return Color(hex: "FFD93D")
        case 5: return Color(hex: "FF9F43")
        default: return Color(hex: "9B7EBD")
        }
    }
}

// MARK: - 梦境热力图
struct DreamHeatMapSection: View {
    let stats: DreamStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("梦境热力图 (近 30 天)")
                .font(.headline)
                .foregroundColor(.white)
            
            DreamHeatMapView(dreams: stats.recentDreams)
                .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 热力图组件
struct DreamHeatMapView: View {
    let dreams: [Dream]
    
    @State private var dateCounts: [Date: Int] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            let calendar = Calendar.current
            let today = Date()
            let cellSize: CGFloat = (geometry.size.width - 60) / 30
            
            HStack(alignment: .top, spacing: 4) {
                // 星期标签
                VStack(spacing: 4) {
                    ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(height: cellSize)
                    }
                }
                
                // 热力图格子
                HStack(spacing: 2) {
                    ForEach(0..<30, id: \.self) { dayOffset in
                        let date = calendar.date(byAdding: .day, value: -(29 - dayOffset), to: today) ?? today
                        let count = dateCounts[date, default: 0]
                        let normalizedCount = min(Double(count) / 5.0, 1.0)
                        
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatColor(intensity: normalizedCount))
                                .frame(width: cellSize, height: cellSize)
                            
                            if dayOffset % 5 == 0 {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            calculateDateCounts()
        }
    }
    
    private func calculateDateCounts() {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        
        for dream in dreams {
            let date = calendar.startOfDay(for: dream.date)
            counts[date, default: 0] += 1
        }
        
        dateCounts = counts
    }
    
    private func heatColor(intensity: Double) -> Color {
        if intensity == 0 {
            return Color.white.opacity(0.05)
        } else if intensity < 0.25 {
            return Color(hex: "6B4E9A").opacity(0.4)
        } else if intensity < 0.5 {
            return Color(hex: "6B4E9A").opacity(0.6)
        } else if intensity < 0.75 {
            return Color(hex: "9B7EBD").opacity(0.8)
        } else {
            return Color(hex: "B89BD6")
        }
    }
}

// MARK: - 标签云
struct TagCloudSection: View {
    let stats: DreamStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("热门标签云")
                .font(.headline)
                .foregroundColor(.white)
            
            TagCloudView(tags: stats.topTags)
                .padding(.vertical, 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 标签云组件
struct TagCloudView: View {
    let tags: [(tag: String, count: Int)]
    
    var maxCount: Int {
        tags.map { $0.count }.max() ?? 1
    }
    
    var body: some View {
        FlowLayout(spacing: 12) {
            ForEach(tags, id: \.tag) { item in
                let sizeRatio = 0.5 + 0.5 * Double(item.count) / Double(max(maxCount, 1))
                
                Text("#\(item.tag)")
                    .font(.system(size: 14 * sizeRatio))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12 * sizeRatio)
                    .padding(.vertical, 6 * sizeRatio)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.2 + 0.3 * sizeRatio))
                    )
            }
        }
    }
}

#Preview {
    ChartsView()
        .environmentObject(DreamStore())
}
