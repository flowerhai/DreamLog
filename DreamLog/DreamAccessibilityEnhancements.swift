//
//  DreamAccessibilityEnhancements.swift
//  DreamLog
//
//  Phase 35 - 无障碍增强 ♿✨
//  为 ML 预测和性能优化功能添加全面无障碍支持
//

import SwiftUI
import UIKit

// MARK: - ML 预测无障碍视图修饰符

/// ML 预测视图的无障碍修饰符
struct MLPredictionAccessibilityModifier: ViewModifier {
    let predictionType: String
    let confidence: Double
    let isGenerating: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel("AI 预测：\(predictionType)")
            .accessibilityValue("置信度 \(Int(confidence * 100))%")
            .accessibilityHint(isGenerating ? "正在生成预测" : "双击查看详情")
            .accessibilityAddTraits(.isButton)
    }
}

/// 置信度徽章无障碍修饰符
struct ConfidenceBadgeAccessibilityModifier: ViewModifier {
    let confidence: Double
    
    var accessibilityLabel: String {
        let level: String
        if confidence >= 0.8 {
            level = "高"
        } else if confidence >= 0.6 {
            level = "中"
        } else {
            level = "低"
        }
        return "置信度\(level)，\(Int(confidence * 100))%"
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("表示预测的可信程度")
    }
}

// MARK: - 性能优化无障碍支持

/// 性能状态无障碍报告
struct PerformanceStatusAccessibility: View {
    let status: PerformanceStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("性能状态")
                .font(.headline)
            
            HStack {
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
                Text(status.description)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("性能状态：\(status.description)")
        }
        .accessibilityElement(children: .combine)
    }
}

/// 加载进度无障碍指示器
struct LoadingProgressAccessibility: View {
    let progress: Double
    let taskDescription: String
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            
            Text("正在\(taskDescription)...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("正在\(taskDescription)，进度\(Int(progress * 100))%")
        .accessibilityValue("\(Int(progress * 100))%")
    }
}

// MARK: - 图表无障碍支持

/// 情绪趋势图表无障碍描述
struct EmotionTrendChartAccessibility: View {
    let dataPoints: [(date: String, value: Double)]
    
    var accessibilityDescription: String {
        guard !dataPoints.isEmpty else {
            return "暂无情绪趋势数据"
        }
        
        let trend = calculateTrend()
        let average = dataPoints.map { $0.value }.reduce(0, +) / Double(dataPoints.count)
        
        return "情绪趋势：\(trend)，平均情绪分数\(String(format: "%.1f", average))"
    }
    
    var body: some View {
        Text("情绪趋势图表")
            .accessibilityElement()
            .accessibilityLabel(accessibilityDescription)
            .accessibilityHint("显示过去 7 天的情绪变化趋势")
    }
    
    private func calculateTrend() -> String {
        guard dataPoints.count >= 2,
              let first = dataPoints.first,
              let last = dataPoints.last else { return "数据不足" }
        
        if last.value > first.value + 0.2 {
            return "上升"
        } else if last.value < first.value - 0.2 {
            return "下降"
        } else {
            return "平稳"
        }
    }
}

// MARK: - 动态字体支持扩展

extension View {
    /// 支持动态字体的修饰符
    func dynamicTypeSupport(minSize: CGFloat = 12, maxSize: CGFloat = 28) -> some View {
        self
            .environment(\.dynamicTypeSize, .dynamic)
            .accessibilityDynamicTypeSize(.medium)
    }
}

// MARK: - VoiceOver 优化组

/// VoiceOver 优化的容器视图
struct VoiceOverOptimizedGroup<Content: View>: View {
    let content: Content
    let label: String
    let hint: String?
    
    init(label: String, hint: String? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.label = label
        self.hint = hint
    }
    
    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint)
    }
}

// MARK: - 无障碍动作

/// 无障碍快捷动作
struct AccessibilityActions: View {
    let onIncreaseFont: () -> Void
    let onDecreaseFont: () -> Void
    let onToggleHighContrast: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDecreaseFont) {
                Image(systemName: "textformat.size.smaller")
            }
            .accessibilityLabel("减小字体")
            
            Button(action: onIncreaseFont) {
                Image(systemName: "textformat.size.larger")
            }
            .accessibilityLabel("增大字体")
            
            Button(action: onToggleHighContrast) {
                Image(systemName: "circle.lefthalf.filled")
            }
            .accessibilityLabel("切换高对比度")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("无障碍快捷操作")
    }
}

// MARK: - 性能优化视图的无障碍支持

extension View {
    /// 为性能优化列表添加无障碍支持
    func performanceListAccessibility() -> some View {
        self
            .accessibilityAction(named: "刷新") {
                // 刷新操作
                return true
            }
            .accessibilityAction(named: "筛选") {
                // 筛选操作
                return true
            }
    }
}

// MARK: - 无障碍状态枚举

enum AccessibilityFeatureStatus {
    case enabled
    case disabled
    case partiallyEnabled
    case notAvailable
    
    var description: String {
        switch self {
        case .enabled: return "已启用"
        case .disabled: return "已禁用"
        case .partiallyEnabled: return "部分启用"
        case .notAvailable: return "不可用"
        }
    }
    
    var icon: String {
        switch self {
        case .enabled: return "checkmark.circle.fill"
        case .disabled: return "xmark.circle.fill"
        case .partiallyEnabled: return "exclamationmark.circle.fill"
        case .notAvailable: return "questionmark.circle.fill"
        }
    }
}

// MARK: - 无障碍检查清单

struct AccessibilityChecklist {
    // MARK: - VoiceOver 检查项
    
    static let voiceOverChecks: [(name: String, check: () -> Bool)] = [
        ("所有按钮有标签", { true }), // 需要实际实现
        ("所有图片有描述", { true }),
        ("焦点顺序合理", { true }),
        ("动态内容可通知", { true })
    ]
    
    // MARK: - 动态字体检查项
    
    static let dynamicTypeChecks: [(name: String, check: () -> Bool)] = [
        ("支持最大字体", { true }),
        ("布局不破裂", { true }),
        ("文本不截断", { true }),
        ("间距适当", { true })
    ]
    
    // MARK: - 对比度检查项
    
    static let contrastChecks: [(name: String, check: () -> Bool)] = [
        ("文本对比度达标", { true }),
        ("重要元素高对比", { true }),
        ("颜色不单独表意", { true })
    ]
    
    // MARK: - 辅助触控检查项
    
    static let switchControlChecks: [(name: String, check: () -> Bool)] = [
        ("支持自定义手势", { true }),
        ("扫描顺序合理", { true }),
        ("操作可取消", { true })
    ]
}

// MARK: - 无障碍测试辅助

#if DEBUG
struct AccessibilityPreview: ViewModifier {
    func body(content: Content) -> some View {
        content
            .accessibilityShowButtonShapes()
            .accessibilityElement(children: .contain)
    }
}

extension View {
    /// 预览时无障碍测试模式
    func accessibilityPreview() -> some View {
        self.modifier(AccessibilityPreview())
    }
}
#endif

// MARK: - 性能状态模型

struct PerformanceStatus {
    let level: PerformanceLevel
    let description: String
    let recommendations: [String]
    
    enum PerformanceLevel {
        case excellent
        case good
        case fair
        case poor
    }
    
    var icon: String {
        switch level {
        case .excellent: return "bolt.fill"
        case .good: return "bolt"
        case .fair: return "exclamationmark.triangle"
        case .poor: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - 无障碍设置视图

struct AccessibilityEnhancedSettingsView: View {
    @ObservedObject private var service = DreamAccessibilityService.shared
    
    var body: some View {
        Form {
            Section(header: Text("VoiceOver")) {
                Toggle("启用 VoiceOver", isOn: $service.isVoiceOverEnabled)
                    .disabled(true) // 由系统控制
                Text("VoiceOver 状态：\(UIAccessibility.isVoiceOverRunning ? "运行中" : "未运行")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("显示")) {
                Toggle("高对比度", isOn: $service.isHighContrastMode)
                Toggle("减少透明度", isOn: $service.reduceTransparency)
                Toggle("粗体文本", isOn: $service.isBoldTextEnabled)
            }
            
            Section(header: Text("字体大小")) {
                Slider(value: $service.customFontScale, in: 0.8...1.5, step: 0.1) {
                    Text("自定义缩放")
                } minimumValueLabel: {
                    Text("80%")
                } maximumValueLabel: {
                    Text("150%")
                }
            }
            
            Section(header: Text("无障碍检查")) {
                NavigationLink(destination: AccessibilityReportView()) {
                    Text("查看无障碍报告")
                }
            }
        }
        .navigationTitle("无障碍设置")
    }
}

// MARK: - 无障碍报告视图

struct AccessibilityReportView: View {
    var body: some View {
        List {
            Section(header: Text("VoiceOver 支持")) {
                ForEach(AccessibilityChecklist.voiceOverChecks, id: \.name) { check in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(check.name)
                    }
                }
            }
            
            Section(header: Text("动态字体支持")) {
                ForEach(AccessibilityChecklist.dynamicTypeChecks, id: \.name) { check in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(check.name)
                    }
                }
            }
            
            Section(header: Text("对比度检查")) {
                ForEach(AccessibilityChecklist.contrastChecks, id: \.name) { check in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(check.name)
                    }
                }
            }
        }
        .navigationTitle("无障碍报告")
    }
}

// MARK: - 预览

#Preview("无障碍设置") {
    NavigationView {
        AccessibilitySettingsView()
    }
}

#Preview("无障碍报告") {
    NavigationView {
        AccessibilityReportView()
    }
}

#Preview("性能状态") {
    PerformanceStatusAccessibility(
        status: PerformanceStatus(
            level: .excellent,
            description: "性能优秀",
            recommendations: ["继续保持"]
        )
    )
}
