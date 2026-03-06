//
//  DreamShareCard.swift
//  DreamLog
//
//  梦境分享卡片 - 生成精美的分享图片
//

import SwiftUI

// MARK: - 分享卡片样式
enum ShareCardStyle: String, CaseIterable, Identifiable {
    case classic = "经典"
    case minimal = "简约"
    case dreamy = "梦幻"
    case gradient = "渐变"
    
    var id: String { rawValue }
    
    var backgroundColors: [Color] {
        switch self {
        case .classic:
            return [Color(hex: "1A1A2E"), Color(hex: "16213E")]
        case .minimal:
            return [Color(hex: "F5F5F5"), Color(hex: "FFFFFF")]
        case .dreamy:
            return [Color(hex: "6B4E9A"), Color(hex: "9B7EBD"), Color(hex: "C9B1DD")]
        case .gradient:
            return [Color(hex: "FF6B6B"), Color(hex: "6B4E9A"), Color(hex: "4ECDC4")]
        }
    }
    
    var textColor: Color {
        switch self {
        case .minimal:
            return .black
        default:
            return .white
        }
    }
    
    var accentColor: Color {
        switch self {
        case .classic:
            return Color(hex: "FFD700")
        case .minimal:
            return Color(hex: "6B4E9A")
        case .dreamy:
            return Color(hex: "FFD700")
        case .gradient:
            return .white
        }
    }
}

// MARK: - 梦境分享卡片视图
struct DreamShareCard: View {
    let dream: Dream
    let style: ShareCardStyle
    @State private var cardSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            // 背景
            backgroundView
            
            // 内容
            VStack(alignment: .leading, spacing: 16) {
                // 头部
                headerView
                
                Spacer()
                
                // 梦境内容
                contentView
                
                Spacer()
                
                // 底部信息
                footerView
            }
            .padding(24)
        }
        .frame(width: 375, height: 500)
        .background(GeometryReader { geometry in
            Color.clear.onAppear {
                cardSize = geometry.size
            }
        })
    }
    
    // MARK: - 背景
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .classic, .dreamy:
            LinearGradient(
                colors: style.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .minimal:
            LinearGradient(
                colors: style.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
        case .gradient:
            LinearGradient(
                colors: style.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(style.textColor.opacity(0.1), lineWidth: 1)
            )
        }
        
        // 装饰元素
        if style == .dreamy {
            dreamyDecorations
        }
    }
    
    // MARK: - 梦幻装饰
    private var dreamyDecorations: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(style.textColor.opacity(0.05))
                    .frame(width: CGFloat.random(in: 50...150))
                    .position(
                        x: CGFloat.random(in: 0...375),
                        y: CGFloat.random(in: 0...500)
                    )
            }
        }
    }
    
    // MARK: - 头部
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("DreamLog")
                    .font(.caption)
                    .foregroundColor(style.textColor.opacity(0.6))
                
                Text(dream.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(style.textColor)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 日期
            VStack(alignment: .trailing, spacing: 2) {
                Text(dream.date.formatted(.dateTime.month().day()))
                    .font(.caption)
                    .foregroundColor(style.textColor.opacity(0.8))
                Text(dream.timeOfDay.rawValue)
                    .font(.caption2)
                    .foregroundColor(style.textColor.opacity(0.6))
            }
        }
    }
    
    // MARK: - 内容
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 梦境文本
            Text(dream.content)
                .font(.body)
                .foregroundColor(style.textColor.opacity(0.9))
                .lineLimit(6)
                .multilineTextAlignment(.leading)
            
            // 分隔线
            Rectangle()
                .fill(style.textColor.opacity(0.2))
                .frame(height: 1)
            
            // AI 解析摘要
            if let analysis = dream.aiAnalysis {
                let shortAnalysis = String(analysis.prefix(100))
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(style.accentColor)
                    
                    Text(shortAnalysis + "...")
                        .font(.caption)
                        .foregroundColor(style.textColor.opacity(0.7))
                        .lineLimit(2)
                }
            }
        }
    }
    
    // MARK: - 底部
    private var footerView: some View {
        VStack(spacing: 12) {
            // 情绪标签
            if !dream.emotions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(dream.emotions.prefix(3), id: \.rawValue) { emotion in
                        HStack(spacing: 4) {
                            Text(emotion.icon)
                                .font(.caption)
                            Text(emotion.rawValue)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(style.textColor.opacity(0.15))
                        )
                    }
                }
            }
            
            // 标签和评分
            HStack {
                // 清晰度
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(style.accentColor)
                    Text("\(dream.clarity)/5")
                        .font(.caption2)
                        .foregroundColor(style.textColor.opacity(0.7))
                }
                
                Spacer()
                
                // 标签
                if !dream.tags.isEmpty {
                    Text("#\(dream.tags.prefix(2).joined(separator: " #"))")
                        .font(.caption2)
                        .foregroundColor(style.textColor.opacity(0.6))
                }
            }
            
            // 品牌标识
            HStack {
                Spacer()
                Text("🌙 DreamLog")
                    .font(.caption2)
                    .foregroundColor(style.textColor.opacity(0.5))
            }
        }
    }
}

// MARK: - 分享卡片预览视图
struct ShareCardPreview: View {
    let dream: Dream
    @State private var selectedStyle: ShareCardStyle = .dreamy
    
    var body: some View {
        VStack(spacing: 20) {
            // 样式选择器
            Picker("卡片样式", selection: $selectedStyle) {
                ForEach(ShareCardStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // 卡片预览
            DreamShareCard(dream: dream, style: selectedStyle)
                .shadow(radius: 20)
            
            // 说明
            Text("滑动选择喜欢的样式")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - 预览
#Preview {
    ShareCardPreview(dream: Dream(
        title: "海边漫步",
        content: "我梦见自己在海边散步，海浪轻轻拍打着沙滩，阳光温暖地洒在身上，感觉非常平静和自由。",
        originalText: "",
        date: Date(),
        tags: ["水", "海滩", "平静", "自由"],
        emotions: [.calm, .happy],
        clarity: 4,
        intensity: 3,
        aiAnalysis: "水通常象征情绪和潜意识。平静的水面代表你内心平和，情绪稳定。"
    ))
    .environmentObject(DreamStore())
}
