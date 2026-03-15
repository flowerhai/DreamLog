//
//  PerformanceOptimizationService.swift
//  DreamLog
//
//  Phase 45 - 性能优化服务
//  启动时间监控、内存使用监控、性能指标收集
//

import Foundation
import UIKit
import SwiftUI

/// 性能优化服务
class PerformanceOptimizationService: ObservableObject {
    static let shared = PerformanceOptimizationService()
    
    // MARK: - Published 性能指标
    
    @Published var launchTime: TimeInterval = 0
    @Published var memoryUsage: Int = 0
    @Published var frameRate: Double = 60.0
    @Published var isPerformant = true
    
    // MARK: - 启动时间监控
    
    private var launchStartTime: CFAbsoluteTime = 0
    private var isLaunchMonitored = false
    
    /// 记录启动开始时间
    func recordLaunchStart() {
        launchStartTime = CFAbsoluteTimeGetCurrent()
        isLaunchMonitored = true
    }
    
    /// 记录启动完成时间
    func recordLaunchEnd() {
        guard isLaunchMonitored else { return }
        let endTime = CFAbsoluteTimeGetCurrent()
        launchTime = endTime - launchStartTime
        isLaunchMonitored = false
        
        print("⚡ 启动时间：\(String(format: "%.3f", launchTime))秒")
        
        // 检查是否达标
        if launchTime > 1.5 {
            print("⚠️ 启动时间超过目标 (1.5 秒)")
            isPerformant = false
        }
    }
    
    // MARK: - 内存监控
    
    /// 获取当前内存使用量 (MB)
    func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        return Int(info.resident_size) / 1024 / 1024
    }
    
    /// 更新内存使用
    func updateMemoryUsage() {
        memoryUsage = getCurrentMemoryUsage()
        
        // 检查是否超标
        if memoryUsage > 200 {
            print("⚠️ 内存使用超过目标 (200MB): \(memoryUsage)MB")
            isPerformant = false
        }
    }
    
    /// 开始定期内存监控
    func startMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }
    
    // MARK: - 帧率监控
    
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastFrameTime = CFAbsoluteTimeGetCurrent()
    
    /// 开始帧率监控
    func startFrameRateMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrameRate))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /// 停止帧率监控
    func stopFrameRateMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateFrameRate() {
        frameCount += 1
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = currentTime - lastFrameTime
        
        if elapsedTime >= 1.0 {
            frameRate = Double(frameCount) / elapsedTime
            frameCount = 0
            lastFrameTime = currentTime
            
            // 检查帧率
            if frameRate < 55 {
                print("⚠️ 帧率低于目标 (60fps): \(String(format: "%.1f", frameRate))fps")
                isPerformant = false
            }
        }
    }
    
    // MARK: - 性能报告
    
    /// 生成性能报告
    func generatePerformanceReport() -> String {
        var report = "📊 DreamLog 性能报告\n"
        report += "========================\n\n"
        
        report += "⚡ 启动时间：\(String(format: "%.3f", launchTime))秒 "
        report += launchTime <= 1.5 ? "✅" : "⚠️"
        report += "\n"
        
        report += "🧠 内存使用：\(memoryUsage)MB "
        report += memoryUsage <= 200 ? "✅" : "⚠️"
        report += "\n"
        
        report += "✨ 帧率：\(String(format: "%.1f", frameRate))fps "
        report += frameRate >= 55 ? "✅" : "⚠️"
        report += "\n\n"
        
        report += "总体状态：\(isPerformant ? "✅ 优秀" : "⚠️ 需要优化")\n"
        
        return report
    }
    
    // MARK: - 优化建议
    
    /// 获取优化建议
    func getOptimizationSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if launchTime > 1.5 {
            suggestions.append("启动优化：延迟加载非关键资源，优化 SwiftData 初始化")
        }
        
        if memoryUsage > 200 {
            suggestions.append("内存优化：检查图片缓存，优化大列表，及时释放未使用资源")
        }
        
        if frameRate < 55 {
            suggestions.append("动画优化：减少复杂视图层级，使用 Core Animation，避免主线程阻塞")
        }
        
        if suggestions.isEmpty {
            suggestions.append("✅ 性能表现优秀，无需优化")
        }
        
        return suggestions
    }
    
    private init() {}
}

// MARK: - 延迟加载工具

/// 延迟加载容器
struct LazyView<Content: View>: View {
    let makeContent: () -> Content
    
    init(_ makeContent: @escaping () -> Content) {
        self.makeContent = makeContent
    }
    
    var body: some View {
        makeContent()
    }
}

// MARK: - 性能分析工具

/// 性能分析工具
struct PerformanceAnalyzer {
    /// 测量代码块执行时间
    static func measureTime(label: String = "", block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let end = CFAbsoluteTimeGetCurrent()
        print("⏱️ [\(label)] 执行时间：\(String(format: "%.4f", end - start))秒")
    }
    
    /// 异步测量代码块执行时间
    static func measureTimeAsync(label: String = "", block: @escaping () -> Void, completion: @escaping (Double) -> Void) {
        Task {
            let start = CFAbsoluteTimeGetCurrent()
            block()
            let end = CFAbsoluteTimeGetCurrent()
            await MainActor.run {
                completion(end - start)
            }
        }
    }
}

// MARK: - 内存警告处理

extension PerformanceOptimizationService {
    /// 处理内存警告
    func handleMemoryWarning() {
        print("⚠️ 收到内存警告，开始清理缓存...")
        
        // 清理图片缓存
        ImageCacheManager.shared.clearAll()
        
        // 更新内存使用
        updateMemoryUsage()
        
        print("✅ 内存清理完成，当前使用：\(memoryUsage)MB")
    }
    
    /// 注册内存警告通知
    func registerForMemoryWarnings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
}
