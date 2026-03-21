//
//  DreamHapticFeedback.swift
//  DreamLog
//
//  触觉反馈增强服务 - Phase 30 用户体验优化
//  为所有交互添加细腻的触觉反馈
//

import UIKit
import Combine

/// 触觉反馈类型枚举
enum DreamHapticType {
    // MARK: - 基础反馈
    
    /// 轻击反馈（按钮点击等）
    case lightImpact
    
    /// 中等反馈（重要操作）
    case mediumImpact
    
    /// 重击反馈（重要确认）
    case heavyImpact
    
    /// 柔软反馈（轻柔操作）
    case softImpact
    
    /// 刚性反馈（确定操作）
    case rigidImpact
    
    // MARK: - 成功/错误反馈
    
    /// 成功反馈
    case success
    
    /// 错误反馈
    case error
    
    /// 警告反馈
    case warning
    
    // MARK: - 选择反馈
    
    /// 选择反馈（Picker、SegmentedControl）
    case selection
    
    // MARK: - 特殊场景反馈
    
    /// 录音开始
    case recordingStart
    
    /// 录音结束
    case recordingEnd
    
    /// 录音进行中（脉冲）
    case recordingPulse
    
    /// 列表滚动到位
    case listScrollEnd
    
    /// 刷新完成
    case refreshComplete
    
    /// 加载完成
    case loadComplete
    
    /// 切换开关
    case toggleSwitch
    
    /// 滑块调整
    case sliderAdjustment
    
    /// 长按触发
    case longPress
    
    /// 双击触发
    case doubleTap
    
    /// 拖拽开始
    case dragStart
    
    /// 拖拽结束
    case dragEnd
    
    /// 页面切换
    case pageTurn
    
    /// 模态框弹出
    case modalPresent
    
    /// 模态框关闭
    case modalDismiss
    
    /// 手风琴展开
    case accordionExpand
    
    /// 手风琴折叠
    case accordionCollapse
    
    /// 星星评分
    case starRating
    
    /// 进度完成
    case progressComplete
    
    /// 解锁成就
    case unlockAchievement
    
    /// 收集物品
    case collectItem
    
    /// 发送消息
    case sendMessage
    
    /// 收到消息
    case receiveMessage
    
    /// 相机快门
    case cameraShutter
    
    /// 生物识别成功
    case biometricSuccess
    
    /// 生物识别失败
    case biometricFailure
}

/// 触觉反馈服务
@MainActor
class DreamHapticFeedbackService: ObservableObject {
    static let shared = DreamHapticFeedbackService()
    
    // 反馈生成器
    private var impactFeedbackLight: UIImpactFeedbackGenerator?
    private var impactFeedbackMedium: UIImpactFeedbackGenerator?
    private var impactFeedbackHeavy: UIImpactFeedbackGenerator?
    private var impactFeedbackSoft: UIImpactFeedbackGenerator?
    private var impactFeedbackRigid: UIImpactFeedbackGenerator?
    private var selectionFeedback: UISelectionFeedbackGenerator?
    private var notificationFeedback: UINotificationFeedbackGenerator?
    
    // 设置
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("hapticIntensity") private var hapticIntensity: Double = 1.0
    
    // 触觉强度映射
    private var intensityMultiplier: CGFloat {
        return CGFloat(hapticIntensity)
    }
    
    private init() {
        setupFeedbackGenerators()
    }
    
    // MARK: - 设置反馈生成器
    
    private func setupFeedbackGenerators() {
        impactFeedbackLight = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackMedium = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackHeavy = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackSoft = UIImpactFeedbackGenerator(style: .soft)
        impactFeedbackRigid = UIImpactFeedbackGenerator(style: .rigid)
        selectionFeedback = UISelectionFeedbackGenerator()
        notificationFeedback = UINotificationFeedbackGenerator()
        
        // 准备所有生成器
        [impactFeedbackLight, impactFeedbackMedium, impactFeedbackHeavy,
         impactFeedbackSoft, impactFeedbackRigid, selectionFeedback, notificationFeedback]
            .compactMap { $0 }
            .forEach { $0.prepare() }
    }
    
    // MARK: - 触发反馈
    
    /// 触发指定类型的触觉反馈
    func trigger(_ type: DreamHapticType) {
        guard hapticEnabled else { return }
        
        switch type {
        // 基础反馈
        case .lightImpact:
            impactFeedbackLight?.impactOccurred(intensity: intensityMultiplier)
            
        case .mediumImpact:
            impactFeedbackMedium?.impactOccurred(intensity: intensityMultiplier)
            
        case .heavyImpact:
            impactFeedbackHeavy?.impactOccurred(intensity: intensityMultiplier)
            
        case .softImpact:
            impactFeedbackSoft?.impactOccurred(intensity: intensityMultiplier)
            
        case .rigidImpact:
            impactFeedbackRigid?.impactOccurred(intensity: intensityMultiplier)
            
        // 成功/错误反馈
        case .success:
            notificationFeedback?.notificationOccurred(.success)
            
        case .error:
            notificationFeedback?.notificationOccurred(.error)
            
        case .warning:
            notificationFeedback?.notificationOccurred(.warning)
            
        // 选择反馈
        case .selection:
            selectionFeedback?.selectionChanged()
            
        // 特殊场景反馈
        case .recordingStart:
            impactFeedbackHeavy?.impactOccurred(intensity: intensityMultiplier)
            
        case .recordingEnd:
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
        case .recordingPulse:
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.impactOccurred(intensity: 0.5)
            
        case .listScrollEnd:
            impactFeedbackLight?.impactOccurred(intensity: 0.3)
            
        case .refreshComplete:
            impactFeedbackMedium?.impactOccurred(intensity: intensityMultiplier)
            
        case .loadComplete:
            impactFeedbackLight?.impactOccurred(intensity: 0.6)
            
        case .toggleSwitch:
            impactFeedbackLight?.impactOccurred(intensity: 0.8)
            
        case .sliderAdjustment:
            impactFeedbackLight?.impactOccurred(intensity: 0.4)
            
        case .longPress:
            impactFeedbackMedium?.impactOccurred(intensity: intensityMultiplier)
            
        case .doubleTap:
            impactFeedbackLight?.impactOccurred(intensity: 0.7)
            
        case .dragStart:
            impactFeedbackSoft?.impactOccurred(intensity: 0.5)
            
        case .dragEnd:
            impactFeedbackMedium?.impactOccurred(intensity: 0.8)
            
        case .pageTurn:
            impactFeedbackLight?.impactOccurred(intensity: 0.5)
            
        case .modalPresent:
            impactFeedbackMedium?.impactOccurred(intensity: 0.7)
            
        case .modalDismiss:
            impactFeedbackLight?.impactOccurred(intensity: 0.6)
            
        case .accordionExpand:
            impactFeedbackLight?.impactOccurred(intensity: 0.5)
            
        case .accordionCollapse:
            impactFeedbackLight?.impactOccurred(intensity: 0.4)
            
        case .starRating:
            impactFeedbackSoft?.impactOccurred(intensity: 0.6)
            
        case .progressComplete:
            impactFeedbackHeavy?.impactOccurred(intensity: intensityMultiplier)
            
        case .unlockAchievement:
            // 连续三次轻击
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                impact.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                impact.impactOccurred()
            }
            
        case .collectItem:
            impactFeedbackSoft?.impactOccurred(intensity: 0.7)
            
        case .sendMessage:
            impactFeedbackLight?.impactOccurred(intensity: 0.5)
            
        case .receiveMessage:
            impactFeedbackLight?.impactOccurred(intensity: 0.6)
            
        case .cameraShutter:
            impactFeedbackRigid?.impactOccurred(intensity: 0.8)
            
        case .biometricSuccess:
            impactFeedbackMedium?.impactOccurred(intensity: intensityMultiplier)
            
        case .biometricFailure:
            impactFeedbackHeavy?.impactOccurred(intensity: intensityMultiplier)
        }
        
        // 准备下一次反馈
        prepareForNext()
    }
    
    /// 准备下一次反馈
    private func prepareForNext() {
        [impactFeedbackLight, impactFeedbackMedium, impactFeedbackHeavy,
         impactFeedbackSoft, impactFeedbackRigid, selectionFeedback, notificationFeedback]
            .compactMap { $0 }
            .forEach { $0.prepare() }
    }
    
    // MARK: - 组合反馈
    
    /// 触发连续反馈（用于重要操作）
    func triggerSequence(_ types: [DreamHapticType], delay: TimeInterval = 0.1) {
        guard hapticEnabled else { return }
        
        for (index, type) in types.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * delay) { [weak self] in
                self?.trigger(type)
            }
        }
    }
    
    /// 触发渐变反馈（强度递增）
    func triggerRampUpFeedback(count: Int = 3, baseType: DreamHapticType = .lightImpact) {
        guard hapticEnabled else { return }
        
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) { [weak self] in
                let intensity = self?.hapticIntensity ?? 1.0
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.impactOccurred(intensity: CGFloat(min(1.0, intensity * Double(i + 1) / Double(count))))
            }
        }
    }
    
    /// 触发渐变反馈（强度递减）
    func triggerRampDownFeedback(count: Int = 3, baseType: DreamHapticType = .mediumImpact) {
        guard hapticEnabled else { return }
        
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) { [weak self] in
                let intensity = self?.hapticIntensity ?? 1.0
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.impactOccurred(intensity: CGFloat(max(0.3, intensity * Double(count - i) / Double(count))))
            }
        }
    }
    
    // MARK: - 设置管理
    
    /// 启用/禁用触觉反馈
    func setEnabled(_ enabled: Bool) {
        hapticEnabled = enabled
        if enabled {
            setupFeedbackGenerators()
        }
    }
    
    /// 设置触觉强度 (0.0 - 1.0)
    func setIntensity(_ intensity: Double) {
        hapticIntensity = max(0.0, min(1.0, intensity))
    }
    
    /// 测试触觉反馈
    func testFeedback() {
        triggerSequence([.lightImpact, .mediumImpact, .success])
    }
}

// MARK: - UIView 扩展

extension UIView {
    /// 为按钮添加点击触觉反馈
    func addTapHaptic(_ type: DreamHapticType = .lightImpact) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapHaptic(_:)))
        tapGesture.setValue(type, forKey: "hapticType")
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    @objc private func handleTapHaptic(_ gesture: UITapGestureRecognizer) {
        if let type = gesture.value(forKey: "hapticType") as? DreamHapticType {
            DreamHapticFeedbackService.shared.trigger(type)
        }
    }
}

// MARK: - 存储键

private var hapticTypeKey: UInt8 = 0

extension UITapGestureRecognizer {
    var hapticType: DreamHapticType? {
        get {
            objc_getAssociatedObject(self, &hapticTypeKey) as? DreamHapticType
        }
        set {
            objc_setAssociatedObject(self, &hapticTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Type Alias for Backward Compatibility
/// Type alias to match existing references throughout the codebase
typealias DreamHapticFeedback = DreamHapticFeedbackService
