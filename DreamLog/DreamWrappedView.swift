//
//  DreamWrappedView.swift
//  DreamLog
//
//  Dream Wrapped - 梦境年度回顾界面
//

import SwiftUI
import UIKit

// MARK: - 主视图

struct DreamWrappedView: View {
    @ObservedObject private var wrappedService = DreamWrappedService.shared
    @EnvironmentObject var dreamStore: DreamStore
    
    @State private var selectedPeriod: WrappedPeriod = .year
    @State private var currentCardIndex: Int = 0
    @State private var isShowingShareSheet: Bool = false
    @State private var shareImage: UIImage?
    
    private var cardTypes: [WrappedCardType] = WrappedCardType.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 时间段选择器
                    periodSelector
                    
                    // 总结卡片
                    if wrappedService.isGenerating {
                        loadingView
                    } else if let wrappedData = wrappedService.currentWrappedData {
                        wrappedCardView(wrappedData)
                    } else {
                        emptyStateView
                    }
                    
                    // 卡片导航
                    if wrappedService.currentWrappedData != nil {
                        cardNavigation
                    }
                    
                    // 操作按钮
                    if wrappedService.currentWrappedData != nil {
                        actionButtons
                    }
                }
            }
            .navigationTitle("梦境回顾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: regenerateWrapped) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                    }
                }
            }
        }
    }
    
    // MARK: - 时间段选择器
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WrappedPeriod.allCases, id: \.self) { period in
                    PeriodButton(
                        period: period,
                        isSelected: selectedPeriod == period
                    ) {
                        selectedPeriod = period
                        regenerateWrapped()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - 加载视图
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("正在生成你的梦境回顾...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("分析梦境数据和模式")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("暂无梦境数据")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("开始记录梦境，生成专属回顾")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: regenerateWrapped) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("生成回顾")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "7B61FF"), Color(hex: "4A90E2")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
        }
    }
    
    // MARK: - 总结卡片视图
    
    @ViewBuilder
    private func wrappedCardView(_ data: DreamWrappedData) -> some View {
        TabView(selection: $currentCardIndex) {
            ForEach(0..<cardTypes.count, id: \.self) { index in
                cardForType(cardTypes[index], data: data)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
    
    @ViewBuilder
    private func cardForType(_ type: WrappedCardType, data: DreamWrappedData) -> some View {
        switch type {
        case .overview:
            OverviewCard(data: data)
        case .emotionJourney:
            EmotionJourneyCard(data: data)
        case .topThemes:
            TopThemesCard(data: data)
        case .lucidDreams:
            LucidDreamsCard(data: data)
        case .dreamStreak:
            DreamStreakCard(data: data)
        case .vividDream:
            VividDreamCard(data: data)
        case .dreamTime:
            DreamTimeCard(data: data)
        case .uniqueStats:
            UniqueStatsCard(data: data)
        case .yearComparison:
            YearComparisonCard(data: data)
        case .shareCard:
            ShareCard(data: data)
        }
    }
    
    // MARK: - 卡片导航
    
    private var cardNavigation: some View {
        HStack(spacing: 20) {
            Button(action: previousCard) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(currentCardIndex == 0)
            
            Spacer()
            
            Button(action: nextCard) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(currentCardIndex == cardTypes.count - 1)
        }
        .padding(.horizontal)
    }
    
    // MARK: - 操作按钮
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: shareWrapped) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "7B61FF"), Color(hex: "4A90E2")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Button(action: saveWrapped) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    // MARK: - 操作方法
    
    private func regenerateWrapped() {
        wrappedService.generateWrapped(for: selectedPeriod, dreams: dreamStore.dreams)
        currentCardIndex = 0
    }
    
    private func previousCard() {
        withAnimation {
            currentCardIndex = max(0, currentCardIndex - 1)
        }
    }
    
    private func nextCard() {
        withAnimation {
            currentCardIndex = min(cardTypes.count - 1, currentCardIndex + 1)
        }
    }
    
    private func shareWrapped() {
        // 生成分享数据
        guard let wrappedData = wrappedService.currentWrappedData else { return }
        
        // 生成分享卡片图片
        let shareItems: [Any]
        
        if let cardImage = WrappedShareCardGenerator.generateStandardShareCard(data: wrappedData) {
            // 同时分享图片和文字
            shareItems = [
                shareText(for: wrappedData),
                cardImage
            ]
        } else {
            // 降级为纯文字分享
            shareItems = [shareText(for: wrappedData)]
        }
        
        // 使用 UIActivityViewController 分享
        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        
        // 获取当前窗口并呈现
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            // 关闭当前键盘
            window.endEditing(true)
            
            // 设置分享视图控制器
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = window.bounds
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func shareText(for wrappedData: DreamWrappedData) -> String {
        """
        🌙 我的\(wrappedData.period.displayName)梦境回顾
        
        📊 记录了 \(wrappedData.totalDreams) 个梦境
        👁️ \(wrappedData.lucidDreamCount) 个清醒梦
        🔥 连续记录 \(wrappedData.dreamStreak) 天
        
        \(wrappedData.shareCardQuote)
        
        来自 DreamLog App
        """
    }
    
    private func saveWrapped() {
        // 导出总结数据为 JSON
        guard let wrappedData = wrappedService.currentWrappedData,
              let jsonData = wrappedService.exportWrappedData() else {
            print("无法导出总结数据")
            return
        }
        
        // 保存到 Documents 目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "DreamWrapped_\(wrappedData.period.rawValue)_\(Date().formatted(.dateTime.year().month().day()))"
        let fileURL = documentsPath.appendingPathComponent("\(fileName).json")
        
        do {
            try jsonData.write(to: fileURL)
            print("总结已保存到：\(fileURL.path)")
        } catch {
            print("保存失败：\(error)")
        }
    }
    
    private func exportShareCardImage() {
        guard let wrappedData = wrappedService.currentWrappedData else { return }
        
        // 导出所有类型的分享卡片
        let exportedURLs = wrappedService.exportAllShareCards(data: wrappedData)
        
        if exportedURLs.isEmpty {
            print("导出卡片图片失败")
            return
        }
        
        print("卡片图片已导出到:")
        for (type, url) in exportedURLs {
            print("  - \(type.displayName): \(url.path)")
        }
    }
}

// MARK: - 时间段按钮

struct PeriodButton: View {
    let period: WrappedPeriod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(period.displayName)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "7B61FF") : Color.white.opacity(0.1))
                )
        }
    }
}

// MARK: - 总览卡片

struct OverviewCard: View {
    let data: DreamWrappedData
    
    var body: some View {
        VStack(spacing: 24) {
            Text(data.period.displayName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 30) {
                StatCard(
                    value: "\(data.totalDreams)",
                    label: "总梦境数",
                    icon: "moon.fill",
                    color: Color(hex: "7B61FF")
                )
                
                StatCard(
                    value: "\(data.lucidDreamCount)",
                    label: "清醒梦",
                    icon: "eye.fill",
                    color: Color(hex: "9D50DD")
                )
                
                StatCard(
                    value: String(format: "%.1f", data.averageClarity),
                    label: "平均清晰度",
                    icon: "star.fill",
                    color: Color(hex: "FFD700")
                )
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            HStack(spacing: 30) {
                StatCard(
                    value: "\(data.dreamStreak)",
                    label: "连续记录",
                    icon: "flame.fill",
                    color: Color(hex: "FF6B35")
                )
                
                StatCard(
                    value: "\(data.longestStreak)",
                    label: "最长连续",
                    icon: "trophy.fill",
                    color: Color(hex: "FFA500")
                )
                
                StatCard(
                    value: String(format: "%.1f", data.averageIntensity),
                    label: "平均强度",
                    icon: "bolt.fill",
                    color: Color(hex: "00B4DB")
                )
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "7B61FF").opacity(0.3), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .padding()
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 80)
    }
}

// MARK: - 情绪之旅卡片

struct EmotionJourneyCard: View {
    let data: DreamWrappedData
    
    var body: some View {
        VStack(spacing: 20) {
            Text("情绪之旅")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(data.topEmotions, id: \.name) { emotion in
                    EmotionBar(emotion: emotion)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
        )
        .padding()
    }
}

struct EmotionBar: View {
    let emotion: DreamWrappedData.EmotionStat
    
    var emotionColor: Color {
        switch emotion.name {
        case "快乐": return Color(hex: "FFD700")
        case "悲伤": return Color(hex: "4A90E2")
        case "恐惧": return Color(hex: "2C3E50")
        case "愤怒": return Color(hex: "E74C3C")
        case "惊讶": return Color(hex: "9B59B6")
        case "平静": return Color(hex: "2ECC71")
        case "焦虑": return Color(hex: "F39C12")
        case "兴奋": return Color(hex: "E91E63")
        default: return Color(hex: "95A5A6")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(emotion.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(emotion.percentage))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(emotionColor)
                        .frame(width: geometry.size.width * CGFloat(emotion.percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - 热门主题卡片

struct TopThemesCard: View {
    let data: DreamWrappedData
    
    var body: some View {
        VStack(spacing: 20) {
            Text("热门主题")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // 使用 Flex 风格的布局 - 用 ScrollView + LazyVGrid 替代
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.topTags, id: \.name) { tag in
                        TagBubble(tag: tag)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
        )
        .padding()
    }
}

struct TagBubble: View {
    let tag: DreamWrappedData.TagStat
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.caption)
            Text(tag.name)
                .font(.subheadline)
            Text("(\(tag.count))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(hex: "2ECC71").opacity(0.3))
        )
    }
}

// MARK: - 清醒梦卡片

struct LucidDreamsCard: View {
    let data: DreamWrappedData
    
    var lucidPercentage: Double {
        guard data.totalDreams > 0 else { return 0 }
        return Double(data.lucidDreamCount) / Double(data.totalDreams) * 100
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("清醒梦探索")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // 环形进度条
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(lucidPercentage / 100))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "9D50DD"), Color(hex: "C77DFF")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(data.lucidDreamCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("清醒梦")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(String(format: "%.1f%%", lucidPercentage))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Text("清醒梦是在梦中意识到自己在做梦的体验")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
        )
        .padding()
    }
}

// MARK: - 连续记录卡片

struct DreamStreakCard: View {
    let data: DreamWrappedData
    
    var body: some View {
        VStack(spacing: 24) {
            Text("连续记录")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 40) {
                StreakCard(
                    value: data.dreamStreak,
                    label: "当前连续",
                    icon: "flame.fill",
                    color: Color(hex: "FF6B35")
                )
                
                StreakCard(
                    value: data.longestStreak,
                    label: "最长连续",
                    icon: "trophy.fill",
                    color: Color(hex: "FFA500")
                )
            }
            
            if data.dreamStreak >= 7 {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(streakMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
        )
        .padding()
    }
    
    private var streakMessage: String {
        if data.dreamStreak >= 30 { return "🏆 月度记录大师！" }
        if data.dreamStreak >= 21 { return "🌟 三周连续成就！" }
        if data.dreamStreak >= 14 { return "✨ 两周坚持者！" }
        if data.dreamStreak >= 7 { return "🔥 一周连续达成！" }
        return ""
    }
}

struct StreakCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - 最清晰的梦卡片

struct VividDreamCard: View {
    let data: DreamWrappedData
    
    var body: some View {
        VStack(spacing: 20) {
            Text("最清晰的梦")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let dream = data.mostVividDream {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(dream.title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(dream.content.prefix(200))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(4)
                    
                    HStack(spacing: 16) {
                        Label("\(dream.clarity)⭐", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Label(dream.timeOfDay.rawValue, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
            } else {
                Text("暂无数据")
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
        )
        .padding()
    }
}

// MARK: - 梦境时间卡片

struct DreamTimeCard: View {
    let data: DreamWrappedData
    
    var body: some View {
        VStack(spacing: 20) {
            Text("梦境时间")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // 时间段分布
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(data.timeOfDayDistribution.sorted { $0.value > $1.value }), id: \.key) { time, count in
                    HStack {
                        Text(time)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(count) 个")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            // 星期分布
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        Text(weekdaySymbol(index))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Rectangle()
                            .fill(barColor(for: index))
                            .frame(width: 30, height: CGFloat(min(60, data.weeklyPattern[index] * 3)))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
        )
        .padding()
    }
    
    private func weekdaySymbol(_ index: Int) -> String {
        ["日", "一", "二", "三", "四", "五", "六"][index]
    }
    
    private func barColor(for index: Int) -> Color {
        if index == 0 || index == 6 {
            return Color(hex: "FFD700")  // 周末金色
        }
        return Color(hex: "4A90E2")  // 工作日蓝色
    }
}

// MARK: - 独特统计卡片

struct UniqueStatsCard: View {
    let data: DreamWrappedData
    
    var body: some View {
        VStack(spacing: 20) {
            Text("独特统计")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(data.uniqueStats, id: \.title) { stat in
                    UniqueStatItem(stat: stat)
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
        )
        .padding()
    }
}

struct UniqueStatItem: View {
    let stat: DreamWrappedData.UniqueStat
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: stat.icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(stat.value)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(stat.title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 年度对比卡片

struct YearComparisonCard: View {
    let data: DreamWrappedData
    @ObservedObject private var wrappedService = DreamWrappedService.shared
    @EnvironmentObject var dreamStore: DreamStore
    
    @State private var comparisonData: YearComparisonData?
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                Text("年度对比")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
            } else if let comparison = comparisonData {
                comparisonContent(comparison)
            } else {
                noDataView
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding()
        .onAppear {
            loadComparisonData()
        }
    }
    
    @ViewBuilder
    private func comparisonContent(_ comparison: YearComparisonData) -> some View {
        VStack(spacing: 20) {
            // 今年数据
            HStack(spacing: 20) {
                YearStatCard(title: "今年", value: "\(comparison.thisYear.totalDreams)", subtitle: "个梦境", color: .white)
                YearStatCard(title: "去年", value: "\(comparison.lastYear.totalDreams)", subtitle: "个梦境", color: .white.opacity(0.7))
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            // 对比洞察
            VStack(alignment: .leading, spacing: 12) {
                Text("📊 年度洞察")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(comparison.insights, id: \.self) { insight in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
            // 变化指标
            HStack(spacing: 16) {
                if comparison.dreamsChange != 0 {
                    ChangeIndicator(value: comparison.dreamsChange, label: "梦境数")
                }
                if comparison.lucidChange != 0 {
                    ChangeIndicator(value: comparison.lucidChange, label: "清醒梦")
                }
                if comparison.clarityChange != 0 {
                    ChangeIndicator(value: comparison.clarityChange, isDouble: true, label: "清晰度")
                }
            }
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))
            
            Text("暂无对比数据")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("需要至少两年的梦境记录才能生成年度对比")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: loadComparisonData) {
                Text("重新加载")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
            }
        }
    }
    
    private func loadComparisonData() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let data = wrappedService.generateYearOverYearComparison(dreams: dreamStore.dreams)
            DispatchQueue.main.async {
                comparisonData = data
                isLoading = false
            }
        }
    }
}

struct YearStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(color.opacity(0.8))
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ChangeIndicator: View {
    let value: Double
    let isDouble: Bool
    let label: String
    
    init(value: Int, label: String) {
        self.value = Double(value)
        self.isDouble = false
        self.label = label
    }
    
    init(value: Double, isDouble: Bool = false, label: String) {
        self.value = value
        self.isDouble = isDouble
        self.label = label
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(value >= 0 ? .green : .red)
                Text(String(format: "%\(value >= 0 ? "+" : "")%.0f", value))
                    .font(.headline)
                    .foregroundColor(value >= 0 ? .green : .red)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 分享卡片

struct ShareCard: View {
    let data: DreamWrappedData
    
    var body: some View {
        VStack(spacing: 24) {
            Text("我的梦境回顾")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(data.shareCardQuote)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding()
            
            HStack(spacing: 30) {
                ShareStatItem(value: "\(data.totalDreams)", label: "梦境")
                ShareStatItem(value: "\(data.lucidDreamCount)", label: "清醒梦")
                ShareStatItem(value: "\(data.dreamStreak)", label: "连续")
            }
            
            Text("DreamLog")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 20)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "667EEA"), Color(hex: "764BA2")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding()
    }
}

struct ShareStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - 辅助视图

/// 简单的流式布局容器 - 使用 ScrollView + FlexLayout 替代方案
struct WrapLayout: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> some View
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                content()
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - 预览

#Preview {
    DreamWrappedView()
        .environmentObject(DreamStore.shared)
}
