//
//  HapticFeedback.swift
//  DreamLog
//
//  触觉反馈工具
//

import UIKit
import SwiftUI

/// 触觉反馈管理器
class HapticFeedback {
    static let shared = HapticFeedback()
    
    private init() {}
    
    // MARK: - 成功反馈
    func success() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
    }
    
    // MARK: - 错误反馈
    func error() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - 警告反馈
    func warning() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.warning)
    }
    
    // MARK: - 轻击反馈
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - 中等击打反馈
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - 重击反馈
    func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - 选择反馈
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - 连续反馈 (用于录音等)
    func continuous(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, count: Int = 3, interval: TimeInterval = 0.1) {
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<count {
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
                
                if i < count - 1 {
                    Thread.sleep(forTimeInterval: interval)
                }
            }
        }
    }
}

// MARK: - View 扩展 - 添加触觉反馈
extension View {
    /// 添加点击触觉反馈
    func hapticTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticFeedback.shared.lightTap()
                }
        )
    }
}

// MARK: - 按钮扩展
extension Button where Label == Text {
    /// 创建带触觉反馈的按钮
    init(_ title: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light, action: @escaping () -> Void) {
        self.init(action: {
            HapticFeedback.shared.lightTap()
            action()
        }, label: {
            Text(title)
        })
    }
}

// MARK: - 录音触觉反馈
extension HapticFeedback {
    /// 录音开始反馈
    func recordingStarted() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 录音结束反馈
    func recordingEnded() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // 成功提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
        }
    }
    
    /// 录音取消反馈
    func recordingCancelled() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
