//
//  Animations.swift
//  DreamLog
//
//  动画效果
//

import SwiftUI

// MARK: - 预设动画
struct Animations {
    /// 快速淡入
    static let quickFadeIn = Animation.easeOut(duration: 0.2)
    
    /// 标准淡入
    static let standardFadeIn = Animation.easeOut(duration: 0.3)
    
    /// 慢速淡入
    static let slowFadeIn = Animation.easeOut(duration: 0.5)
    
    /// 弹性效果
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    
    /// 弹性放大
    static let springBounce = Animation.interpolatingSpring(stiffness: 300, damping: 15)
    
    /// 平滑过渡
    static let smooth = Animation.easeInOut(duration: 0.35)
    
    /// 快速过渡
    static let quick = Animation.easeInOut(duration: 0.15)
}

// MARK: - 视图动画修饰符
struct FadeInModifier: ViewModifier {
    let duration: Double
    let delay: Double
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(Animation.easeOut(duration: duration).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct SlideUpModifier: ViewModifier {
    let duration: Double
    let delay: Double
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(Animation.easeOut(duration: duration).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct ScaleInModifier: ViewModifier {
    let duration: Double
    let delay: Double
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(Animations.springBounce.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// 添加淡入动画
    func fadeIn(duration: Double = 0.3, delay: Double = 0) -> some View {
        modifier(FadeInModifier(duration: duration, delay: delay))
    }
    
    /// 添加向上滑动动画
    func slideUp(duration: Double = 0.3, delay: Double = 0) -> some View {
        modifier(SlideUpModifier(duration: duration, delay: delay))
    }
    
    /// 添加缩放进入动画
    func scaleIn(duration: Double = 0.3, delay: Double = 0) -> some View {
        modifier(ScaleInModifier(duration: duration, delay: delay))
    }
}

// MARK: - 脉冲动画
struct PulseModifier: ViewModifier {
    let duration: Double
    let scale: CGFloat
    
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? scale : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    /// 添加脉冲效果
    func pulse(duration: Double = 1.5, scale: CGFloat = 1.05) -> some View {
        modifier(PulseModifier(duration: duration, scale: scale))
    }
}

// MARK: - 旋转动画
struct RotateModifier: ViewModifier {
    let duration: Double
    let angle: Angle
    
    @State private var isRotated = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(isRotated ? angle : .zero)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: false)) {
                    isRotated = true
                }
            }
    }
}

extension View {
    /// 添加旋转效果
    func rotate(duration: Double = 2.0, angle: Angle = .degrees(360)) -> some View {
        modifier(RotateModifier(duration: duration, angle: angle))
    }
}

// MARK: - 闪烁动画
struct ShimmerModifier: ViewModifier {
    let duration: Double
    
    @State private var isShimmering = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isShimmering ? 0.5 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isShimmering = true
                }
            }
    }
}

extension View {
    /// 添加闪烁效果
    func shimmer(duration: Double = 1.0) -> some View {
        modifier(ShimmerModifier(duration: duration))
    }
}

// MARK: - 波浪动画 (用于录音)
struct WaveformAnimation: ViewModifier {
    @State private var waveOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: waveOffset)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    waveOffset = -20
                }
            }
    }
}

extension View {
    /// 添加波浪效果
    func waveform() -> some View {
        modifier(WaveformAnimation())
    }
}

// MARK: - 粒子效果
struct ParticleEffect: View {
    let count: Int
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ParticleView(color: color, delay: Double(index) * 0.1)
            }
        }
    }
}

struct ParticleView: View {
    let color: Color
    let delay: Double
    
    @State private var offset = CGSize.zero
    @State private var opacity = 1.0
    @State private var scale = 1.0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
            .offset(offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(Animation.easeOut(duration: 1.5).delay(delay)) {
                    offset = CGSize(
                        width: CGFloat.random(in: -100...100),
                        height: CGFloat.random(in: -100...-20)
                    )
                    opacity = 0
                    scale = 0.5
                }
            }
    }
}

// MARK: - 成功动画
struct SuccessAnimation: ViewModifier {
    @State private var scale = 0.5
    @State private var opacity = 0.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animations.springBounce) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

extension View {
    /// 添加成功动画
    func successAnimation() -> some View {
        modifier(SuccessAnimation())
    }
}

// MARK: - 列表项动画
struct ListItemAnimation: ViewModifier {
    let index: Int
    let baseDelay: Double
    
    @State private var isVisible = false
    
    var delay: Double {
        baseDelay + Double(index) * 0.05
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: isVisible ? 0 : -20)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(Animation.easeOut(duration: 0.3).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// 添加列表项动画
    func listItemAnimation(index: Int, baseDelay: Double = 0.1) -> some View {
        modifier(ListItemAnimation(index: index, baseDelay: baseDelay))
    }
}

// MARK: - 页面转场
struct PageTransition: Transition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var slideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
}

// MARK: - 星空背景动画
struct StarryBackground: View {
    let starCount: Int = 50
    
    var body: some View {
        ZStack {
            ForEach(0..<starCount, id: \.self) { index in
                StarView(delay: Double.random(in: 0...2))
            }
        }
    }
}

struct StarView: View {
    let delay: Double
    
    @State private var opacity = 0.3
    @State private var scale = 1.0
    
    var randomPosition: CGPoint {
        CGPoint(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1)
        )
    }
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
            .position(x: randomPosition.x * 100, y: randomPosition.y * 100)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2.0).delay(delay).repeatForever(autoreverses: true)) {
                    opacity = CGFloat.random(in: 0.3...1.0)
                    scale = CGFloat.random(in: 1.0...1.5)
                }
            }
    }
}
