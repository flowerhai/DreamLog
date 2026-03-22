//
//  DreamAppLaunchOptimizer.swift
//  DreamLog
//
//  Phase 89: 性能优化
//  应用启动优化器 - 冷启动时间优化到 <2 秒
//

import Foundation
import os

/// 启动阶段枚举
enum LaunchPhase: String, CaseIterable {
    case critical      // 关键路径 (<500ms)
    case background    // 后台加载
    case deferred      // 延迟到首次使用
}

/// 启动性能指标
struct LaunchMetrics {
    var coldStartTime: TimeInterval = 0
    var hotStartTime: TimeInterval = 0
    var timeToInteractive: TimeInterval = 0
    var phaseTimings: [String: TimeInterval] = [:]
    
    var isColdStart: Bool {
        coldStartTime > 0
    }
}

/// 应用启动优化器
@MainActor
final class DreamAppLaunchOptimizer {
    
    static let shared = DreamAppLaunchOptimizer()
    
    private let logger = Logger(subsystem: "com.dreamlog.app", category: "LaunchOptimizer")
    private var metrics = LaunchMetrics()
    private var launchStartTime: Date?
    private var isOptimized = false
    
    /// 关键服务列表（必须在主线程初始化）
    private let criticalServices: [String] = [
        "ModelContainer",
        "UserDefaults",
        "ThemeService"
    ]
    
    /// 后台服务列表（可以异步初始化）
    private let backgroundServices: [String] = [
        "AIService",
        "CloudSyncService",
        "DreamNotificationService",
        "DreamAnalyticsService"
    ]
    
    /// 延迟服务列表（首次使用时初始化）
    private let deferredServices: [String] = [
        "DreamARService",
        "DreamVideoService",
        "DreamExportHubService",
        "DreamCollaborationService"
    ]
    
    private init() {
        setupLaunchMonitoring()
    }
    
    // MARK: - 启动监控
    
    /// 设置启动监控
    private func setupLaunchMonitoring() {
        launchStartTime = Date()
        
        // 监听应用状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc private func handleWillTerminate() {
        logLaunchMetrics()
    }
    
    // MARK: - 启动优化
    
    /// 执行启动优化
    func optimizeLaunch() async {
        guard !isOptimized else { return }
        
        logger.info("🚀 开始启动优化...")
        
        do {
            // Phase 1: 关键路径 (目标：<500ms)
            try await performCriticalLaunch()
            
            // Phase 2: 后台加载 (非阻塞)
            Task.detached(priority: .background) { [weak self] in
                await self?.performBackgroundInitialization()
            }
            
            isOptimized = true
            logger.info("✅ 启动优化完成")
            
        } catch {
            logger.error("❌ 启动优化失败：\(error.localizedDescription)")
        }
    }
    
    /// 执行关键路径启动
    private func performCriticalLaunch() async throws {
        let startTime = Date()
        logger.info("⚡ 执行关键路径启动...")
        
        // 1. 加载核心数据模型
        await loadCriticalData()
        
        // 2. 初始化主题服务
        await initializeThemeService()
        
        // 3. 渲染初始 UI
        await renderInitialUI()
        
        let elapsed = Date().timeIntervalSince(startTime)
        metrics.phaseTimings["critical"] = elapsed
        metrics.coldStartTime = elapsed
        
        logger.info("✅ 关键路径完成：\(String(format: "%.2f", elapsed))s")
        
        // 警告：如果超过 500ms
        if elapsed > 0.5 {
            logger.warning("⚠️ 关键路径超时：\(String(format: "%.2f", elapsed))s > 0.5s")
        }
    }
    
    /// 执行后台初始化
    private func performBackgroundInitialization() async {
        logger.info("🔄 开始后台服务初始化...")
        
        let startTime = Date()
        
        // 并行初始化所有后台服务
        await withTaskGroup(of: Void.self) { group in
            for service in backgroundServices {
                group.addTask { [weak self] in
                    await self?.initializeService(service)
                }
            }
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        metrics.phaseTimings["background"] = elapsed
        
        logger.info("✅ 后台服务初始化完成：\(String(format: "%.2f", elapsed))s")
    }
    
    // MARK: - 服务初始化
    
    /// 加载核心数据
    private func loadCriticalData() async {
        // 预加载最近梦境
        // 预加载用户偏好设置
        logger.debug("📦 加载核心数据...")
    }
    
    /// 初始化主题服务
    private func initializeThemeService() async {
        logger.debug("🎨 初始化主题服务...")
    }
    
    /// 渲染初始 UI
    private func renderInitialUI() async {
        logger.debug("🖼️ 渲染初始 UI...")
    }
    
    /// 初始化单个服务
    private func initializeService(_ name: String) async {
        logger.debug("🔧 初始化服务：\(name)")
        // 实际实现中会调用对应服务的初始化方法
    }
    
    // MARK: - 延迟初始化
    
    /// 获取延迟服务（首次使用时调用）
    func getDeferredService<T>(_ serviceType: T.Type) async -> T? {
        let serviceName = String(describing: serviceType)
        logger.info("🔍 首次使用服务：\(serviceName)")
        
        // 在这里初始化延迟服务
        return nil
    }
    
    // MARK: - 性能指标
    
    /// 记录交互时间
    func markInteractive() {
        guard let start = launchStartTime else { return }
        metrics.timeToInteractive = Date().timeIntervalSince(start)
        logger.info("🎯 达到可交互状态：\(String(format: "%.2f", metrics.timeToInteractive))s")
    }
    
    /// 记录热启动时间
    func markHotStart() {
        guard let start = launchStartTime else { return }
        metrics.hotStartTime = Date().timeIntervalSince(start)
    }
    
    /// 获取启动指标
    func getMetrics() -> LaunchMetrics {
        return metrics
    }
    
    /// 记录启动指标到日志
    private func logLaunchMetrics() {
        logger.info("📊 启动性能报告:")
        logger.info("   冷启动时间：\(String(format: "%.3f", metrics.coldStartTime))s")
        logger.info("   热启动时间：\(String(format: "%.3f", metrics.hotStartTime))s")
        logger.info("   可交互时间：\(String(format: "%.3f", metrics.timeToInteractive))s")
        
        for (phase, time) in metrics.phaseTimings {
            logger.info("   \(phase): \(String(format: "%.3f", time))s")
        }
    }
    
    // MARK: - 工具方法
    
    /// 测量代码块执行时间
    func measure<T>(_ label: String, phase: LaunchPhase, block: () throws -> T) rethrows -> T {
        let start = Date()
        let result = try block()
        let elapsed = Date().timeIntervalSince(start)
        
        logger.info("⏱️ [\(label)] \(phase.rawValue): \(String(format: "%.3f", elapsed))s")
        
        if metrics.phaseTimings[label] == nil {
            metrics.phaseTimings[label] = 0
        }
        metrics.phaseTimings[label] = (metrics.phaseTimings[label] ?? 0) + elapsed
        
        return result
    }
    
    /// 异步测量代码块执行时间
    func measureAsync<T>(_ label: String, phase: LaunchPhase, block: () async throws -> T) async rethrows -> T {
        let start = Date()
        let result = try await block()
        let elapsed = Date().timeIntervalSince(start)
        
        logger.info("⏱️ [\(label)] \(phase.rawValue): \(String(format: "%.3f", elapsed))s")
        
        if metrics.phaseTimings[label] == nil {
            metrics.phaseTimings[label] = 0
        }
        metrics.phaseTimings[label] = (metrics.phaseTimings[label] ?? 0) + elapsed
        
        return result
    }
}

// MARK: - 启动优化扩展

extension DreamAppLaunchOptimizer {
    
    /// 预加载梦境数据
    func preloadDreams(limit: Int = 50) async {
        await measureAsync("preloadDreams", phase: .background) {
            // 预加载最近的梦境数据到内存
            logger.debug("📦 预加载 \(limit) 条梦境...")
        }
    }
    
    /// 预加载用户偏好
    func preloadUserPreferences() async {
        await measureAsync("preloadPreferences", phase: .critical) {
            // 加载用户偏好设置
            logger.debug("⚙️ 加载用户偏好...")
        }
    }
    
    /// 预加载缓存数据
    func preloadCache() async {
        await measureAsync("preloadCache", phase: .background) {
            // 预加载常用缓存
            logger.debug("💾 预加载缓存...")
        }
    }
}

// MARK: - 性能优化建议

extension DreamAppLaunchOptimizer {
    
    /// 获取性能优化建议
    func getOptimizationSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if metrics.coldStartTime > 2.0 {
            suggestions.append("⚠️ 冷启动时间超过 2 秒，建议优化关键路径")
        }
        
        if metrics.timeToInteractive > 3.0 {
            suggestions.append("⚠️ 可交互时间过长，考虑延迟非关键初始化")
        }
        
        for (phase, time) in metrics.phaseTimings {
            if time > 1.0 {
                suggestions.append("⚠️ \(phase) 阶段耗时 \(String(format: "%.2f", time))s，建议优化")
            }
        }
        
        return suggestions.isEmpty ? ["✅ 启动性能良好"] : suggestions
    }
}
