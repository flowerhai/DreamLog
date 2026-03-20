//
//  DreamLogScreenshotHelper.swift
//  DreamLog
//
//  Created for Phase 38 - App Store 发布准备
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

// MARK: - Screenshot Helper View
// 用于 App Store 截图的辅助视图
// 使用方法：在 Settings 中启用 Screenshot Mode，然后导航到各个页面截图

/// Screenshot 模式配置
struct ScreenshotConfig {
    static let showDeviceFrame = false  // 是否显示设备框架 (后期添加)
    static let hideStatusBar = true     // 隐藏状态栏
    static let useLightMode = true      // 使用浅色模式
    static let fontSize: CGFloat = 17   // 默认字体大小
}

// MARK: - 首页截图视图

/// 首页截图预览 - 展示梦境列表和统计
struct HomeScreenshotView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部统计卡片
            headerStatsSection
            
            Divider()
                .padding(.horizontal)
            
            // 梦境列表
            dreamListSection
        }
        .navigationTitle("DreamLog")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemBackground))
    }
    
    private var headerStatsSection: some View {
        VStack(spacing: 16) {
            // 连续记录卡片
            StreakCard(days: 7, totalDreams: 128)
            
            // 统计网格
            HStack(spacing: 12) {
                ScreenshotStatCard(
                    value: "128",
                    title: "总梦境",
                    icon: "moon.fill",
                    color: .purple
                )
                
                ScreenshotStatCard(
                    value: "23",
                    title: "清醒梦",
                    icon: "star.fill",
                    color: .yellow
                )
                
                ScreenshotStatCard(
                    value: "8.5",
                    title: "平均清晰",
                    icon: "eye.fill",
                    color: .blue
                )
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var dreamListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sampleDreams) { dream in
                    DreamCard(dream: dream)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var sampleDreams: [Dream] {
        [
            Dream(title: "昨晚的奇幻冒险", content: "梦见自己在空中自由飞翔，穿越云层，俯瞰大地", date: Date(), emotions: [.excited], clarity: 9, tags: ["冒险", "飞行", "奇幻"]),
            Dream(title: "深海探险", content: "在深海中探索，周围是发光的海洋生物，宁静而神秘", date: Date().addingTimeInterval(-86400), emotions: [.calm], clarity: 8, tags: ["海洋", "探索", "宁静"]),
            Dream(title: "与故人重逢", content: "梦见了很久未见的朋友，我们一起聊天，感觉很温暖", date: Date().addingTimeInterval(-172800), emotions: [.happy], clarity: 7, tags: ["回忆", "情感", "温暖"]),
            Dream(title: "未来城市", content: "来到了一座未来城市，高科技建筑悬浮在空中，充满科幻感", date: Date().addingTimeInterval(-259200), emotions: [.surprised], clarity: 8, tags: ["科幻", "未来", "城市"]),
        ]
    }
}

// MARK: - AI 解析截图视图

/// AI 解析截图预览 - 展示三层解析结果
struct AIAnalysisScreenshotView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 梦境标题
                dreamHeader
                
                // 三层解析卡片
                analysisLayers
                
                // 智能洞察
                insightsSection
                
                // 个性化建议
                suggestionsSection
            }
            .padding()
        }
        .navigationTitle("AI 梦境解析")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var dreamHeader: some View {
        VStack(spacing: 8) {
            Text("昨晚的奇幻冒险")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Label("2026 年 3 月 14 日", systemImage: "calendar")
                Label("清晰度 9/10", systemImage: "star.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var analysisLayers: some View {
        VStack(spacing: 16) {
            AnalysisLayerCard(
                title: "🧠 表层解析",
                content: "这是一次充满冒险精神的梦境，飞行元素象征着对自由的渴望和突破限制的愿望。",
                color: .blue
            )
            
            AnalysisLayerCard(
                title: "🔮 深层解析",
                content: "反映了你内心对未知领域的好奇心和探索欲。可能预示着生活中即将迎来新的机遇和挑战。",
                color: .purple
            )
            
            AnalysisLayerCard(
                title: "🎭 原型层",
                content: "英雄原型 - 成长之旅。你正在经历个人成长的阶段，勇敢面对挑战并将获得突破。",
                color: .orange
            )
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 智能洞察")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InsightRow(icon: "📈", text: "近期冒险主题梦境增多，创造力处于高峰期")
                InsightRow(icon: "🌙", text: "清晰度持续提升，清醒梦练习效果显著")
                InsightRow(icon: "✨", text: "情绪积极，心理健康状态良好")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📝 个性化建议")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                SuggestionRow(icon: "🎯", text: "尝试记录梦境后的第一个想法")
                SuggestionRow(icon: "🧘", text: "睡前进行 5 分钟冥想，提升梦境质量")
                SuggestionRow(icon: "📖", text: "阅读关于飞行梦境的解析，加深理解")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - AR 可视化截图视图

/// AR 可视化截图预览 - 展示 3D 梦境元素
struct ARVisualizationScreenshotView: View {
    var body: some View {
        ZStack {
            // 模拟 AR 背景
            ARBackgroundView()
            
            // 3D 元素
            ARElementsOverlay()
            
            // 控制按钮
            ControlButtonsOverlay()
        }
        .navigationTitle("AR 梦境世界")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "cube.box.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

struct ARBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.1, blue: 0.4),
                Color(red: 0.3, green: 0.1, blue: 0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            // 星空效果
            Canvas { context, size in
                for _ in 0..<50 {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let radius = CGFloat.random(in: 1..<3)
                    let path = Circle().path(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
                    context.fill(path, with: .color(.white.opacity(Double.random(in: 0.3..<0.8))))
                }
            }
        )
    }
}

struct ARElementsOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            // 漂浮的光点
            ForEach(0..<5) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.yellow, .orange.opacity(0.1)],
                            center: .center,
                            radius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .position(
                        x: CGFloat.random(in: 50..<geometry.size.width - 50),
                        y: CGFloat.random(in: 50..<geometry.size.height - 50)
                    )
                    .blur(radius: 5)
            }
            
            // 水元素
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .cyan.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 80)
                .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.6)
                .blur(radius: 10)
            
            // 蝴蝶
            Image(systemName: "ladybug.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.4)
                .rotationEffect(.degrees(45))
        }
    }
}

struct ControlButtonsOverlay: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                ControlButton(icon: "plus", label: "添加")
                ControlButton(icon: "wand.and.stars", label: "魔法")
                ControlButton(icon: "record.circle", label: "录制", accent: true)
                ControlButton(icon: "square.and.arrow.up", label: "分享")
            }
            .padding()
            .background(
                Color(.systemBackground)
                    .opacity(0.9)
            )
            .cornerRadius(20)
            .padding()
        }
    }
}

struct ControlButton: View {
    let icon: String
    let label: String
    var accent: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(accent ? .white : .accentColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(accent ? Color.accentColor : Color.accentColor.opacity(0.1))
                )
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 分享中心截图视图

/// 分享中心截图预览 - 展示分享配置和统计
struct ShareHubScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 统计卡片
            statsSection
            
            Divider()
            
            // 快速分享
            quickShareSection
            
            Divider()
            
            // 分享配置
            configsSection
        }
        .navigationTitle("分享中心")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ScreenshotStatCard(value: "47", title: "本周分享", icon: "paperplane.fill", color: .blue)
                ScreenshotStatCard(value: "12", title: "本月分享", icon: "calendar", color: .purple)
            }
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("最常用平台：微信朋友圈")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var quickShareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速分享")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    PlatformButton(platform: .wechat) {}
                    PlatformButton(platform: .moments) {}
                    PlatformButton(platform: .weibo) {}
                    PlatformButton(platform: .xiaohongshu) {}
                    PlatformButton(platform: .qq) {}
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private var configsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分享配置")
                .font(.headline)
                .padding(.horizontal)
            
            ConfigCard(
                config: ShareConfig(
                    name: "默认配置",
                    platforms: [.wechat, .moments],
                    template: .starry
                )
            ) {}
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - 组件视图

struct StreakCard: View {
    let days: Int
    let totalDreams: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🔥 \(days) 天连续记录")
                    .font(.headline)
                Text("已记录 \(totalDreams) 个梦境")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text("\(days)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct ScreenshotStatCard: View {
    let value: String
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
    }
}

struct AnalysisLayerCard: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct PlatformButton: View {
    let platform: SharePlatform
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: platform.iconName)
                    .font(.title2)
                    .foregroundColor(platformColor(platform))
                
                Text(platform.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 70)
            .background(platformColor(platform).opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func platformColor(_ platform: SharePlatform) -> Color {
        switch platform {
        case .wechat: return .green
        case .moments: return .green
        case .weibo: return .red
        case .xiaohongshu: return .red
        case .qq: return .blue
        default: return .gray
        }
    }
}

struct ConfigCard: View {
    let config: ShareConfig
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.accentColor)
                    Text(config.name)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    ForEach(config.platforms.prefix(4), id: \.self) { platform in
                        Image(systemName: SharePlatform.iconName(for: platform))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    if config.platforms.count > 4 {
                        Text("+\(config.platforms.count - 4)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label("模板：\(config.template.displayName)", systemImage: "paintbrush")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Label("卡片", systemImage: "card.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct ScreenshotDreamCard: View {
    let dream: Dream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dream.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if let primaryEmotion = dream.emotions.first {
                    Text(primaryEmotion.icon)
                        .font(.system(size: 18))
                }
            }
            
            Text(String(dream.content.prefix(80)) + "...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                ForEach(Array(dream.tags.prefix(3)), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 预览

#Preview("首页截图") {
    NavigationStack {
        HomeScreenshotView()
    }
}

#Preview("AI 解析截图") {
    NavigationStack {
        AIAnalysisScreenshotView()
    }
}

#Preview("AR 可视化截图") {
    NavigationStack {
        ARVisualizationScreenshotView()
    }
}

#Preview("分享中心截图") {
    NavigationStack {
        ShareHubScreenshotView()
    }
}

// MARK: - 统计洞察截图视图

/// 统计洞察截图预览 - 展示数据可视化和智能洞察
struct InsightsDashboardScreenshotView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部统计
                headerStats
                
                // 情绪分布
                moodDistributionSection
                
                // 时间分析
                timeAnalysisSection
                
                // 热门标签
                popularTagsSection
                
                // 智能洞察
                insightsSection
            }
            .padding()
        }
        .navigationTitle("智能洞察")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerStats: some View {
        HStack(spacing: 16) {
            ScreenshotStatCard(value: "128", title: "总梦境", icon: "moon.fill", color: .purple)
            ScreenshotStatCard(value: "23", title: "清醒梦", icon: "star.fill", color: .yellow)
        }
    }
    
    private var moodDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("情绪分布")
                .font(.headline)
            
            HStack(spacing: 12) {
                MoodIndicator(mood: "积极", percentage: 45, color: .green)
                MoodIndicator(mood: "平静", percentage: 30, color: .blue)
                MoodIndicator(mood: "好奇", percentage: 15, color: .purple)
                MoodIndicator(mood: "其他", percentage: 10, color: .gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var timeAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("做梦时段分析")
                .font(.headline)
            
            HStack(spacing: 8) {
                TimeBar(hour: "凌晨", percentage: 15, height: 30)
                TimeBar(hour: "清晨", percentage: 45, height: 80)
                TimeBar(hour: "上午", percentage: 10, height: 20)
                TimeBar(hour: "下午", percentage: 5, height: 15)
                TimeBar(hour: "夜晚", percentage: 25, height: 50)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var popularTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门标签")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                TagBadge(text: "#冒险", count: 23)
                TagBadge(text: "#飞行", count: 18)
                TagBadge(text: "#奇幻", count: 15)
                TagBadge(text: "#海洋", count: 12)
                TagBadge(text: "#回忆", count: 10)
                TagBadge(text: "#未来", count: 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 智能洞察")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InsightRow(icon: "📈", text: "近期冒险主题梦境增多，创造力处于高峰期")
                InsightRow(icon: "🌙", text: "清晰度持续提升，清醒梦练习效果显著")
                InsightRow(icon: "⏰", text: "主要在清晨做梦，建议床头放置记录工具")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 梦境孵育截图视图

/// 梦境孵育截图预览 - 展示孵育类型和模板
struct DreamIncubationScreenshotView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部说明
                headerSection
                
                // 孵育类型
                incubationTypesSection
                
                // 推荐模板
                recommendedTemplatesSection
            }
            .padding()
        }
        .navigationTitle("梦境孵育")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text("设定意图，引导梦境")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("选择一个孵育类型，睡前进行仪式，晨间记录反思")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var incubationTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("孵育类型")
                .font(.headline)
            
            VStack(spacing: 12) {
                IncubationTypeCard(
                    icon: "🧩",
                    title: "问题解答",
                    description: "在梦中寻求问题的答案",
                    duration: "10 分钟",
                    color: .blue
                )
                
                IncubationTypeCard(
                    icon: "💡",
                    title: "创意启发",
                    description: "激发创意灵感和艺术创作",
                    duration: "10 分钟",
                    color: .orange
                )
                
                IncubationTypeCard(
                    icon: "❤️",
                    title: "情感疗愈",
                    description: "处理情感创伤和内心冲突",
                    duration: "15 分钟",
                    color: .pink
                )
            }
        }
    }
    
    private var recommendedTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐模板")
                .font(.headline)
            
            TemplateCard(
                name: "创意突破",
                type: "创意启发",
                steps: 3,
                color: .orange
            )
        }
    }
}

// MARK: - 时间胶囊截图视图

/// 时间胶囊截图预览 - 展示胶囊列表和创建界面
struct TimeCapsuleScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 头部统计
            headerSection
            
            Divider()
            
            // 胶囊列表
            capsulesList
        }
        .navigationTitle("时间胶囊")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                CapsuleStat(icon: "📦", value: "5", label: "已创建")
                CapsuleStat(icon: "🔓", value: "2", label: "已解锁")
                CapsuleStat(icon: "⏳", value: "3", label: "等待中")
            }
            
            Text("给未来的自己发送梦境")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var capsulesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                TimeCapsuleCard(
                    title: "给一年后的自己",
                    dreamCount: 3,
                    unlockDate: Date().addingTimeInterval(31536000),
                    status: "waiting"
                )
                
                TimeCapsuleCard(
                    title: "生日惊喜",
                    dreamCount: 5,
                    unlockDate: Date().addingTimeInterval(-86400),
                    status: "unlocked"
                )
                
                TimeCapsuleCard(
                    title: "百日纪念",
                    dreamCount: 10,
                    unlockDate: Date().addingTimeInterval(86400 * 50),
                    status: "waiting"
                )
            }
            .padding()
        }
    }
}

// MARK: - 梦境社区截图视图

/// 梦境社区截图预览 - 展示社区动态和互动
struct DreamCommunityScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 筛选器
            filterSection
            
            Divider()
            
            // 梦境列表
            communityDreamsList
        }
        .navigationTitle("梦境社区")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ScreenshotFilterChip(text: "🔥 热门", active: true)
                ScreenshotFilterChip(text: "🕐 最新", active: false)
                ScreenshotFilterChip(text: "⭐ Top", active: false)
                ScreenshotFilterChip(text: "👁️ 清醒梦", active: false)
                ScreenshotFilterChip(text: "👥 关注", active: false)
            }
            .padding()
        }
    }
    
    private var communityDreamsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                CommunityDreamCard(
                    author: "匿名梦友",
                    avatar: "🌙",
                    title: "昨晚的奇幻冒险",
                    preview: "我梦见自己在天空中飞翔，穿越云层...",
                    likes: 234,
                    comments: 45,
                    tags: ["冒险", "飞行", "奇幻"]
                )
                
                CommunityDreamCard(
                    author: "匿名梦友",
                    avatar: "🌊",
                    title: "深海探险",
                    preview: "在一片神秘的海洋中，我遇到了会说话的鱼...",
                    likes: 189,
                    comments: 32,
                    tags: ["海洋", "探索", "奇幻"]
                )
                
                CommunityDreamCard(
                    author: "匿名梦友",
                    avatar: "✨",
                    title: "清醒梦体验",
                    preview: "意识到自己在做梦后，我尝试控制梦境...",
                    likes: 456,
                    comments: 78,
                    tags: ["清醒梦", "控制", "体验"]
                )
            }
            .padding()
        }
    }
}

// MARK: - 组件视图

struct MoodIndicator: View {
    let mood: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(percentage)%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.3))
                .frame(height: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 40 * CGFloat(percentage) / 100, height: 4),
                    alignment: .leading
                )
            
            Text(mood)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TimeBar: View {
    let hour: String
    let percentage: Int
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(percentage)%")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .purple],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 40, height: height)
            
            Text(hour)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

struct TagBadge: View {
    let text: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .foregroundColor(.accentColor)
            
            Text("(\(count))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
    }
}

struct IncubationTypeCard: View {
    let icon: String
    let title: String
    let description: String
    let duration: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 40))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(duration)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.1))
                        .foregroundColor(color)
                        .cornerRadius(4)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TemplateCard: View {
    let name: String
    let type: String
    let steps: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text("\(type) · \(steps) 个步骤")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CapsuleStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TimeCapsuleCard: View {
    let title: String
    let dreamCount: Int
    let unlockDate: Date
    let status: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: status == "unlocked" ? "lock.open.fill" : "lock.fill")
                .font(.title2)
                .foregroundColor(status == "unlocked" ? .green : .orange)
                .frame(width: 50, height: 50)
                .background((status == "unlocked" ? Color.green : Color.orange).opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text("\(dreamCount) 个梦境 · 解锁：\(formatDate(unlockDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if status == "unlocked" {
                Text("已解锁")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct ScreenshotFilterChip: View {
    let text: String
    let active: Bool
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(active ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundColor(active ? .white : .primary)
            .cornerRadius(20)
    }
}

struct CommunityDreamCard: View {
    let author: String
    let avatar: String
    let title: String
    let preview: String
    let likes: Int
    let comments: Int
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(avatar)
                    .font(.title)
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(22)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(author)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("2 小时前")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text(preview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 8) {
                ForEach(tags.prefix(3), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 20) {
                Label("\(likes)", systemImage: "heart.fill")
                    .foregroundColor(.red)
                
                Label("\(comments)", systemImage: "message.fill")
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: "share")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Additional Previews

#Preview("统计洞察截图") {
    NavigationStack {
        InsightsDashboardScreenshotView()
    }
}

#Preview("梦境孵育截图") {
    NavigationStack {
        DreamIncubationScreenshotView()
    }
}

#Preview("时间胶囊截图") {
    NavigationStack {
        TimeCapsuleScreenshotView()
    }
}

#Preview("梦境社区截图") {
    NavigationStack {
        DreamCommunityScreenshotView()
    }
}

#Preview("首页截图") {
    NavigationStack {
        HomeScreenshotView()
    }
}

#Preview("AI 解析截图") {
    NavigationStack {
        AIAnalysisScreenshotView()
    }
}

#Preview("AR 可视化截图") {
    NavigationStack {
        ARVisualizationScreenshotView()
    }
}

#Preview("分享中心截图") {
    NavigationStack {
        ShareHubScreenshotView()
    }
}

// MARK: - App Store Screenshot Guide

/*
 ## App Store 截图尺寸要求
 
 ### iPhone 截图 (必须)
 - 6.7" iPhone (1290x2796) - iPhone 14/15 Pro Max
 - 6.5" iPhone (1242x2688) - iPhone 11 Pro Max/XS Max
 - 5.5" iPhone (1242x2208) - iPhone 8 Plus/7 Plus
 
 ### iPad 截图 (可选但推荐)
 - 12.9" iPad Pro (2048x2732)
 - 11" iPad Pro (1668x2388)
 - 10.2" iPad (1620x2160)
 
 ## 推荐截图内容 (5 张)
 
 1. **首页 - 快速记录**
    - 展示语音记录按钮和统计卡片
    - 文案："30 秒记录你的梦境"
    - 使用 HomeScreenshotView
 
 2. **AI 梦境解析**
    - 展示三层解析结果
    - 文案："AI 深度解析梦境含义"
    - 使用 AIAnalysisScreenshotView
 
 3. **数据洞察**
    - 展示情绪图表和趋势分析
    - 文案："发现你的梦境模式"
    - 使用 InsightsDashboardScreenshotView
 
 4. **AR 梦境世界**
    - 展示 3D 梦境元素和交互
    - 文案："让梦境栩栩如生"
    - 使用 ARVisualizationScreenshotView
 
 5. **时间胶囊**
    - 展示时间胶囊列表和解锁进度
    - 文案："给未来的自己发送梦境"
    - 使用 TimeCapsuleScreenshotView
 
 ## 截图技巧
 
 1. 在 Xcode 中运行预览
 2. 使用截图工具 (Cmd+Shift+4)
 3. 裁剪到设备边框
 4. 添加设备框架 (可选)
 5. 上传到 App Store Connect
 
 ## 预览视频脚本 (30 秒)
 
 | 时间 | 画面 | 文案 |
 |------|------|------|
 | 0-3s | 应用图标 + 名称 | "DreamLog - 你的 AI 梦境日记" |
 | 3-8s | 语音记录梦境 | "按住说话，30 秒记录梦境" |
 | 8-13s | AI 解析动画 | "AI 深度解析，发现隐藏含义" |
 | 13-18s | 数据图表展示 | "智能洞察，追踪梦境模式" |
 | 18-23s | AR 梦境可视化 | "AR 技术，让梦境可视化" |
 | 23-27s | 特色功能快速切换 | "时间胶囊、清醒梦、冥想音效..." |
 | 27-30s | App Store 下载按钮 | "立即下载，探索潜意识世界" |
 */
