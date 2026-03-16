//
//  DreamPDFExportRenderer.swift
//  DreamLog
//
//  Phase 53 - PDF 导出渲染器
//  创建时间：2026-03-16
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// PDF 渲染器 - 生成精美的 PDF 文档
class DreamPDFExportRenderer {
    
    // MARK: - 配置
    
    struct PDFConfig {
        var pageSize: PageSize = .a4
        var margins: Margins = .standard
        var theme: Theme = .default
        var includeCover: Bool = true
        var includeTOC: Bool = false
        var includeHeader: Bool = true
        var includeFooter: Bool = true
        var embedImages: Bool = true
        var quality: ImageQuality = .high
        
        enum PageSize {
            case a4
            case letter
            case custom(width: CGFloat, height: CGFloat)
            
            var size: CGSize {
                switch self {
                case .a4: return CGSize(width: 595, height: 842)
                case .letter: return CGSize(width: 612, height: 792)
                case .custom(let width, let height): return CGSize(width: width, height: height)
                }
            }
        }
        
        struct Margins {
            var top: CGFloat = 72
            var bottom: CGFloat = 72
            var left: CGFloat = 72
            var right: CGFloat = 72
            
            static var standard: Margins { Margins() }
            static var narrow: Margins { Margins(top: 36, bottom: 36, left: 36, right: 36) }
            static var wide: Margins { Margins(top: 108, bottom: 108, left: 108, right: 108) }
        }
        
        struct Theme {
            var primaryColor: CGColor
            var secondaryColor: CGColor
            var textColor: CGColor
            var backgroundColor: CGColor
            var fontName: String
            var fontSize: CGFloat
            var headingFontSize: CGFloat
            
            static var `default`: Theme {
                Theme(
                    primaryColor: CGColor(srgbRed: 0.4, green: 0.3, blue: 0.8, alpha: 1),
                    secondaryColor: CGColor(srgbRed: 0.6, green: 0.6, blue: 0.6, alpha: 1),
                    textColor: CGColor(srgbRed: 0.1, green: 0.1, blue: 0.1, alpha: 1),
                    backgroundColor: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1),
                    fontName: "PingFangSC-Regular",
                    fontSize: 12,
                    headingFontSize: 18
                )
            }
            
            static var elegant: Theme {
                Theme(
                    primaryColor: CGColor(srgbRed: 0.2, green: 0.2, blue: 0.3, alpha: 1),
                    secondaryColor: CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1),
                    textColor: CGColor(srgbRed: 0.1, green: 0.1, blue: 0.1, alpha: 1),
                    backgroundColor: CGColor(srgbRed: 0.98, green: 0.98, blue: 0.99, alpha: 1),
                    fontName: "Georgia",
                    fontSize: 11,
                    headingFontSize: 16
                )
            }
            
            static var modern: Theme {
                Theme(
                    primaryColor: CGColor(srgbRed: 0, green: 0.5, blue: 1, alpha: 1),
                    secondaryColor: CGColor(srgbRed: 0.7, green: 0.7, blue: 0.7, alpha: 1),
                    textColor: CGColor(srgbRed: 0.2, green: 0.2, blue: 0.2, alpha: 1),
                    backgroundColor: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1),
                    fontName: "Helvetica Neue",
                    fontSize: 12,
                    headingFontSize: 18
                )
            }
        }
        
        enum ImageQuality {
            case low
            case medium
            case high
        }
    }
    
    // MARK: - 属性
    
    private let config: PDFConfig
    
    // MARK: - 初始化
    
    init(config: PDFConfig = .init()) {
        self.config = config
    }
    
    // MARK: - PDF 生成
    
    /// 生成 PDF 数据
    func generatePDF(dreams: [DreamExportData], title: String = "梦境记录") -> Data {
        #if canImport(UIKit)
        return generatePDFWithUIKit(dreams: dreams, title: title)
        #else
        // 在非 iOS 环境中返回 Markdown 作为占位
        return generateMarkdownData(dreams: dreams, title: title)
        #endif
    }
    
    #if canImport(UIKit)
    /// 使用 UIGraphicsPDFRenderer 生成 PDF
    private func generatePDFWithUIKit(dreams: [DreamExportData], title: String) -> Data {
        let pageInfo = UIGraphicsPDFRendererFormat().documentInfo
        pageInfo[UIGraphicsPDFRendererDocumentInfoKey.title] = title
        
        let rendererFormat = UIGraphicsPDFRendererFormat()
        rendererFormat.documentInfo = pageInfo
        rendererFormat.bounds = CGRect(origin: .zero, size: config.pageSize.size)
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: config.pageSize.size), format: rendererFormat)
        
        let data = renderer.pdfData { context in
            var currentPage = 0
            
            // 封面页
            if config.includeCover {
                context.beginPage()
                drawCoverPage(context: context, title: title, dreamCount: dreams.count)
                currentPage += 1
            }
            
            // 目录页
            if config.includeTOC && dreams.count > 1 {
                context.beginPage()
                drawTableOfContents(context: context, dreams: dreams)
                currentPage += 1
            }
            
            // 梦境内容页
            for (index, dream) in dreams.enumerated() {
                context.beginPage()
                drawDreamPage(context: context, dream: dream, index: index + 1, total: dreams.count)
            }
        }
        
        return data
    }
    
    /// 绘制封面页
    private func drawCoverPage(context: UIGraphicsPDFRendererContext, title: String, dreamCount: Int) {
        let bounds = context.format.bounds
        let pageCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // 背景渐变
        let gradientColors = [config.theme.primaryColor, config.theme.backgroundColor]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: [0, 1]) {
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: bounds.height), options: [])
        } else {
            // Fallback to solid color if gradient creation fails
            config.theme.backgroundColor.setFill()
            context.cgContext.fill(bounds)
        }
        
        // 标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: UIColor(white: 1, alpha: 1)
        ]
        let titleSize = title.size(withAttributes: titleAttributes)
        title.draw(at: CGPoint(x: (bounds.width - titleSize.width) / 2, y: pageCenter.y - 100), withAttributes: titleAttributes)
        
        // 副标题
        let subtitle = "共 \(dreamCount) 篇梦境"
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .regular),
            .foregroundColor: UIColor(white: 1, alpha: 0.8)
        ]
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        subtitle.draw(at: CGPoint(x: (bounds.width - subtitleSize.width) / 2, y: pageCenter.y - 50), withAttributes: subtitleAttributes)
        
        // 日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        let dateString = dateFormatter.string(from: Date())
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .light),
            .foregroundColor: UIColor(white: 1, alpha: 0.6)
        ]
        let dateSize = dateString.size(withAttributes: dateAttributes)
        dateString.draw(at: CGPoint(x: (bounds.width - dateSize.width) / 2, y: bounds.height - 100), withAttributes: dateAttributes)
        
        // 装饰元素
        let moonPath = UIBezierPath(arcCenter: CGPoint(x: bounds.width - 80, y: 80), radius: 40, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        moonPath.fill()
        moonPath.stroke()
    }
    
    /// 绘制目录页
    private func drawTableOfContents(context: UIGraphicsPDFRendererContext, dreams: [DreamExportData]) {
        let bounds = context.format.bounds
        let margin = config.margins
        
        // 标题
        let tocTitle = "目录"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: config.theme.headingFontSize, weight: .bold),
            .foregroundColor: UIColor(config.theme.primaryColor)
        ]
        tocTitle.draw(at: CGPoint(x: margin.left, y: margin.top), withAttributes: titleAttributes)
        
        // 梦境列表
        var y = margin.top + 50
        for (index, dream) in dreams.enumerated() {
            let indexStr = "\(index + 1)."
            let indexAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: config.theme.fontSize, weight: .medium),
                .foregroundColor: UIColor(config.theme.secondaryColor)
            ]
            indexStr.draw(at: CGPoint(x: margin.left, y: y), withAttributes: indexAttributes)
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: config.theme.fontSize, weight: .regular),
                .foregroundColor: UIColor(config.theme.textColor)
            ]
            dream.title.draw(at: CGPoint(x: margin.left + 30, y: y), withAttributes: titleAttributes)
            
            y += 25
        }
    }
    
    /// 绘制梦境内容页
    private func drawDreamPage(context: UIGraphicsPDFRendererContext, dream: DreamExportData, index: Int, total: Int) {
        let bounds = context.format.bounds
        let margin = config.margins
        
        // 页眉
        if config.includeHeader {
            drawHeader(context: context, index: index, total: total)
        }
        
        // 内容
        var y = margin.top + (config.includeHeader ? 40 : 0)
        
        // 标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: config.theme.headingFontSize, weight: .bold),
            .foregroundColor: UIColor(config.theme.primaryColor)
        ]
        dream.title.draw(at: CGPoint(x: margin.left, y: y), withAttributes: titleAttributes)
        y += 30
        
        // 日期
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: config.theme.fontSize - 2, weight: .light),
            .foregroundColor: UIColor(config.theme.secondaryColor)
        ]
        dream.date.draw(at: CGPoint(x: margin.left, y: y), withAttributes: dateAttributes)
        y += 30
        
        // 分隔线
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin.left, y: y))
        linePath.addLine(to: CGPoint(x: bounds.width - margin.right, y: y))
        UIColor(config.theme.secondaryColor).withAlphaComponent(0.3).setStroke()
        linePath.lineWidth = 1
        linePath.stroke()
        y += 20
        
        // 内容
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: config.theme.fontSize, weight: .regular),
            .foregroundColor: UIColor(config.theme.textColor),
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 6
                return style
            }()
        ]
        
        let contentRect = CGRect(
            x: margin.left,
            y: y,
            width: bounds.width - margin.left - margin.right,
            height: bounds.height - y - margin.bottom - (config.includeFooter ? 40 : 0)
        )
        dream.content.draw(in: contentRect, withAttributes: contentAttributes)
        
        // 页脚
        if config.includeFooter {
            drawFooter(context: context, index: index, total: total)
        }
    }
    
    /// 绘制页眉
    private func drawHeader(context: UIGraphicsPDFRendererContext, index: Int, total: Int) {
        let bounds = context.format.bounds
        let margin = config.margins
        
        let headerText = "DreamLog - 梦境记录"
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .light),
            .foregroundColor: UIColor(config.theme.secondaryColor)
        ]
        headerText.draw(at: CGPoint(x: margin.left, y: 20), withAttributes: headerAttributes)
        
        let pageText = "\(index) / \(total)"
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .light),
            .foregroundColor: UIColor(config.theme.secondaryColor)
        ]
        let pageSize = pageText.size(withAttributes: pageAttributes)
        pageText.draw(at: CGPoint(x: bounds.width - margin.right - pageSize.width, y: 20), withAttributes: pageAttributes)
    }
    
    /// 绘制页脚
    private func drawFooter(context: UIGraphicsPDFRendererContext, index: Int, total: Int) {
        let bounds = context.format.bounds
        let margin = config.margins
        
        let footerText = "由 DreamLog 生成"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .light),
            .foregroundColor: UIColor(config.theme.secondaryColor).withAlphaComponent(0.5)
        ]
        let footerSize = footerText.size(withAttributes: footerAttributes)
        footerText.draw(at: CGPoint(x: (bounds.width - footerSize.width) / 2, y: bounds.height - 25), withAttributes: footerAttributes)
    }
    #endif
    
    /// 生成 Markdown 数据（非 iOS 环境占位）
    private func generateMarkdownData(dreams: [DreamExportData], title: String) -> Data {
        var markdown = "# \(title)\n\n"
        markdown += "导出日期：\(Date().formatted(.dateTime.year().month().day()))\n"
        markdown += "共 **\(dreams.count)** 篇梦境\n\n"
        markdown += "---\n\n"
        
        for (index, dream) in dreams.enumerated() {
            markdown += "## \(dream.title)\n\n"
            markdown += "**日期**: \(dream.date)\n\n"
            markdown += "\(dream.content)\n\n"
            markdown += "---\n\n"
        }
        
        return markdown.data(using: .utf8) ?? Data()
    }
}

// MARK: - 梦境导出数据

struct DreamExportData {
    var title: String
    var content: String
    var date: String
    var emotions: [String]
    var tags: [String]
    var aiAnalysis: String?
    var isLucid: Bool
    var rating: Int
}

// MARK: - Dream 扩展

extension Dream {
    /// 转换为导出数据
    func toExportData() -> DreamExportData {
        DreamExportData(
            title: title,
            content: content,
            date: date.formatted(.dateTime.year().month().day().hour().minute()),
            emotions: emotions.map { $0.rawValue },
            tags: tags,
            aiAnalysis: aiAnalysis,
            isLucid: isLucid,
            rating: Int(clarity)
        )
    }
}
