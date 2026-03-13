# DreamLog 网络优化指南 🌐

> 网络请求缓存、离线模式、弱网环境优化

**Phase 30.3 - 性能优化**  
**目标**: 提升网络性能，优化用户体验  
**优先级**: 🟡 中

---

## 📊 当前网络架构

### 现有组件

1. **DreamAPI** - AI 解析 API 调用
2. **DreamCloudService** - iCloud 同步
3. **DreamBackupService** - 备份与恢复
4. **DreamShareService** - 分享功能

### 网络请求类型

| 类型 | 频率 | 数据量 | 优先级 |
|------|------|--------|--------|
| AI 梦境解析 | 中 (用户触发) | 中 (~5KB) | 🔴 高 |
| AI 图像生成 | 低 (用户触发) | 大 (~2MB) | 🟡 中 |
| iCloud 同步 | 高 (自动) | 中 (~10KB) | 🔴 高 |
| 备份上传 | 低 (用户触发) | 大 (~10MB+) | 🟢 低 |
| 数据导出 | 低 (用户触发) | 大 (~5MB+) | 🟢 低 |

---

## 🎯 优化目标

| 指标 | 当前 | 目标 | 改进 |
|------|------|------|------|
| AI 解析响应时间 | ~2-3s | <1.5s | -50% |
| 离线可用性 | 部分 | 完全 | +100% |
| 弱网成功率 | ~70% | >95% | +25% |
| 流量消耗 | 基准 | -40% | -40% |

---

## 💾 网络缓存策略

### 1. URLCache 配置

```swift
// DreamLog/DreamNetworkCache.swift

import Foundation

class DreamNetworkCache {
    static let shared = DreamNetworkCache()
    
    private let urlCache: URLCache
    private let memoryCapacity: UInt = 50 * 1024 * 1024  // 50MB
    private let diskCapacity: UInt = 200 * 1024 * 1024   // 200MB
    
    private init() {
        urlCache = URLCache(
            memoryCapacity: Int(memoryCapacity),
            diskCapacity: Int(diskCapacity),
            directory: cacheDirectory
        )
        URLSessionConfiguration.default.urlCache = urlCache
    }
    
    private var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("DreamNetworkCache")
    }
    
    // 配置请求缓存策略
    func configureRequest(_ request: inout URLRequest) {
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 30
    }
    
    // 清除缓存
    func clearCache() {
        urlCache.removeAllCachedResponses()
    }
    
    // 获取缓存大小
    func getCacheSize() -> UInt64 {
        var totalSize: UInt64 = 0
        if let contents = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for url in contents {
                if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += UInt64(fileSize)
                }
            }
        }
        return totalSize
    }
}
```

### 2. 响应缓存装饰器

```swift
// DreamLog/DreamCacheDecorator.swift

import Foundation

class DreamCacheDecorator {
    
    enum CachePolicy {
        case none
        case timeBased(Duration)
        case contentBased
        case userControlled
    }
    
    enum Duration {
        case seconds(Int)
        case minutes(Int)
        case hours(Int)
        case days(Int)
        
        var seconds: Int {
            switch self {
            case .seconds(let s): return s
            case .minutes(let m): return m * 60
            case .hours(let h): return h * 3600
            case .days(let d): return d * 86400
            }
        }
    }
    
    // 缓存 AI 解析结果
    func cacheAIAnalysis(dreamId: String, result: AIAnalysisResult, policy: Duration = .hours(24)) {
        let cacheKey = "ai_analysis_\(dreamId)"
        let data = try? JSONEncoder().encode(result)
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "\(cacheKey)_timestamp")
    }
    
    // 获取缓存的 AI 解析
    func getCachedAIAnalysis(dreamId: String, maxAge: Duration = .hours(24)) -> AIAnalysisResult? {
        let cacheKey = "ai_analysis_\(dreamId)"
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let timestamp = UserDefaults.standard.object(forKey: "\(cacheKey)_timestamp") as? TimeInterval else {
            return nil
        }
        
        // 检查缓存是否过期
        let age = Date().timeIntervalSince1970 - timestamp
        if age > Double(maxAge.seconds) {
            return nil
        }
        
        return try? JSONDecoder().decode(AIAnalysisResult.self, from: data)
    }
    
    // 缓存统计结果
    func cacheStatistics(stats: DreamStatistics, policy: Duration = .minutes(30)) {
        let cacheKey = "dream_statistics"
        let data = try? JSONEncoder().encode(stats)
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "\(cacheKey)_timestamp")
    }
    
    // 获取缓存的统计
    func getCachedStatistics(maxAge: Duration = .minutes(30)) -> DreamStatistics? {
        let cacheKey = "dream_statistics"
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let timestamp = UserDefaults.standard.object(forKey: "\(cacheKey)_timestamp") as? TimeInterval else {
            return nil
        }
        
        let age = Date().timeIntervalSince1970 - timestamp
        if age > Double(maxAge.seconds) {
            return nil
        }
        
        return try? JSONDecoder().decode(DreamStatistics.self, from: data)
    }
}
```

### 3. 图片缓存优化

```swift
// DreamLog/DreamImageCache.swift

import UIKit

class DreamImageCache {
    static let shared = DreamImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private let maxMemoryItems = 100
    private let maxDiskSize: UInt64 = 100 * 1024 * 1024  // 100MB
    
    private init() {
        cache.countLimit = maxMemoryItems
        
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("DreamImageCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // 保存图片到缓存
    func saveImage(_ image: UIImage, forKey key: String) {
        // 内存缓存
        cache.setObject(image, forKey: key as NSString)
        
        // 磁盘缓存
        if let data = image.jpegData(compressionQuality: 0.8) {
            let fileURL = cacheDirectory.appendingPathComponent(key)
            try? data.write(to: fileURL)
        }
    }
    
    // 从缓存获取图片
    func getImage(forKey key: String) -> UIImage? {
        // 先尝试内存缓存
        if let cachedImage = cache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // 再尝试磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // 重新存入内存缓存
            cache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    // 清除缓存
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // 获取缓存大小
    func getCacheSize() -> UInt64 {
        var totalSize: UInt64 = 0
        if let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for url in contents {
                if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += UInt64(fileSize)
                }
            }
        }
        return totalSize
    }
}
```

---

## 📴 离线模式

### 1. 离线数据管理器

```swift
// DreamLog/DreamOfflineManager.swift

import Foundation
import Combine

class DreamOfflineManager: ObservableObject {
    static let shared = DreamOfflineManager()
    
    @Published var isOfflineMode = false
    @Published var pendingOperations: [PendingOperation] = []
    
    private let networkMonitor = DreamNetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 监听网络状态
        networkMonitor.$reachability
            .receive(on: RunLoop.main)
            .sink { [weak self] reachability in
                self?.handleNetworkChange(reachability)
            }
            .store(in: &cancellables)
    }
    
    private func handleNetworkChange(_ reachability: NetworkReachability) {
        switch reachability {
        case .notReachable:
            isOfflineMode = true
            // 保存待同步操作
        case .reachableViaWiFi, .reachableViaCellular:
            isOfflineMode = false
            // 执行待同步操作
            Task {
                await syncPendingOperations()
            }
        }
    }
    
    // 添加待同步操作
    func addPendingOperation(_ operation: PendingOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    // 同步待处理操作
    func syncPendingOperations() async {
        guard !pendingOperations.isEmpty else { return }
        
        for operation in pendingOperations {
            await executeOperation(operation)
        }
        
        pendingOperations.removeAll()
        savePendingOperations()
    }
    
    private func executeOperation(_ operation: PendingOperation) async {
        switch operation.type {
        case .dreamSync:
            await DreamCloudService.shared.syncDream(operation.dreamId)
        case .analysisRequest:
            await DreamAPIService.shared.requestAnalysis(dreamId: operation.dreamId)
        case .backup:
            await DreamBackupService.shared.performBackup()
        }
    }
    
    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(data, forKey: "DreamPendingOperations")
        }
    }
    
    private func loadPendingOperations() {
        guard let data = UserDefaults.standard.data(forKey: "DreamPendingOperations"),
              let operations = try? JSONDecoder().decode([PendingOperation].self, from: data) else {
            pendingOperations = []
            return
        }
        pendingOperations = operations
    }
}

// 待处理操作模型
struct PendingOperation: Codable {
    enum OperationType: String, Codable {
        case dreamSync
        case analysisRequest
        case backup
    }
    
    var id: UUID = UUID()
    var type: OperationType
    var dreamId: String
    var createdAt: Date = Date()
}
```

### 2. 本地数据优先策略

```swift
// DreamLog/DreamDataRepository.swift

import Foundation
import Combine
import SwiftData

class DreamDataRepository: ObservableObject {
    @Published var dreams: [Dream] = []
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    
    private let modelContext: ModelContext
    private let cloudService = DreamCloudService.shared
    private let offlineManager = DreamOfflineManager.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLocalDreams()
    }
    
    // 获取梦境列表（本地优先）
    func fetchDreams() async -> [Dream] {
        // 1. 立即返回本地数据
        let localDreams = loadLocalDreams()
        
        // 2. 后台同步
        Task.detached { [weak self] in
            await self?.syncWithCloud()
        }
        
        return localDreams
    }
    
    // 保存梦境（本地 + 队列同步）
    func saveDream(_ dream: Dream) async {
        // 1. 立即保存到本地
        saveToLocal(dream)
        
        // 2. 检查网络状态
        if offlineManager.isOfflineMode {
            // 离线模式：加入待同步队列
            offlineManager.addPendingOperation(
                PendingOperation(type: .dreamSync, dreamId: dream.id.uuidString)
            )
        } else {
            // 在线模式：同步到云端
            Task.detached {
                await self.cloudService.syncDream(dream.id.uuidString)
            }
        }
    }
    
    // 删除梦境
    func deleteDream(_ dream: Dream) async {
        // 1. 本地删除
        deleteFromLocal(dream)
        
        // 2. 云端删除（如果在线）
        if !offlineManager.isOfflineMode {
            Task.detached {
                await self.cloudService.deleteDream(dream.id.uuidString)
            }
        }
    }
    
    private func loadLocalDreams() -> [Dream] {
        let fetchDescriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        dreams = (try? modelContext.fetch(fetchDescriptor)) ?? []
        return dreams
    }
    
    private func saveToLocal(_ dream: Dream) {
        modelContext.insert(dream)
        try? modelContext.save()
        loadLocalDreams()
    }
    
    private func deleteFromLocal(_ dream: Dream) {
        modelContext.delete(dream)
        try? modelContext.save()
        loadLocalDreams()
    }
    
    private func syncWithCloud() async {
        isLoading = true
        await cloudService.syncAllDreams()
        isLoading = false
        lastSyncDate = Date()
        loadLocalDreams()
    }
}
```

---

## 📶 弱网环境优化

### 1. 网络质量监测

```swift
// DreamLog/DreamNetworkMonitor.swift

import Foundation
import Network
import Combine

class DreamNetworkMonitor: ObservableObject {
    static let shared = DreamNetworkMonitor()
    
    @Published var reachability: NetworkReachability = .notReachable
    @Published var networkQuality: NetworkQuality = .unknown
    @Published var currentBandwidth: Double = 0  // Mbps
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "DreamNetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    enum NetworkReachability {
        case notReachable
        case reachableViaWiFi
        case reachableViaCellular
    }
    
    enum NetworkQuality: String {
        case unknown = "未知"
        case excellent = "优秀 (>10 Mbps)"
        case good = "良好 (5-10 Mbps)"
        case fair = "一般 (1-5 Mbps)"
        case poor = "较差 (<1 Mbps)"
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        monitor.start(queue: queue)
        
        // 定期测试网络质量
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.testNetworkQuality()
            }
            .store(in: &cancellables)
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        switch path.status {
        case .satisfied:
            if path.usesInterfaceType(.wifi) {
                reachability = .reachableViaWiFi
            } else if path.usesInterfaceType(.cellular) {
                reachability = .reachableViaCellular
            }
        case .unsatisfied:
            reachability = .notReachable
        case .requiresConnection:
            break
        @unknown default:
            break
        }
    }
    
    private func testNetworkQuality() {
        // 简单的网络质量测试
        // 实际应用中可以下载测试文件或使用 SpeedTest API
        Task {
            let startTime = Date()
            // 模拟网络请求测试
            let testURL = URL(string: "https://www.apple.com")!
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 5
            config.timeoutIntervalForResource = 10
            
            do {
                let (_, response) = try await URLSession(configuration: config).data(from: testURL)
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    updateNetworkQuality(basedOn: duration)
                }
            } catch {
                networkQuality = .poor
            }
        }
    }
    
    private func updateNetworkQuality(basedOn duration: TimeInterval) {
        // 根据响应时间评估网络质量
        if duration < 0.5 {
            networkQuality = .excellent
            currentBandwidth = 10
        } else if duration < 1.0 {
            networkQuality = .good
            currentBandwidth = 5
        } else if duration < 3.0 {
            networkQuality = .fair
            currentBandwidth = 1
        } else {
            networkQuality = .poor
            currentBandwidth = 0.5
        }
    }
    
    // 判断是否适合进行大文件传输
    func canPerformLargeTransfer() -> Bool {
        return reachability != .notReachable &&
               (networkQuality == .excellent || networkQuality == .good)
    }
    
    // 判断是否适合进行 AI 请求
    func canPerformAIRequest() -> Bool {
        return reachability != .notReachable &&
               networkQuality != .poor
    }
}
```

### 2. 自适应请求策略

```swift
// DreamLog/DreamAdaptiveRequest.swift

import Foundation

class DreamAdaptiveRequest {
    static let shared = DreamAdaptiveRequest()
    
    private let networkMonitor = DreamNetworkMonitor.shared
    private let cache = DreamCacheDecorator()
    
    // 自适应 AI 解析请求
    func requestAIAnalysis(dream: Dream, completion: @escaping (AIAnalysisResult?) -> Void) {
        // 1. 检查网络质量
        guard networkMonitor.canPerformAIRequest() else {
            // 网络差：使用缓存或降级
            if let cached = cache.getCachedAIAnalysis(dreamId: dream.id.uuidString) {
                completion(cached)
            } else {
                // 无缓存：提示用户
                completion(nil)
            }
            return
        }
        
        // 2. 网络好：正常请求
        Task {
            do {
                let result = try await DreamAPIService.shared.analyzeDream(dream)
                // 缓存结果
                cache.cacheAIAnalysis(dreamId: dream.id.uuidString, result: result)
                completion(result)
            } catch {
                // 请求失败：尝试缓存
                if let cached = cache.getCachedAIAnalysis(dreamId: dream.id.uuidString) {
                    completion(cached)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    // 自适应图片上传
    func uploadImage(_ image: UIImage, for dreamId: String) async throws {
        // 检查是否适合大文件传输
        guard networkMonitor.canPerformLargeTransfer() else {
            // 网络差：压缩图片后上传
            let compressedImage = image.compress(to: 500)  // 压缩到 500KB
            try await DreamCloudService.shared.uploadImage(compressedImage, for: dreamId)
            return
        }
        
        // 网络好：上传原图
        try await DreamCloudService.shared.uploadImage(image, for: dreamId)
    }
}

// UIImage 扩展 - 压缩
extension UIImage {
    func compress(to maxSizeKB: Int) -> UIImage {
        var compression: CGFloat = 1.0
        var data = self.jpegData(compressionQuality: compression)
        
        while let imageData = data, imageData.count > maxSizeKB * 1024, compression > 0.1 {
            compression -= 0.1
            data = self.jpegData(compressionQuality: compression)
        }
        
        return UIImage(data: data ?? Data()) ?? self
    }
}
```

### 3. 请求重试机制

```swift
// DreamLog/DreamRetryManager.swift

import Foundation

class DreamRetryManager {
    static let shared = DreamRetryManager()
    
    struct RetryConfig {
        var maxRetries: Int = 3
        var initialDelay: TimeInterval = 1.0
        var maxDelay: TimeInterval = 30.0
        var exponentialBase: Double = 2.0
    }
    
    private var retryTasks: [String: Task<Void, Never>] = [:]
    private let config = RetryConfig()
    
    // 带重试的执行
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        key: String,
        onSuccess: @escaping (T) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        retryTasks[key]?.cancel()
        
        retryTasks[key] = Task {
            var lastError: Error?
            var delay = config.initialDelay
            
            for attempt in 1...config.maxRetries {
                do {
                    let result = try await operation()
                    await MainActor.run {
                        onSuccess(result)
                    }
                    retryTasks.removeValue(forKey: key)
                    return
                } catch {
                    lastError = error
                    
                    if attempt < config.maxRetries {
                        // 等待后重试
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        delay = min(delay * config.exponentialBase, config.maxDelay)
                    }
                }
            }
            
            // 所有重试失败
            if let error = lastError {
                await MainActor.run {
                    onFailure(error)
                }
            }
            retryTasks.removeValue(forKey: key)
        }
    }
    
    // 取消重试
    func cancelRetry(key: String) {
        retryTasks[key]?.cancel()
        retryTasks.removeValue(forKey: key)
    }
    
    // 取消所有重试
    func cancelAllRetries() {
        for task in retryTasks.values {
            task.cancel()
        }
        retryTasks.removeAll()
    }
}
```

---

## 📊 性能监控

### 监控指标

```swift
// DreamLog/DreamNetworkMetrics.swift

import Foundation

class DreamNetworkMetrics {
    static let shared = DreamNetworkMetrics()
    
    struct Metrics {
        var totalRequests: Int = 0
        var successfulRequests: Int = 0
        var failedRequests: Int = 0
        var cachedResponses: Int = 0
        var totalDataTransferred: UInt64 = 0
        var averageResponseTime: TimeInterval = 0
    }
    
    @Published var currentMetrics = Metrics()
    
    private var responseTimes: [TimeInterval] = []
    private let maxSamples = 100
    
    // 记录请求
    func recordRequest(success: Bool, dataSize: UInt64 = 0, responseTime: TimeInterval = 0) {
        currentMetrics.totalRequests += 1
        
        if success {
            currentMetrics.successfulRequests += 1
        } else {
            currentMetrics.failedRequests += 1
        }
        
        currentMetrics.totalDataTransferred += dataSize
        
        responseTimes.append(responseTime)
        if responseTimes.count > maxSamples {
            responseTimes.removeFirst()
        }
        
        currentMetrics.averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    // 记录缓存命中
    func recordCacheHit() {
        currentMetrics.cachedResponses += 1
    }
    
    // 获取成功率
    var successRate: Double {
        guard currentMetrics.totalRequests > 0 else { return 0 }
        return Double(currentMetrics.successfulRequests) / Double(currentMetrics.totalRequests)
    }
    
    // 获取缓存命中率
    var cacheHitRate: Double {
        let total = currentMetrics.successfulRequests + currentMetrics.cachedResponses
        guard total > 0 else { return 0 }
        return Double(currentMetrics.cachedResponses) / Double(total)
    }
    
    // 重置指标
    func resetMetrics() {
        currentMetrics = Metrics()
        responseTimes.removeAll()
    }
}
```

---

## ✅ 实施清单

### 阶段 1: 基础缓存 (1-2 天)

- [ ] 实现 URLCache 配置
- [ ] 添加 AI 解析结果缓存
- [ ] 添加统计数据缓存
- [ ] 实现图片缓存优化

### 阶段 2: 离线模式 (2-3 天)

- [ ] 实现网络状态监测
- [ ] 添加待同步操作队列
- [ ] 实现本地数据优先策略
- [ ] 添加离线提示 UI

### 阶段 3: 弱网优化 (2-3 天)

- [ ] 实现网络质量评估
- [ ] 添加自适应请求策略
- [ ] 实现图片压缩上传
- [ ] 添加请求重试机制

### 阶段 4: 监控与调优 (1-2 天)

- [ ] 实现网络性能监控
- [ ] 添加指标上报
- [ ] 性能基准测试
- [ ] 文档完善

---

## 📈 预期效果

| 指标 | 优化前 | 优化后 | 改进 |
|------|--------|--------|------|
| AI 解析平均响应 | 2.5s | 1.2s | -52% |
| 离线可用性 | 60% | 95% | +35% |
| 弱网成功率 | 70% | 95% | +25% |
| 流量消耗 | 基准 | -40% | -40% |
| 缓存命中率 | 20% | 60% | +40% |

---

## 🔧 故障排除

### 问题：缓存不生效

**检查项**:
- URLCache 配置是否正确
- 请求头是否允许缓存
- 缓存目录权限

### 问题：离线同步失败

**检查项**:
- 待同步队列是否持久化
- 网络恢复后是否触发同步
- 冲突解决策略

### 问题：网络质量评估不准

**检查项**:
- 测试 URL 是否可达
- 测试频率是否合理
- 是否考虑了不同网络类型

---

**创建时间**: 2026-03-13 10:04 UTC  
**最后更新**: 2026-03-13 10:04 UTC  
**负责人**: DreamLog 开发团队  
**状态**: 📝 待实施
