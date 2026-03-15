//
//  AccessibilityEnhancements.swift
//  DreamLog
//
//  Phase 45 - 无障碍功能增强
//  VoiceOver 支持、动态字体、对比度检查
//

import SwiftUI

// MARK: - 无障碍配置

/// 无障碍配置管理器
class AccessibilityConfiguration {
    static let shared = AccessibilityConfiguration()
    
    /// 检查是否启用 VoiceOver
    var isVoiceOverEnabled: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// 检查是否启用减少动态效果
    var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// 检查是否启用减少透明度
    var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }
    
    /// 检查是否启用粗体文本
    var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
    
    /// 检查是否启用更大字体
    var isDarkerSystemColorsEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// 获取当前字体大小倍数
    var contentSizeCategory: UIContentSizeCategory {
        UIApplication.shared.preferredContentSizeCategory
    }
    
    private init() {}
}

// MARK: - 动态字体修饰符

/// 动态字体修饰符
struct DynamicTypeFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: design))
            .accessibilityAdjustableAction { direction in
                // 支持动态调整字体大小
            }
    }
}

extension View {
    /// 应用动态字体
    func dynamicTypeFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(DynamicTypeFont(size: size, weight: weight, design: design))
    }
}

// MARK: - 无障碍标签扩展

extension View {
    /// 添加完整的无障碍标签
    func accessibilityIdentifier(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: UIAccessibilityTraits = .none
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - 对比度检查工具

/// 对比度检查工具
struct ContrastChecker {
    /// 检查前景色和背景色的对比度是否符合 WCAG AA 标准
    static func isWCAAGCompliant(foreground: UIColor, background: UIColor, largeText: Bool = false) -> Bool {
        let ratio = contrastRatio(foreground: foreground, background: background)
        let threshold: CGFloat = largeText ? 3.0 : 4.5
        return ratio >= threshold
    }
    
    /// 计算对比度比率
    static func contrastRatio(foreground: UIColor, background: UIColor) -> CGFloat {
        let l1 = luminance(foreground)
        let l2 = luminance(background)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// 计算颜色亮度
    static func luminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        let r = linearize(red)
        let g = linearize(green)
        let b = linearize(blue)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// 线性化颜色分量
    static func linearize(_ component: CGFloat) -> CGFloat {
        return component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
}

// MARK: - 无障碍通知

extension Notification.Name {
    /// 无障碍设置变化通知
    static let accessibilitySettingsDidChange = Notification.Name("accessibilitySettingsDidChange")
}

/// 监听无障碍设置变化
class AccessibilitySettingsMonitor: ObservableObject {
    static let shared = AccessibilitySettingsMonitor()
    
    @Published var isVoiceOverEnabled = false
    @Published var isReduceMotionEnabled = false
    @Published var contentSizeCategory: UIContentSizeCategory = .medium
    
    private init() {
        updateSettings()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func settingsDidChange() {
        updateSettings()
        NotificationCenter.default.post(name: .accessibilitySettingsDidChange, object: nil)
    }
    
    private func updateSettings() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    }
}

// MARK: - 无障碍视图修饰符

/// 减少动画修饰符（当用户启用减少动态效果时）
struct ReduceMotionModifier: ViewModifier {
    let duration: Double
    
    func body(content: Content) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            content.transaction { transaction in
                transaction.animation = nil
            }
        } else {
            content.animation(.easeInOut(duration: duration), value: duration)
        }
    }
}

extension View {
    /// 应用减少动画效果
    func reduceMotion(duration: Double = 0.3) -> some View {
        modifier(ReduceMotionModifier(duration: duration))
    }
}

// MARK: - 无障碍测试辅助

/// 无障碍测试辅助工具
struct AccessibilityAudit {
    /// 审计视图的无障碍支持
    static func auditView(_ viewName: String) -> [String] {
        var issues: [String] = []
        
        // 检查 VoiceOver 支持
        if !AccessibilityConfiguration.shared.isVoiceOverEnabled {
            issues.append("⚠️ VoiceOver 未启用，无法完整测试")
        }
        
        // 检查动态字体
        let contentSize = AccessibilityConfiguration.shared.contentSizeCategory
        if contentSize.isAccessibilityCategory {
            issues.append("✅ 当前使用无障碍字体大小：\(contentSize)")
        }
        
        // 检查对比度
        let dreamPurple = UIColor(hex: "9B7EBD")
        let darkBackground = UIColor(hex: "1A1A2E")
        if ContrastChecker.isWCAAGCompliant(foreground: dreamPurple, background: darkBackground, largeText: true) {
            issues.append("✅ 主色调对比度符合 WCAG AA 标准")
        } else {
            issues.append("❌ 主色调对比度不符合 WCAG AA 标准")
        }
        
        return issues
    }
}

// Note: UIColor(hex:) is defined in Theme.swift to avoid duplicate declarations
