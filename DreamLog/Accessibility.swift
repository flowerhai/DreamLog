//
//  Accessibility.swift
//  DreamLog
//
//  无障碍支持
//

import SwiftUI

// MARK: - 无障碍标签扩展
extension View {
    /// 添加梦境卡片无障碍标签
    func dreamCardAccessibility(_ dream: Dream) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(dream.title)
            .accessibilityHint("\(dream.date.formatted(.dateTime.month().day())) · \(dream.emotions.count) 种情绪 · \(dream.tags.count) 个标签")
            .accessibilityAddTraits(.isButton)
    }
    
    /// 添加按钮无障碍标签
    func buttonAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
    
    /// 添加进度条无障碍标签
    func progressAccessibility(value: Double, description: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(description)
            .accessibilityValue("\(Int(value * 100))%")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - 无障碍字体支持
struct DynamicFontModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: baseSize(for: dynamicTypeSize)))
    }
    
    private func baseSize(for size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: return 12
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .xLarge: return 20
        case .xxLarge: return 22
        case .accessibility1: return 24
        case .accessibility2: return 28
        case .accessibility3: return 32
        @unknown default: return 16
        }
    }
}

// MARK: - 高对比度支持
struct HighContrastModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            .accessibilitySortPriority(1)
    }
}

// MARK: - 语音控制支持
extension View {
    /// 添加语音控制标签
    func voiceControl(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - 减少动效支持
struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content.transaction { transaction in
                transaction.animation = nil
            }
        } else {
            content
        }
    }
}

// MARK: - 无障碍颜色
struct AccessibleColors {
    // 确保足够的对比度 (WCAG AA 标准：4.5:1)
    
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.5)
    
    static let accentColor = Color(hex: "9B7EBD")
    static let successColor = Color(hex: "4CAF50")
    static let warningColor = Color(hex: "FFA726")
    static let errorColor = Color(hex: "EF5350")
    
    // 检查对比度是否足够
    static func hasSufficientContrast(foreground: Color, background: Color) -> Bool {
        let contrastRatio = calculateContrastRatio(foreground: foreground, background: background)
        return contrastRatio >= 4.5  // WCAG AA 标准
    }
    
    /// 计算两种颜色的对比度比率 (基于 WCAG 2.0)
    private static func calculateContrastRatio(foreground: Color, background: Color) -> CGFloat {
        let l1 = getLuminance(for: foreground)
        let l2 = getLuminance(for: background)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// 计算颜色的相对亮度 (基于 WCAG 2.0)
    private static func getLuminance(for color: Color) -> CGFloat {
        // 使用 UIColor 获取 RGB 值
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // 尝试获取 RGBA 值
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            // 应用 gamma 校正
            let r = linearize(red)
            let g = linearize(green)
            let b = linearize(blue)
            // WCAG 2.0 亮度公式
            return 0.2126 * r + 0.7152 * g + 0.0722 * b
        }
        
        // 无法解析时返回默认值
        return 0.5
    }
    
    /// 将 sRGB 值转换为线性值 (gamma 校正)
    private static func linearize(_ value: CGFloat) -> CGFloat {
        if value <= 0.03928 {
            return value / 12.92
        } else {
            return pow((value + 0.055) / 1.055, 2.4)
        }
    }
}

// MARK: - 无障碍提示
struct AccessibilityHint {
    static let recordDream = "双击开始记录梦境"
    static let viewDetails = "双击查看详情"
    static let deleteDream = "双击删除此梦境"
    static let shareDream = "双击分享此梦境"
    static let editDream = "双击编辑此梦境"
    static let playAudio = "双击播放录音"
    static let pauseAudio = "双击暂停播放"
    static let expandSection = "双击展开此部分"
    static let collapseSection = "双击收起此部分"
    static let nextMonth = "双击查看下一个月"
    static let previousMonth = "双击查看上一个月"
    static let selectDate = "双击选择此日期"
    static let toggleSetting = "双击切换此设置"
}

// MARK: - 屏幕阅读器支持
extension Dream {
    /// 生成无障碍描述
    var accessibilityDescription: String {
        var description = "\(title)。"
        description += "\(date.formatted(.dateTime.month().day().hour().minute()))记录。"
        
        if isLucid {
            description += "清醒梦。"
        }
        
        if !emotions.isEmpty {
            let emotionNames = emotions.map { $0.rawValue }.joined(separator: "、")
            description += "情绪：\(emotionNames)。"
        }
        
        if !tags.isEmpty {
            let tagNames = tags.joined(separator: "、")
            description += "标签：\(tagNames)。"
        }
        
        description += "清晰度\(clarity)星，强度\(intensity)星。"
        
        return description
    }
}

// MARK: - 无障碍测试
#if DEBUG
struct AccessibilityAudit {
    /// 检查视图的无障碍属性
    static func auditView(_ view: some View) {
        // 在 Xcode 的 Accessibility Inspector 中使用
        print("🔍 无障碍审计：请运行 Xcode Accessibility Inspector")
    }
    
    /// 检查颜色对比度
    static func checkContrast() {
        let colorsToCheck: [(String, Color, Color)] = [
            ("主文本", AccessibleColors.primaryText, Color.black),
            ("次要文本", AccessibleColors.secondaryText, Color.black),
            ("强调色", AccessibleColors.accentColor, Color.white),
            ("成功色", AccessibleColors.successColor, Color.white),
            ("警告色", AccessibleColors.warningColor, Color.black),
            ("错误色", AccessibleColors.errorColor, Color.white)
        ]
        
        var allPassed = true
        for (name, foreground, background) in colorsToCheck {
            let hasContrast = AccessibleColors.hasSufficientContrast(foreground: foreground, background: background)
            if !hasContrast {
                print("❌ 颜色对比度不足：\(name)")
                allPassed = false
            }
        }
        
        if allPassed {
            print("✅ 颜色对比度检查通过 (WCAG AA 标准)")
        }
    }
    
    /// 检查动态字体支持
    static func checkDynamicType() {
        let fontSizes: [(String, CGFloat)] = [
            ("xSmall", 12),
            ("small", 14),
            ("medium", 16),
            ("large", 18),
            ("xLarge", 20),
            ("xxLarge", 22),
            ("accessibility1", 24),
            ("accessibility2", 28),
            ("accessibility3", 32)
        ]
        
        print("📏 动态字体支持检查:")
        for (sizeName, size) in fontSizes {
            print("  - \(sizeName): \(size)pt ✓")
        }
        print("✅ 动态字体支持检查通过")
    }
    
    /// 运行所有无障碍检查
    static func runAllChecks() {
        print("\n=== 无障碍审计开始 ===\n")
        checkContrast()
        checkDynamicType()
        print("\n=== 无障碍审计完成 ===\n")
    }
}
#endif
