//
//  DreamArtCardGenerator.swift
//  DreamLog
//
//  Phase 54 - AI 梦境艺术分享卡片
//  卡片渲染引擎
//

import Foundation
import SwiftUI
import UIKit
import CoreGraphics
import CoreImage

/// 艺术卡片生成器
class DreamArtCardGenerator {
    
    // MARK: - 属性
    
    private let ciContext = CIContext(options: nil)
    
    // MARK: - 渲染卡片
    
    func renderCard(
        dream: Dream,
        template: ArtCardTemplate,
        enhancedText: AITextEnhancement,
        config: CardGenerationConfig
    ) async throws -> RenderResult {
        
        // 获取平台优化配置
        let platformOpt: PlatformOptimization
        if let platform = config.platform {
            platformOpt = PlatformOptimization.default(for: platform)
        } else {
            platformOpt = PlatformOptimization.default(for: "general")
        }
        
        // 创建图片渲染器
        let renderer = UIGraphicsImageRenderer(
            size: platformOpt.resolution,
            format: UIGraphicsImageRendererFormat()
        )
        
        // 渲染图片
        let image = renderer.image { context in
            // 绘制背景
            drawBackground(
                context: context,
                config: template.background,
                size: platformOpt.resolution
            )
            
            // 绘制装饰元素
            drawDecorations(
                context: context,
                decorations: template.decorations,
                size: platformOpt.resolution
            )
            
            // 绘制文字内容
            drawTextContent(
                context: context,
                dream: dream,
                enhancedText: enhancedText,
                config: config,
                textConfig: template.textConfig,
                size: platformOpt.resolution,
                safeArea: platformOpt.safeArea
            )
            
            // 绘制水印
            if config.showWatermark {
                drawWatermark(
                    context: context,
                    size: platformOpt.resolution
                )
            }
        }
        
        // 生成缩略图
        let thumbnail = createThumbnail(from: image, size: CGSize(width: 300, height: 300))
        
        // 保存图片
        let imagePath = try saveImage(image, format: platformOpt.format, quality: platformOpt.quality)
        let thumbnailPath = try saveImage(thumbnail, format: .jpg, quality: 0.8)
        
        // 获取文件大小
        let fileSize = try getFileSize(at: imagePath)
        
        return RenderResult(
            success: true,
            imagePath: imagePath,
            imageData: nil,
            thumbnailPath: thumbnailPath,
            dimensions: platformOpt.resolution,
            fileSize: fileSize
        )
    }
    
    // MARK: - 绘制背景
    
    private func drawBackground(context: UIGraphicsImageRendererContext, config: BackgroundConfig, size: CGSize) {
        let cgContext = context.cgContext
        
        // 创建渐变
        guard let colorSpace = CGColorSpaceCreateGenericRGB(),
              let gradient = createGradient(from: config.colors, colorSpace: colorSpace) else {
            // Fallback: 纯色背景
            UIColor.systemBackground.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            return
        }
        
        // 绘制渐变
        let startPoint = getGradientStartPoint(for: config.gradientType, size: size)
        let endPoint = getGradientEndPoint(for: config.gradientType, size: size)
        
        cgContext.clip(to: CGRect(origin: .zero, size: size))
        gradient.draw(in: cgContext, start: startPoint, end: endPoint)
        
        // 应用模糊
        if config.blurRadius > 0 {
            applyBlur(context: context, radius: config.blurRadius, size: size)
        }
        
        // 应用噪点
        if config.noiseIntensity > 0 {
            applyNoise(context: context, intensity: config.noiseIntensity, size: size)
        }
    }
    
    private func createGradient(from colorNames: [String], colorSpace: CGColorSpace) -> CGGradient? {
        var colors: [CGColor] = []
        
        for name in colorNames {
            if let color = getColorFromName(name) {
                colors.append(color.cgColor)
            }
        }
        
        if colors.isEmpty {
            colors = [UIColor.systemBackground.cgColor]
        }
        
        // Create CGGradient directly from CGColor array
        guard let colorArray = colors as CFArray? else { return nil }
        let locations = stride(from: 0.0, to: 1.0, by: 1.0 / Double(max(colors.count - 1, 1))).map { CGFloat($0) } as CFArray
        return CGGradient(colorsSpace: colorSpace, colors: colorArray, locations: locations)
    }
    
    private func getColorFromName(_ name: String) -> UIColor? {
        // 尝试从 Asset Catalog 获取颜色
        if let color = UIColor(named: name) {
            return color
        }
        
        // Fallback: 常见颜色名称
        let colorMap: [String: UIColor] = [
            "white": .white,
            "black": .black,
            "red": .red,
            "blue": .blue,
            "green": .green,
            "yellow": .yellow,
            "orange": .orange,
            "purple": .purple,
            "pink": .systemPink,
            "gray": .gray,
            "clear": .clear,
            "deepPurple": UIColor(red: 0.2, green: 0.1, blue: 0.4, alpha: 1.0),
            "midnightBlue": UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 1.0),
            "indigo": UIColor(red: 0.29, green: 0.0, blue: 0.51, alpha: 1.0),
            "turquoise": UIColor(red: 0.25, green: 0.88, blue: 0.82, alpha: 1.0),
            "forestGreen": UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0),
            "lightPink": UIColor(red: 1.0, green: 0.71, blue: 0.76, alpha: 1.0),
            "lavender": UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1.0),
            "lightPurple": UIColor(red: 0.8, green: 0.6, blue: 0.9, alpha: 1.0),
            "hotPink": UIColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1.0),
            "cyan": UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0),
            "magenta": UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0),
            "gold": UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
            "darkRed": UIColor(red: 0.55, green: 0.0, blue: 0.0, alpha: 1.0),
            "emerald": UIColor(red: 0.31, green: 0.78, blue: 0.47, alpha: 1.0),
            "lime": UIColor(red: 0.75, green: 0.91, blue: 0.0, alpha: 1.0),
            "ricePaper": UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0),
            "inkBlack": UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0),
            "cinnabar": UIColor(red: 0.87, green: 0.2, blue: 0.2, alpha: 1.0),
            "lightGray": .lightGray,
            "deepBlue": UIColor(red: 0.0, green: 0.2, blue: 0.5, alpha: 1.0)
        ]
        
        return colorMap[name.lowercased()] ?? UIColor.black
    }
    
    private func getGradientStartPoint(for gradientType: String, size: CGSize) -> CGPoint {
        switch gradientType {
        case "vertical": return CGPoint(x: size.width / 2, y: 0)
        case "horizontal": return CGPoint(x: 0, y: size.height / 2)
        case "radial": return CGPoint(x: size.width / 2, y: size.height / 2)
        case "diagonal": return CGPoint(x: 0, y: 0)
        default: return CGPoint(x: 0, y: 0)
        }
    }
    
    private func getGradientEndPoint(for gradientType: String, size: CGSize) -> CGPoint {
        switch gradientType {
        case "vertical": return CGPoint(x: size.width / 2, y: size.height)
        case "horizontal": return CGPoint(x: size.width, y: size.height / 2)
        case "radial": return CGPoint(x: size.width / 2, y: size.height / 2)
        case "diagonal": return CGPoint(x: size.width, y: size.height)
        default: return CGPoint(x: size.width, y: size.height)
        }
    }
    
    private func applyBlur(context: UIGraphicsImageRendererContext, radius: CGFloat, size: CGSize) {
        guard let cgImage = context.cgContext.makeImage(),
              let ciImage = CIImage(cgImage: cgImage) else { return }
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        context.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
    }
    
    private func applyNoise(context: UIGraphicsImageRendererContext, intensity: Double, size: CGSize) {
        // 简化实现：绘制半透明噪点层
        let noiseColor = UIColor(white: 0.5, alpha: CGFloat(intensity * 0.1))
        noiseColor.setFill()
        
        for _ in 0..<1000 {
            let x = CGFloat.random(in: 0..<size.width)
            let y = CGFloat.random(in: 0..<size.height)
            let rect = CGRect(x: x, y: y, width: 1, height: 1)
            context.cgContext.fill(rect)
        }
    }
    
    // MARK: - 绘制装饰元素
    
    private func drawDecorations(context: UIGraphicsImageRendererContext, decorations: [DecorationConfig], size: CGSize) {
        for config in decorations {
            drawDecoration(context: context, config: config, size: size)
        }
    }
    
    private func drawDecoration(context: UIGraphicsImageRendererContext, config: DecorationConfig, size: CGSize) {
        let decorationType = DecorationType(rawValue: config.type) ?? .stars
        
        for i in 0..<config.count {
            let x = CGFloat.random(in: 0..<size.width)
            let y = CGFloat.random(in: 0..<size.height)
            let rotation = CGFloat.random(in: 0..<360)
            
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: x, y: y)
            context.cgContext.rotate(by: rotation * .pi / 180)
            context.cgContext.setAlpha(config.opacity)
            
            drawDecorationType(context: context.cgContext, type: decorationType, size: config.size)
            
            context.cgContext.restoreGState()
        }
    }
    
    private func drawDecorationType(context: CGContext, type: DecorationType, size: CGFloat) {
        switch type {
        case .stars:
            drawStar(context: context, size: size)
        case .petals:
            drawPetal(context: context, size: size)
        case .leaves:
            drawLeaf(context: context, size: size)
        case .dots:
            drawDot(context: context, size: size)
        default:
            drawSimpleShape(context: context, type: type, size: size)
        }
    }
    
    private func drawStar(context: CGContext, size: CGFloat) {
        let path = UIBezierPath()
        let outerRadius = size / 2
        let innerRadius = size / 4
        
        for i in 0..<5 {
            let angle = CGFloat(i) * 4 * .pi / 5 - .pi / 2
            let x = cos(angle) * outerRadius
            let y = sin(angle) * outerRadius
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            let innerAngle = angle + 2 * .pi / 10
            let innerX = cos(innerAngle) * innerRadius
            let innerY = sin(innerAngle) * innerRadius
            path.addLine(to: CGPoint(x: innerX, y: innerY))
        }
        
        path.close()
        UIColor.white.setFill()
        path.fill()
    }
    
    private func drawPetal(context: CGContext, size: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -size / 2))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: size / 2),
            controlPoint: CGPoint(x: size / 4, y: 0)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: -size / 2),
            controlPoint: CGPoint(x: -size / 4, y: 0)
        )
        path.close()
        
        UIColor.systemPink.setFill()
        path.fill()
    }
    
    private func drawLeaf(context: CGContext, size: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -size / 2))
        path.addQuadCurve(
            to: CGPoint(x: size / 3, y: 0),
            controlPoint: CGPoint(x: size / 4, y: -size / 4)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: size / 2),
            controlPoint: CGPoint(x: size / 4, y: size / 4)
        )
        path.addQuadCurve(
            to: CGPoint(x: -size / 3, y: 0),
            controlPoint: CGPoint(x: -size / 4, y: size / 4)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: -size / 2),
            controlPoint: CGPoint(x: -size / 4, y: -size / 4)
        )
        path.close()
        
        UIColor.systemGreen.setFill()
        path.fill()
    }
    
    private func drawDot(context: CGContext, size: CGFloat) {
        let path = UIBezierPath(ovalIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size))
        UIColor.white.setFill()
        path.fill()
    }
    
    private func drawSimpleShape(context: CGContext, type: DecorationType, size: CGFloat) {
        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        UIColor.white.setFill()
        context.fill(rect)
    }
    
    // MARK: - 绘制文字内容
    
    private func drawTextContent(
        context: UIGraphicsImageRendererContext,
        dream: Dream,
        enhancedText: AITextEnhancement,
        config: CardGenerationConfig,
        textConfig: TextConfig,
        size: CGSize,
        safeArea: EdgeInsets
    ) {
        let cgContext = context.cgContext
        
        // 计算文字区域
        let textRect = CGRect(
            x: safeArea.leading,
            y: safeArea.top,
            width: size.width - safeArea.leading - safeArea.trailing,
            height: size.height - safeArea.top - safeArea.bottom
        )
        
        // 绘制标题
        if !dream.title.isEmpty {
            let titleFont = UIFont.systemFont(ofSize: textConfig.fontSize * 1.3, weight: .bold)
            let titleColor = getColorFromName(textConfig.textColor) ?? .white
            let titleShadow = getColorFromName(textConfig.shadowColor) ?? .black
            
            drawText(
                context: cgContext,
                text: dream.title,
                font: titleFont,
                color: titleColor,
                shadowColor: titleShadow,
                shadowRadius: textConfig.shadowRadius,
                rect: textRect,
                alignment: textConfig.alignment
            )
        }
        
        // 绘制内容
        let contentFont = UIFont.systemFont(ofSize: textConfig.fontSize)
        let contentColor = getColorFromName(textConfig.textColor) ?? .white
        let contentShadow = getColorFromName(textConfig.shadowColor) ?? .black
        
        let contentRect = CGRect(
            x: textRect.minX,
            y: textRect.minY + 40,
            width: textRect.width,
            height: textRect.height - 40
        )
        
        drawText(
            context: cgContext,
            text: enhancedText.enhancedText,
            font: contentFont,
            color: contentColor,
            shadowColor: contentShadow,
            shadowRadius: textConfig.shadowRadius,
            rect: contentRect,
            alignment: textConfig.alignment,
            lineHeight: textConfig.lineHeight
        )
        
        // 绘制标签和情绪
        var footerY = contentRect.maxY + 20
        
        if config.includeTags && !dream.tags.isEmpty {
            drawTags(context: cgContext, tags: dream.tags, y: &footerY, width: textRect.width)
        }
        
        if config.includeEmotions && !dream.emotions.isEmpty {
            drawEmotions(context: cgContext, emotions: dream.emotions, y: &footerY, width: textRect.width)
        }
        
        if config.includeDate {
            drawDate(context: cgContext, date: dream.createdAt, y: &footerY, width: textRect.width)
        }
    }
    
    private func drawText(
        context: CGContext,
        text: String,
        font: UIFont,
        color: UIColor,
        shadowColor: UIColor,
        shadowRadius: CGFloat,
        rect: CGRect,
        alignment: NSTextAlignment,
        lineHeight: CGFloat = 1.5
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineHeightMultiple = lineHeight
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            .shadow: NSShadow.shadowWith(color: shadowColor, blurRadius: shadowRadius)
        ]
        
        // Use NSString for drawing text in CGContext
        let nsString = text as NSString
        nsString.draw(in: rect, withAttributes: attributes)
    }
    
    private func drawTags(context: CGContext, tags: [String], y: inout CGFloat, width: CGFloat) {
        let tagFont = UIFont.systemFont(ofSize: 12)
        let tagColor = UIColor.white.withAlphaComponent(0.8)
        
        var x: CGFloat = 0
        let tagSpacing: CGFloat = 8
        let tagPadding: CGFloat = 6
        
        for tag in tags.prefix(5) {
            let tagText = "#\(tag)"
            let tagSize = tagText.size(withAttributes: [.font: tagFont])
            let tagRect = CGRect(x: x, y: y, width: tagSize.width + tagPadding * 2, height: tagSize.height + tagPadding)
            
            // 绘制标签背景
            let tagBackground = UIColor.white.withAlphaComponent(0.2)
            tagBackground.setFill()
            UIBezierPath(roundedRect: tagRect, cornerRadius: 4).fill()
            
            // 绘制标签文字 (use NSString for drawing)
            let textRect = CGRect(x: x + tagPadding, y: y + tagPadding, width: tagSize.width, height: tagSize.height)
            (tagText as NSString).draw(in: textRect, withAttributes: [.font: tagFont, .foregroundColor: tagColor])
            
            x += tagSize.width + tagPadding * 2 + tagSpacing
        }
        
        y += 30
    }
    
    private func drawEmotions(context: CGContext, emotions: [String], y: inout CGFloat, width: CGFloat) {
        let emotionFont = UIFont.systemFont(ofSize: 14)
        let emotionColor = UIColor.white.withAlphaComponent(0.9)
        
        let emotionIcons = emotions.prefix(3).map { emotion -> String in
            switch emotion {
            case "平静": return "😌"
            case "快乐": return "😊"
            case "悲伤": return "😢"
            case "恐惧": return "😱"
            case "惊讶": return "😲"
            case "兴奋": return "🤩"
            case "困惑": return "🤔"
            case "愤怒": return "😠"
            default: return "✨"
            }
        }.joined(separator: " ")
        
        let emotionRect = CGRect(x: 0, y: y, width: width, height: 20)
        (emotionIcons as NSString).draw(in: emotionRect, withAttributes: [.font: emotionFont, .foregroundColor: emotionColor])
        
        y += 25
    }
    
    private func drawDate(context: CGContext, date: Date, y: inout CGFloat, width: CGFloat) {
        let dateFont = UIFont.systemFont(ofSize: 12)
        let dateColor = UIColor.white.withAlphaComponent(0.6)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let dateRect = CGRect(x: 0, y: y, width: width, height: 20)
        (dateString as NSString).draw(in: dateRect, withAttributes: [.font: dateFont, .foregroundColor: dateColor])
        
        y += 25
    }
    
    // MARK: - 绘制水印
    
    private func drawWatermark(context: UIGraphicsImageRendererContext, size: CGSize) {
        let watermarkFont = UIFont.systemFont(ofSize: 10, weight: .light)
        let watermarkColor = UIColor.white.withAlphaComponent(0.5)
        let watermarkText = "DreamLog"
        
        let textSize = watermarkText.size(withAttributes: [.font: watermarkFont])
        let textRect = CGRect(
            x: size.width - textSize.width - 10,
            y: size.height - textSize.height - 10,
            width: textSize.width,
            height: textSize.height
        )
        
        (watermarkText as NSString).draw(in: textRect, withAttributes: [.font: watermarkFont, .foregroundColor: watermarkColor])
    }
    
    // MARK: - 辅助方法
    
    private func createThumbnail(from image: UIImage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func saveImage(_ image: UIImage, format: ImageFormat, quality: Double) throws -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let artCardsPath = documentsPath.appendingPathComponent("ArtCards")
        
        try? FileManager.default.createDirectory(at: artCardsPath, withIntermediateDirectories: true)
        
        let filename = "art_card_\(UUID().uuidString).\(format.rawValue)"
        let filePath = artCardsPath.appendingPathComponent(filename)
        
        guard let data = imageToData(image, format: format, quality: quality) else {
            throw NSError(domain: "DreamArtCard", code: 1, userInfo: [NSLocalizedDescriptionKey: "图片转换失败"])
        }
        
        try data.write(to: filePath)
        return filePath.path
    }
    
    private func imageToData(_ image: UIImage, format: ImageFormat, quality: Double) -> Data? {
        switch format {
        case .png:
            return image.pngData()
        case .jpg, .heic:
            return image.jpegData(compressionQuality: CGFloat(quality))
        }
    }
    
    private func getFileSize(at path: String) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        return attributes[.size] as? Int ?? 0
    }
}

// MARK: - 渲染结果

extension DreamArtCardGenerator {
    struct RenderResult {
        var success: Bool
        var imagePath: String
        var imageData: Data?
        var thumbnailPath: String
        var dimensions: CGSize
        var fileSize: Int
        var errorMessage: String?
        
        static var empty: RenderResult {
            RenderResult(
                success: false,
                imagePath: "",
                imageData: nil,
                thumbnailPath: "",
                dimensions: .zero,
                fileSize: 0,
                errorMessage: nil
            )
        }
    }
}

// MARK: - NSShadow 扩展

extension NSShadow {
    static func shadowWith(color: UIColor, blurRadius: CGFloat) -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = color
        shadow.shadowBlurRadius = blurRadius
        shadow.shadowOffset = CGSize(width: 1, height: 1)
        return shadow
    }
}
