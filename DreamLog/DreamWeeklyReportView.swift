//
//  DreamWeeklyReportView.swift
//  DreamLog
//
//  梦境周报查看界面
//  Phase 18 - 梦境周报功能
//

import SwiftUI
import UIKit
import Photos

// MARK: - 周报主视图

struct DreamWeeklyReportView: View {
    @ObservedObject private var service = DreamWeeklyReportService.shared
    @State private var selectedTheme: WeeklyReportCard.ReportCardTheme = .starry
    @State private var showingShareSheet = false
    @State private var showingSettings = false
    @State private var generatedCard: WeeklyReportCard?
    
    var body: some View {
        NavigationView {
            Group {
                if service.isGenerating {
                    loadingView
                } else if let report = service.currentReport {
                    reportView(report)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("梦境周报")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if service.currentReport != nil {
                        Button(action: generateReport) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            WeeklyReportSettingsView()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let card = generatedCard {
                ShareReportView(card: card)
            }
        }
        .onAppear {
            if service.currentReport == nil {
                generateReport()
            }
        }
    }
    
    // MARK: - 加载视图
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在生成周报...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            Text("暂无周报数据")
                .font(.title2)
                .fontWeight(.semibold)
            Text("记录梦境后，每周日自动生成周报")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button(action: generateReport) {
                Label("立即生成", systemImage: "sparkles")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 报告视图
    
    private func reportView(_ report: DreamWeeklyReport) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头部卡片
                headerCard(report)
                
                // 基础统计
                statisticsSection(report)
                
                // 情绪分析
                emotionSection(report)
                
                // 亮点梦境
                highlightsSection(report)
                
                // 智能洞察
                insightsSection(report)
                
                // 主题标签
                tagsSection(report)
                
                // 建议
                suggestionsSection(report)
                
                // 分享按钮
                shareButton(report)
                
                // 历史报告
                historySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 头部卡片
    
    private func headerCard(_ report: DreamWeeklyReport) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("梦境周报")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(formatWeekRange(start: report.weekStartDate, end: report.weekEndDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(report.totalDreams) 个梦")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("本周")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                WeeklyReportStatCard(icon: "eye.fill", value: "\(report.lucidDreams)", label: "清醒梦")
                WeeklyReportStatCard(icon: "star.fill", value: String(format: "%.1f", report.averageClarity), label: "清晰度")
                WeeklyReportStatCard(icon: "flame.fill", value: "\(report.recordingStreak)", label: "连续天数")
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .cornerRadius(16)
        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 统计部分
    
    private func statisticsSection(_ report: DreamWeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 本周统计")
                .font(.headline)
            
            HStack(spacing: 16) {
                WeeklyReportStatCard(
                    icon: "moon.fill",
                    value: "\(report.totalDreams)",
                    label: "总梦境",
                    iconColor: .purple
                )
                
                WeeklyReportStatCard(
                    icon: "eye.fill",
                    value: "\(report.lucidDreams)",
                    label: "清醒梦",
                    iconColor: .blue
                )
                
                WeeklyReportStatCard(
                    icon: "heart.fill",
                    value: String(format: "%.1f", report.averageIntensity),
                    label: "平均强度",
                    iconColor: .red
                )
                
                WeeklyReportStatCard(
                    icon: "star.fill",
                    value: String(format: "%.1f", report.averageClarity),
                    label: "清晰度",
                    iconColor: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 情绪部分
    
    private func emotionSection(_ report: DreamWeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💖 情绪分析")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: report.moodTrend.icon)
                        .foregroundColor(Color(report.moodTrend.color))
                    Text(report.moodTrend.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(report.emotionDistribution.prefix(6)), id: \.key) { emotion, count in
                    EmotionBar(emotion: emotion, count: count, total: report.totalDreams)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 亮点梦境
    
    private func highlightsSection(_ report: DreamWeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⭐ 亮点梦境")
                .font(.headline)
            
            if report.highlightDreams.isEmpty {
                Text("暂无亮点梦境")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(report.highlightDreams) { highlight in
                    HighlightCard(highlight: highlight)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 洞察部分
    
    private func insightsSection(_ report: DreamWeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 智能洞察")
                .font(.headline)
            
            if report.insights.isEmpty {
                Text("继续记录以获取洞察")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(report.insights) { insight in
                    WeeklyReportInsightCard(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 标签部分
    
    private func tagsSection(_ report: DreamWeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏷️ 热门主题")
                .font(.headline)
            
            if report.topTags.isEmpty {
                Text("暂无标签数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(report.topTags) { tag in
                        TagBubble(tag: tag.tag, count: tag.count)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 建议部分
    
    private func suggestionsSection(_ report: DreamWeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📝 个性化建议")
                .font(.headline)
            
            ForEach(report.suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 分享按钮
    
    private func shareButton(_ report: DreamWeeklyReport) -> some View {
        Button(action: {
            generatedCard = WeeklyReportCard(report: report, theme: selectedTheme)
            showingShareSheet = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("分享周报")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - 历史报告
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📚 历史周报")
                .font(.headline)
            
            if service.generatedReports.count <= 1 {
                Text("每周自动生成周报")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(service.generatedReports.dropFirst().prefix(3)) { report in
                    HistoryReportRow(report: report)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 方法
    
    private func generateReport() {
        Task {
            await service.generateCurrentWeekReport()
        }
    }
    
    private func formatWeekRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - 统计卡片

struct WeeklyReportStatCard: View {
    let icon: String
    let value: String
    let label: String
    var iconColor: Color = .white
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - 情绪条

struct EmotionBar: View {
    let emotion: String
    let count: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(emotion)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(count) / max(total, 1), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - 亮点卡片

struct HighlightCard: View {
    let highlight: DreamHighlight
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(highlight.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                Text(highlight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(highlight.reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatDate(highlight.date))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - 洞察卡片

struct WeeklyReportInsightCard: View {
    let insight: ReportInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 40, height: 40)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 标签气泡

struct TagBubble: View {
    let tag: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            Text("(\(count))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.1))
        .foregroundColor(.purple)
        .cornerRadius(16)
    }
}

// MARK: - 历史报告行

struct HistoryReportRow: View {
    let report: DreamWeeklyReport
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatWeekRange(start: report.weekStartDate, end: report.weekEndDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(report.totalDreams) 个梦境 · 清晰度 \(String(format: "%.1f", report.averageClarity))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatWeekRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - 设置视图

struct WeeklyReportSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var service = DreamWeeklyReportService.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("自动生成功能")) {
                    Toggle("启用周报", isOn: $service.config.isEnabled)
                    Toggle("每周自动生成", isOn: $service.config.autoGenerate)
                    
                    if service.config.autoGenerate {
                        Picker("生成日期", selection: $service.config.generateDay) {
                            Text("周日").tag(0)
                            Text("周一").tag(1)
                            Text("周二").tag(2)
                            Text("周三").tag(3)
                            Text("周四").tag(4)
                            Text("周五").tag(5)
                            Text("周六").tag(6)
                        }
                        
                        Picker("生成时间", selection: $service.config.generateHour) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d:00", hour)).tag(hour)
                            }
                        }
                    }
                }
                
                Section(header: Text("报告内容")) {
                    Toggle("包含个性化建议", isOn: $service.config.includeSuggestions)
                    Toggle("包含亮点梦境", isOn: $service.config.includeHighlights)
                }
                
                Section(header: Text("分享设置")) {
                    Toggle("自动生成后提醒", isOn: .init(
                        get: { service.config.isEnabled },
                        set: { service.config.isEnabled = $0 }
                    ))
                }
            }
            .navigationTitle("周报设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 分享视图

struct ShareReportView: View {
    @Environment(\.dismiss) var dismiss
    let card: WeeklyReportCard
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 预览卡片
                ReportCardPreview(card: card)
                    .padding()
                
                // 主题选择
                themeSelector
                
                // 操作按钮
                actionButtons
            }
            .navigationTitle("分享周报")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private var themeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WeeklyReportCard.ReportCardTheme.allCases, id: \.self) { theme in
                    ThemeButton(theme: theme, isSelected: card.theme == theme) {
                        // 主题切换逻辑
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: shareToSocial) {
                Label("分享到社交平台", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: saveToPhotos) {
                Label("保存到相册", systemImage: "photo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    private func shareToSocial() {
        // 生成分享卡片图片
        guard let cardImage = generateShareCardImage() else { return }
        
        // 创建分享项目
        let activityVC = UIActivityViewController(
            activityItems: [cardImage, "我的梦境周报 - DreamLog 🌙"],
            applicationActivities: nil
        )
        
        // 排除不需要的活动类型
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .print
        ]
        
        // 在 iPad 上需要设置 popover 源
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.permittedArrowDirections = []
        }
        
        // 获取当前窗口场景
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        // 寻找最上层的视图控制器
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        topController.present(activityVC, animated: true, completion: nil)
    }
    
    private func saveToPhotos() {
        // 生成分享卡片图片
        guard let cardImage = generateShareCardImage() else {
            showSaveError("无法生成卡片图片")
            return
        }
        
        // 请求相册权限
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                saveImageToPhotos(cardImage)
            case .denied, .restricted:
                showSaveError("需要相册权限才能保存")
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    if newStatus == .authorized || newStatus == .limited {
                        saveImageToPhotos(cardImage)
                    } else {
                        showSaveError("需要相册权限才能保存")
                    }
                }
            @unknown default:
                showSaveError("未知权限状态")
            }
        }
    }
    
    private func generateShareCardImage() -> UIImage? {
        // 创建分享卡片视图
        let shareCard = StandardShareCardView(data: generateShareCardData())
            .frame(width: 1080, height: 1920)
        
        // 渲染为图片
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0 // 高分辨率
        
        if let image = renderer.uiImage {
            return image
        }
        
        return nil
    }
    
    private func generateShareCardData() -> DreamWrappedData {
        // 从当前周报生成分享数据
        guard let report = service.currentReport else {
            return createEmptyShareData()
        }
        
        return DreamWrappedData(
            period: .thisWeek,
            totalDreams: report.totalDreams,
            lucidDreams: report.lucidDreams,
            averageClarity: report.averageClarity,
            consecutiveDays: report.recordingStreak,
            topEmotions: report.emotionDistribution.map { DreamEmotion(name: $0.key, count: $0.value) },
            topTags: report.topTags.map { TagFrequency(tag: $0.tag, count: $0.count) },
            highlightDream: report.highlightDreams.first,
            insights: report.insights.map { $0.title },
            generatedAt: report.generatedAt
        )
    }
    
    private func createEmptyShareData() -> DreamWrappedData {
        DreamWrappedData(
            period: .thisWeek,
            totalDreams: 0,
            lucidDreams: 0,
            averageClarity: 0,
            consecutiveDays: 0,
            topEmotions: [],
            topTags: [],
            highlightDream: nil,
            insights: [],
            generatedAt: Date()
        )
    }
    
    private func saveImageToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // 显示成功提示
        DispatchQueue.main.async {
            showSaveSuccess()
        }
    }
    
    private func showSaveError(_ message: String) {
        DispatchQueue.main.async {
            // 简单的错误提示（实际项目中可使用 Toast 或 Alert）
            print("保存失败：\(message)")
        }
    }
    
    private func showSaveSuccess() {
        // 成功提示（实际项目中可使用 Toast）
        print("✅ 已保存到相册")
    }
}

// MARK: - 主题按钮

struct ThemeButton: View {
    let theme: WeeklyReportCard.ReportCardTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(gradientForTheme(theme))
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 3)
                    )
                Text(theme.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func gradientForTheme(_ theme: WeeklyReportCard.ReportCardTheme) -> LinearGradient {
        switch theme {
        case .starry:
            return LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sunset:
            return LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ocean:
            return LinearGradient(gradient: Gradient(colors: [.blue, .teal]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:
            return LinearGradient(gradient: Gradient(colors: [.green, .teal]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .minimal:
            return LinearGradient(gradient: Gradient(colors: [.gray, .gray.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gradient:
            return LinearGradient(gradient: Gradient(colors: [.pink, .purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - 报告卡片预览

struct ReportCardPreview: View {
    let card: WeeklyReportCard
    
    var body: some View {
        VStack(spacing: 16) {
            // 简化预览
            Text("周报预览")
                .font(.headline)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .cornerRadius(16)
    }
}

// MARK: - 预览

#Preview {
    DreamWeeklyReportView()
}
