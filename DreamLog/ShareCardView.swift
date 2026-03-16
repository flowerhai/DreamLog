//
//  ShareCardView.swift
//  DreamLog
//
//  Phase 25 - Dream Sharing Cards & Social Templates
//  分享卡片渲染视图
//

import SwiftUI

struct ShareCardView: View {
    let dream: Dream
    let config: ShareCardConfig
    let template: CardTemplate
    
    var body: some View {
        ZStack {
            // 背景
            backgroundColor
            
            // 装饰元素
            if template.showDecorations {
                decorationElements
            }
            
            // 内容
            VStack(alignment: .leading, spacing: config.fontSize) {
                Spacer()
                
                // 顶部内容
                topContent
                
                Spacer()
                
                // 梦境内容
                if config.showDreamContent, let content = dream.content.preview(300) {
                    Text(content)
                        .font(.system(size: config.fontSize))
                        .foregroundColor(Color(hex: template.textColor) ?? .white)
                        .lineLimit(6)
                }
                
                Spacer()
                
                // 底部信息
                bottomContent
            }
            .padding(template.padding)
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(template.cornerRadius)
    }
    
    // MARK: - 背景
    
    private var backgroundColor: some View {
        Group {
            if let bgImage = template.backgroundImage {
                Image(bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: template.gradientColors.map { Color(hex: $0) ?? .gray },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - 装饰元素
    
    private var decorationElements: some View {
        ZStack {
            ForEach(template.decorationElements, id: \.self) { element in
                switch element {
                case "stars":
                    StarsDecoration()
                case "moon":
                    MoonDecoration()
                        .position(x: 50, y: 50)
                case "sparkles":
                    SparklesDecoration()
                case "clouds":
                    CloudsDecoration()
                case "sun":
                    SunDecoration()
                        .position(x: UIScreen.main.bounds.width - 50, y: 50)
                case "waves":
                    WavesDecoration()
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 30)
                case "bubbles":
                    BubblesDecoration()
                case "hearts":
                    HeartsDecoration()
                case "brush_strokes":
                    BrushStrokesDecoration()
                case "splashes":
                    SplashesDecoration()
                case "shapes":
                    ShapesDecoration()
                case "lines":
                    LinesDecoration()
                case "border":
                    BorderDecoration(color: Color(hex: template.accentColor) ?? .white)
                case "ornament":
                    OrnamentDecoration()
                case "quote_marks":
                    QuoteMarksDecoration()
                default:
                    EmptyView()
                }
            }
        }
        .opacity(0.3)
    }
    
    // MARK: - 顶部内容
    
    private var topContent: some View {
        VStack(alignment: .leading, spacing: config.fontSize / 2) {
            // 标题
            if config.showDreamTitle {
                Text(dream.title)
                    .font(.system(size: config.fontSize * 1.8, weight: .bold))
                    .foregroundColor(Color(hex: template.textColor) ?? .white)
                    .lineLimit(2)
            }
            
            // 情绪标签
            if config.showEmotions && !dream.emotions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(dream.emotions.prefix(3), id: \.self) { emotion in
                        HStack(spacing: 4) {
                            Text(emotion.icon)
                            Text(emotion.rawValue)
                                .font(.system(size: config.fontSize * 0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: template.accentColor)?.opacity(0.3) ?? Color.white.opacity(0.3))
                        .cornerRadius(12)
                    }
                }
            }
            
            // 标签
            if config.showTags && !dream.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(dream.tags.prefix(5), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: config.fontSize * 0.8))
                            .foregroundColor(Color(hex: template.textColor)?.opacity(0.8) ?? Color.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - 底部内容
    
    private var bottomContent: some View {
        VStack(spacing: config.fontSize / 2) {
            // 自定义语录
            if let quote = config.customQuote {
                Text("\"\(quote)\"")
                    .font(.system(size: config.fontSize * 1.1, weight: .medium))
                    .foregroundColor(Color(hex: template.textColor)?.opacity(0.9) ?? Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
            }
            
            // 清晰度和日期
            HStack {
                if config.showClarity {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("\(dream.clarity)/5")
                    }
                    .font(.system(size: config.fontSize * 0.8))
                }
                
                if config.showDate {
                    Text(dream.date, style: .date)
                        .font(.system(size: config.fontSize * 0.8))
                }
                
                Spacer()
                
                if config.showAILogo {
                    HStack(spacing: 4) {
                        Text("🌙")
                        Text("DreamLog")
                    }
                    .font(.system(size: config.fontSize * 0.8, weight: .medium))
                }
            }
            .foregroundColor(Color(hex: template.textColor)?.opacity(0.7) ?? Color.white.opacity(0.7))
        }
    }
}

// MARK: - 装饰视图

struct StarsDecoration: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<50 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let radius = CGFloat.random(in: 1..<3)
                
                context.fill(
                    Circle().path(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                    with: .color(.white.opacity(Double.random(in: 0.3..<0.8)))
                )
            }
        }
    }
}

struct MoonDecoration: View {
    var body: some View {
        Circle()
            .fill(Color.yellow.opacity(0.8))
            .frame(width: 40, height: 40)
            .shadow(color: .yellow.opacity(0.5), radius: 10)
    }
}

struct SparklesDecoration: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<20 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: y - 8))
                    p.addLine(to: CGPoint(x: x, y: y + 8))
                    p.move(to: CGPoint(x: x - 8, y: y))
                    p.addLine(to: CGPoint(x: x + 8, y: y))
                }
                
                context.stroke(path, with: .color(.white.opacity(0.6)), lineWidth: 2)
            }
        }
    }
}

struct CloudsDecoration: View {
    var body: some View {
        Canvas { context, size in
            for i in 0..<5 {
                let x = CGFloat(i) * size.width / 5 + 30
                let y = CGFloat.random(in: 0..<size.height / 3)
                
                context.fill(
                    Ellipse().path(in: CGRect(x: x - 30, y: y, width: 60, height: 30)),
                    with: .color(.white.opacity(0.3))
                )
            }
        }
    }
}

struct SunDecoration: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.yellow, .orange, .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 40
                )
            )
            .frame(width: 80, height: 80)
    }
}

struct WavesDecoration: View {
    var body: some View {
        Canvas { context, size in
            for i in 0..<3 {
                let y = size.height - CGFloat(i) * 25
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                
                for x in stride(from: 0, to: size.width, by: 20) {
                    path.addQuadCurve(
                        to: CGPoint(x: x + 20, y: y),
                        control: CGPoint(x: x + 10, y: y - 10)
                    )
                }
                
                context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 2)
            }
        }
    }
}

struct BubblesDecoration: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<15 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let radius = CGFloat.random(in: 3..<10)
                
                context.fill(
                    Circle().path(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                    with: .color(.white.opacity(0.3))
                )
            }
        }
    }
}

struct HeartsDecoration: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<10 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                
                let heartPath = Path { p in
                    p.move(to: CGPoint(x: x, y: y - 5))
                    p.addCurve(
                        to: CGPoint(x: x - 5, y: y - 10),
                        control1: CGPoint(x: x - 2, y: y - 7),
                        control2: CGPoint(x: x - 5, y: y - 10)
                    )
                    p.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: x - 10, y: y - 15),
                        control2: CGPoint(x: x - 10, y: y)
                    )
                    p.addCurve(
                        to: CGPoint(x: x + 5, y: y - 10),
                        control1: CGPoint(x: x + 10, y: y),
                        control2: CGPoint(x: x + 10, y: y - 15)
                    )
                    p.addCurve(
                        to: CGPoint(x: x, y: y - 5),
                        control1: CGPoint(x: x + 5, y: y - 10),
                        control2: CGPoint(x: x + 2, y: y - 7)
                    )
                }
                
                context.fill(heartPath, with: .color(.pink.opacity(0.4)))
            }
        }
    }
}

struct BrushStrokesDecoration: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<5 {
                let startX = CGFloat.random(in: 0..<size.width)
                let startY = CGFloat.random(in: 0..<size.height)
                
                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                
                for i in 0..<5 {
                    path.addLine(
                        to: CGPoint(
                            x: startX + CGFloat(i) * 20 + CGFloat.random(in: -10..<10),
                            y: startY + CGFloat(i) * 15 + CGFloat.random(in: -10..<10)
                        )
                    )
                }
                
                context.stroke(path, with: .color(.purple.opacity(0.3)), lineWidth: 3)
            }
        }
    }
}

struct SplashesDecoration: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<8 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                
                for _ in 0..<5 {
                    let offsetX = CGFloat.random(in: -20..<20)
                    let offsetY = CGFloat.random(in: -20..<20)
                    let radius = CGFloat.random(in: 2..<6)
                    
                    context.fill(
                        Circle().path(in: CGRect(x: x + offsetX, y: y + offsetY, width: radius * 2, height: radius * 2)),
                        with: .color(.pink.opacity(0.4))
                    )
                }
            }
        }
    }
}

struct ShapesDecoration: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<10 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let size = CGFloat.random(in: 10..<30)
                
                let rect = CGRect(x: x, y: y, width: size, height: size)
                context.fill(
                    RoundedRectangle(cornerRadius: 5).path(in: rect),
                    with: .color(Color.purple.opacity(0.2))
                )
            }
        }
    }
}

struct LinesDecoration: View {
    var body: some View {
        Canvas { context, size in
            for i in 0..<5 {
                let y = CGFloat(i) * size.height / 5 + 20
                
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 20, y: y))
                        p.addLine(to: CGPoint(x: size.width - 20, y: y))
                    },
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 1
                )
            }
        }
    }
}

struct BorderDecoration: View {
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(color, lineWidth: 3)
            .padding(10)
    }
}

struct OrnamentDecoration: View {
    var body: some View {
        Canvas { context, size in
            let corners: [CGPoint] = [
                CGPoint(x: 20, y: 20),
                CGPoint(x: size.width - 20, y: 20),
                CGPoint(x: 20, y: size.height - 20),
                CGPoint(x: size.width - 20, y: size.height - 20)
            ]
            
            for corner in corners {
                context.fill(
                    Circle().path(in: CGRect(x: corner.x - 5, y: corner.y - 5, width: 10, height: 10)),
                    with: .color(.brown.opacity(0.4))
                )
            }
        }
    }
}

struct QuoteMarksDecoration: View {
    var body: some View {
        Text("❝")
            .font(.system(size: 100))
            .foregroundColor(.gray.opacity(0.2))
            .position(x: 40, y: 60)
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - 预览

#Preview {
    ShareCardView(
        dream: Dream(
            title: "飞翔的梦",
            content: "我梦见自己在天空中自由飞翔，穿过云层，感受着风的轻抚。那种自由的感觉如此真实，仿佛我真的可以摆脱一切束缚...",
            tags: ["飞行", "自由", "天空", "梦想"],
            emotions: [.happy, .excited],
            clarity: 4,
            intensity: 5,
            isLucid: true
        ),
        config: ShareCardConfig(
            cardType: .dreamy,
            platform: .wechat,
            showDreamTitle: true,
            showDreamContent: true,
            showTags: true,
            showEmotions: true,
            showClarity: true,
            showDate: true,
            showAILogo: true
        ),
        template: CardTemplate.templates[2] // dreamy_starry
    )
    .frame(width: 400, height: 400)
}
