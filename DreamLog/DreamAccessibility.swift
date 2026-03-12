//
//  DreamAccessibility.swift
//  DreamLog - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Accessibility Service

/// 无障碍服务 - 提供全面的无障碍支持
@MainActor
class DreamAccessibilityService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 是否启用高对比度模式
    @Published var isHighContrastMode: Bool = false
    
    /// 是否启用减少透明度
    @Published var reduceTransparency: Bool = false
    
    /// 是否启用粗体文本
    @Published var isBoldTextEnabled: Bool = false
    
    /// 自定义字体大小倍数
    @Published var customFontScale: CGFloat = 1.0
    
    /// 是否启用语音反馈
    @Published var isVoiceOverEnabled: Bool = false
    
    /// 当前辅助功能状态
    @Published var accessibilityStatus: AccessibilityStatus = .normal
    
    // MARK: - Singleton
    
    static let shared = DreamAccessibilityService()
    
    private init() {
        setupAccessibilityObservers()
    }
    
    // MARK: - Setup
    
    /// 设置无障碍观察者
    private func setupAccessibilityObservers() {
        // 监听 VoiceOver 状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        // 监听对比度设置
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(highContrastStatusChanged),
            name: UIAccessibility.contrastStatusDidChangeNotification,
            object: nil
        )
        
        // 监听字体大小变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dynamicTypeStatusChanged),
            name: UIAccessibility.preferredContentSizeCategoryDidChangeNotification,
            object: nil
        )
        
        updateAccessibilityStatus()
    }
    
    // MARK: - Notifications
    
    @objc private func voiceOverStatusChanged() {
        DispatchQueue.main.async {
            self.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
            self.updateAccessibilityStatus()
        }
    }
    
    @objc private func highContrastStatusChanged() {
        DispatchQueue.main.async {
            self.isHighContrastMode = UIAccessibility.isReduceTransparencyEnabled
            self.updateAccessibilityStatus()
        }
    }
    
    @objc private func dynamicTypeStatusChanged() {
        DispatchQueue.main.async {
            self.updateAccessibilityStatus()
        }
    }
    
    /// 更新无障碍状态
    private func updateAccessibilityStatus() {
        if isVoiceOverEnabled {
            accessibilityStatus = .voiceOver
        } else if isHighContrastMode {
            accessibilityStatus = .highContrast
        } else {
            accessibilityStatus = .normal
        }
    }
    
    // MARK: - Configuration
    
    /// 切换高对比度模式
    func toggleHighContrastMode() {
        isHighContrastMode.toggle()
    }
    
    /// 切换减少透明度
    func toggleReduceTransparency() {
        reduceTransparency.toggle()
    }
    
    /// 切换粗体文本
    func toggleBoldText() {
        isBoldTextEnabled.toggle()
    }
    
    /// 设置自定义字体大小
    func setFontScale(_ scale: CGFloat) {
        customFontScale = max(0.8, min(2.0, scale))
    }
    
    // MARK: - Helper Methods
    
    /// 获取对比度颜色
    func contrastColor(for color: Color) -> Color {
        guard isHighContrastMode else { return color }
        
        // 在高对比度模式下，使用更鲜明的颜色
        switch color {
        case .gray, .secondary:
            return .black
        case .purple:
            return .blue
        case .pink:
            return .red
        default:
            return color.opacity(1.0)
        }
    }
    
    /// 获取背景颜色
    func backgroundColor(for color: Color) -> Color {
        guard isHighContrastMode else { return color }
        
        // 在高对比度模式下，使用纯色背景
        return color.opacity(1.0)
    }
    
    /// 获取字体大小
    func fontSize(_ size: CGFloat) -> CGFloat {
        return size * customFontScale
    }
    
    /// 获取可访问性标签
    func accessibilityLabel(for text: String) -> String {
        guard isVoiceOverEnabled else { return text }
        
        // 为 VoiceOver 优化标签
        return text
            .replacingOccurrences(of: "🌙", with: "月亮")
            .replacingOccurrences(of: "✨", with: "闪烁")
            .replacingOccurrences(of: "🎤", with: "麦克风")
            .replacingOccurrences(of: "📊", with: "图表")
    }
}

// MARK: - Accessibility Status

/// 无障碍状态
enum AccessibilityStatus {
    case normal
    case voiceOver
    case highContrast
    case custom
    
    var description: String {
        switch self {
        case .normal: return "标准模式"
        case .voiceOver: return "VoiceOver 模式"
        case .highContrast: return "高对比度模式"
        case .custom: return "自定义模式"
        }
    }
}

// MARK: - Accessibility Modifiers

extension View {
    /// 应用无障碍优化
    func dreamAccessibility(
        label: String? = nil,
        hint: String? = nil,
        traits: UIAccessibility.Traits = .none
    ) -> some View {
        self
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// 应用动态字体大小
    func dreamFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        let scale = DreamAccessibilityService.shared.customFontScale
        return self.font(.system(size: size * scale, weight: weight))
    }
    
    /// 应用高对比度颜色
    func dreamContrastColor() -> some View {
        self.foregroundStyle(
            DreamAccessibilityService.shared.isHighContrastMode ? Color.black : Color.primary
        )
    }
}

// MARK: - High Contrast Color Scheme

/// 高对比度配色方案
struct HighContrastColorScheme {
    
    static let shared = HighContrastColorScheme()
    
    // 主色调
    var primary: Color { .blue }
    var secondary: Color { .gray }
    
    // 背景色
    var background: Color { .white }
    var secondaryBackground: Color { .gray.opacity(0.2) }
    
    // 文本色
    var primaryText: Color { .black }
    var secondaryText: Color { .gray }
    
    // 强调色
    var accent: Color { .blue }
    var error: Color { .red }
    var success: Color { .green }
    var warning: Color { .orange }
    
    // 边框色
    var border: Color { .black.opacity(0.3) }
    
    /// 获取颜色 (根据无障碍设置调整)
    func color(for type: ColorType) -> Color {
        guard DreamAccessibilityService.shared.isHighContrastMode else {
            return defaultColor(for: type)
        }
        
        switch type {
        case .primary: return .blue
        case .secondary: return .gray
        case .background: return .white
        case .secondaryBackground: return .gray.opacity(0.3)
        case .primaryText: return .black
        case .secondaryText: return .black.opacity(0.7)
        case .accent: return .blue
        case .error: return .red
        case .success: return .green
        case .warning: return .orange
        case .border: return .black
        }
    }
    
    private func defaultColor(for type: ColorType) -> Color {
        switch type {
        case .primary: return primary
        case .secondary: return secondary
        case .background: return background
        case .secondaryBackground: return secondaryBackground
        case .primaryText: return primaryText
        case .secondaryText: return secondaryText
        case .accent: return accent
        case .error: return error
        case .success: return success
        case .warning: return warning
        case .border: return border
        }
    }
}

enum ColorType {
    case primary, secondary
    case background, secondaryBackground
    case primaryText, secondaryText
    case accent, error, success, warning
    case border
}

// MARK: - Accessibility Settings View

/// 无障碍设置界面
struct AccessibilitySettingsView: View {
    @ObservedObject var accessibilityService = DreamAccessibilityService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("显示与亮度")) {
                    Toggle("高对比度模式", isOn: $accessibilityService.isHighContrastMode)
                        .accessibilityLabel("高对比度模式")
                        .accessibilityHint("启用后使用更鲜明的颜色和对比度")
                    
                    Toggle("减少透明度", isOn: $accessibilityService.reduceTransparency)
                        .accessibilityLabel("减少透明度")
                        .accessibilityHint("减少界面透明效果")
                }
                
                Section(header: Text("文本与字体")) {
                    Toggle("粗体文本", isOn: $accessibilityService.isBoldTextEnabled)
                        .accessibilityLabel("粗体文本")
                        .accessibilityHint("使用更粗的字体显示文本")
                    
                    VStack(alignment: .leading) {
                        Text("字体大小：\(Int(accessibilityService.customFontScale * 100))%")
                            .font(.subheadline)
                        
                        Slider(value: $accessibilityService.customFontScale, in: 0.8...2.0, step: 0.1)
                            .accessibilityLabel("字体大小调节")
                            .accessibilityValue("\(Int(accessibilityService.customFontScale * 100))%")
                    }
                    
                    HStack {
                        Text("示例文本")
                            .font(.system(size: 16 * accessibilityService.customFontScale))
                        Spacer()
                    }
                    .previewLayout(.sizeThatFits)
                }
                
                Section(header: Text("VoiceOver")) {
                    HStack {
                        Text("VoiceOver 状态")
                        Spacer()
                        Text(accessibilityService.isVoiceOverEnabled ? "已启用" : "未启用")
                            .foregroundColor(.gray)
                    }
                    
                    if accessibilityService.isVoiceOverEnabled {
                        Text("VoiceOver 已开启，界面元素已优化为语音反馈")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Section(header: Text("当前状态")) {
                    HStack {
                        Text("无障碍模式")
                        Spacer()
                        Text(accessibilityService.accessibilityStatus.description)
                            .foregroundColor(.purple)
                    }
                }
                
                Section(header: Text("系统设置")) {
                    Button("打开系统无障碍设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("无障碍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Accessible Components

/// 可访问性按钮
struct AccessibleButton: View {
    let label: String
    let hint: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(.isButton)
    }
}

/// 可访问性卡片
struct AccessibleCard<Content: View>: View {
    let label: String
    let hint: String?
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// 动态字体 - 标题
    static func dreamTitle() -> Font {
        .system(.title, design: .default)
    }
    
    /// 动态字体 - 副标题
    static func dreamHeadline() -> Font {
        .system(.headline, design: .default)
    }
    
    /// 动态字体 - 正文
    static func dreamBody() -> Font {
        .system(.body, design: .default)
    }
    
    /// 动态字体 - 说明
    static func dreamCaption() -> Font {
        .system(.caption, design: .default)
    }
}

// MARK: - Accessibility Identifiers

/// 无障碍标识符 - 用于 UI 测试
enum AccessibilityIdentifiers {
    // 主界面
    static let homeView = "home_view"
    static let recordButton = "record_button"
    static let insightsButton = "insights_button"
    static let galleryButton = "gallery_button"
    
    // 记录界面
    static let recordInput = "record_input"
    static let submitButton = "submit_button"
    static let cancelButton = "cancel_button"
    
    // 洞察界面
    static let statsChart = "stats_chart"
    static let trendGraph = "trend_graph"
    
    // 设置界面
    static let settingsView = "settings_view"
    static let accessibilitySettings = "accessibility_settings"
    
    // AR 界面
    static let arView = "ar_view"
    static let arCaptureButton = "ar_capture_button"
    static let arRecordButton = "ar_record_button"
}
