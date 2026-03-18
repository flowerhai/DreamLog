# Phase 64 开发计划 - 健康集成与睡眠追踪 🍎💤

**创建时间**: 2026-03-18 02:04 UTC  
**优先级**: 中  
**预计时间**: 6-8 小时  
**状态**: 📋 计划中

---

## 🎯 Phase 64 目标

将 DreamLog 与 Apple Health 深度集成，实现睡眠数据自动同步、睡眠质量分析、以及基于睡眠状态的智能梦境推荐。

---

## 📦 新增文件 (5 个)

### 1. DreamHealthIntegrationModels.swift (~350 行)

**健康数据模型**:
```swift
@Model
final class SleepSession {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var quality: SleepQuality // .excellent, .good, .fair, .poor
    var remDuration: TimeInterval?
    var coreDuration: TimeInterval?
    var deepDuration: TimeInterval?
    var awakeDuration: TimeInterval?
    var source: String // "Apple Watch", "Manual", "Auto"
}

@Model
final class HealthMetrics {
    var id: UUID
    var date: Date
    var restingHeartRate: Double?
    var heartRateVariability: Double?
    var respiratoryRate: Double?
    var sleepGoal: TimeInterval
    var actualSleep: TimeInterval
}

enum SleepQuality: String, CaseIterable {
    case excellent = "优秀"
    case good = "良好"
    case fair = "一般"
    case poor = "较差"
}
```

### 2. DreamHealthIntegrationService.swift (~550 行)

**健康服务核心**:
```swift
@ModelActor
final class DreamHealthIntegrationService {
    // HealthKit 授权
    func requestAuthorization() async throws -> Bool
    
    // 睡眠数据同步
    func syncSleepSessions(from startDate: Date, to endDate: Date) async throws -> [SleepSession]
    
    // 睡眠质量分析
    func analyzeSleepQuality(for date: Date) async throws -> SleepQuality
    
    // 梦境 - 睡眠关联分析
    func correlateDreamsWithSleep() async throws -> [DreamSleepCorrelation]
    
    // 基于睡眠的智能推荐
    func getDreamRecommendations(basedOn sleepQuality: SleepQuality) -> [DreamRecommendation]
    
    // 健康指标查询
    func getHealthMetrics(for date: Date) async throws -> HealthMetrics?
}
```

**核心功能**:
- ✅ HealthKit 授权管理
- ✅ 睡眠阶段数据读取 (REM/Core/Deep/Awake)
- ✅ 睡眠质量自动评估
- ✅ 梦境记录与睡眠数据关联
- ✅ 睡眠趋势分析
- ✅ 智能梦境推荐 (基于睡眠质量)
- ✅ 心率/呼吸率等健康指标集成

### 3. DreamHealthDashboardView.swift (~650 行)

**健康仪表板 UI**:
```swift
struct DreamHealthDashboardView: View {
    @Environment(ModelContext.self) var modelContext
    @State private var sleepSessions: [SleepSession]
    @State private var selectedPeriod: Period = .week
    
    var body: some View {
        NavigationStack {
            List {
                // 睡眠概览卡片
                SleepOverviewCard(averageDuration: avgDuration, quality: avgQuality)
                
                // 睡眠阶段分布
                SleepStageChart(sessions: sleepSessions)
                
                // 睡眠质量趋势
                SleepQualityTrendChart(period: selectedPeriod)
                
                // 梦境 - 睡眠关联
                DreamSleepCorrelationSection(correlations: correlations)
                
                // 智能推荐
                SmartRecommendationsSection(quality: currentQuality)
                
                // 健康指标
                HealthMetricsCard(metrics: todayMetrics)
            }
        }
    }
}
```

**UI 组件**:
- ✅ 睡眠概览卡片 (时长/质量/趋势)
- ✅ 睡眠阶段环形图 (REM/Core/Deep/Awake)
- ✅ 睡眠质量趋势图表 (7/30/90 天)
- ✅ 梦境 - 睡眠关联分析
- ✅ 智能推荐卡片
- ✅ 健康指标卡片 (心率/呼吸率/HRV)

### 4. DreamSleepReminderService.swift (~300 行)

**智能提醒服务**:
```swift
@ModelActor
final class DreamSleepReminderService {
    // 睡前提醒
    func scheduleBedtimeReminder(preferredTime: Date)
    
    // 晨间记录提醒 (基于起床时间)
    func scheduleMorningRecordingReminder(wakeUpTime: Date)
    
    // 最佳记录时间提醒 (REM 睡眠后)
    func scheduleOptimalRecordingReminder()
    
    // 睡眠目标达成提醒
    func scheduleSleepGoalReminder(goal: TimeInterval)
}
```

**提醒类型**:
- ✅ 睡前准备提醒 (提前 30 分钟)
- ✅ 晨间梦境记录提醒 (起床后 15 分钟)
- ✅ 最佳回忆时机提醒 (REM 睡眠后)
- ✅ 睡眠目标达成/未达成提醒
- ✅ 连续记录鼓励提醒

### 5. DreamHealthIntegrationTests.swift (~400 行)

**单元测试**:
```swift
final class DreamHealthIntegrationTests: XCTestCase {
    // 健康授权测试
    func testHealthKitAuthorization() async throws
    
    // 睡眠数据同步测试
    func testSleepSessionSync() async throws
    
    // 睡眠质量分析测试
    func testSleepQualityAnalysis() async throws
    
    // 梦境 - 睡眠关联测试
    func testDreamSleepCorrelation() async throws
    
    // 智能推荐测试
    func testSmartRecommendations() async throws
    
    // 提醒服务测试
    func testSleepReminderScheduling() async throws
}
```

**测试覆盖**:
- ✅ 30+ 测试用例
- ✅ 数据模型测试
- ✅ 服务层测试
- ✅ UI 组件测试
- ✅ 边界情况测试
- ✅ 测试覆盖率：95%+

---

## 🔧 修改文件 (3 个)

### 1. DreamLogApp.swift

**集成健康服务**:
```swift
@main
struct DreamLogApp: App {
    @StateObject private var healthIntegrationManager = HealthIntegrationManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(healthIntegrationManager)
                .onAppear {
                    Task {
                        await healthIntegrationManager.checkHealthAuthorization()
                    }
                }
        }
    }
}
```

### 2. ContentView.swift / RootView.swift

**添加健康入口**:
```swift
Tab("健康", systemImage: "heart.fill") {
    DreamHealthDashboardView()
}
```

### 3. Info.plist

**添加 HealthKit 权限**:
```xml
<key>NSHealthShareUsageDescription</key>
<string>DreamLog 需要访问您的睡眠数据，以提供更精准的梦境分析和推荐。</string>
<key>NSHealthUpdateUsageDescription</key>
<string>DreamLog 可以记录您的梦境数据到健康应用，帮助您全面了解睡眠质量。</string>
```

---

## 📊 核心功能详解

### 1. 睡眠数据自动同步

**同步策略**:
- 每日自动同步前一天的睡眠数据
- 手动触发立即同步
- 后台刷新支持
- 增量同步优化性能

**数据来源**:
- Apple Watch (首选，最准确)
- iPhone (基于使用情况和运动)
- 第三方睡眠应用 (AutoSleep, Sleep Cycle 等)
- 手动输入

### 2. 梦境 - 睡眠关联分析

**分析维度**:
- 睡眠质量 vs 梦境清晰度
- REM 睡眠时长 vs 清醒梦发生率
- 睡眠时长 vs 梦境情绪
- 入睡时间 vs 梦境主题
- 夜间觉醒次数 vs 梦境记忆强度

**可视化**:
- 相关性热力图
- 散点图趋势分析
- 统计显著性标注

### 3. 智能梦境推荐

**基于睡眠质量**:
- 优秀睡眠 → 创意启发类孵育
- 良好睡眠 → 深度探索类记录
- 一般睡眠 → 轻松正念类练习
- 较差睡眠 → 疗愈放松类冥想

**基于睡眠阶段**:
- REM 充足 → 清醒梦训练
- Deep 充足 → 创意记录
- Core 为主 → 基础记录

### 4. 睡眠趋势分析

**时间维度**:
- 7 天趋势 (短期)
- 30 天趋势 (中期)
- 90 天趋势 (长期)
- 年度对比

**指标追踪**:
- 平均睡眠时长
- 睡眠质量分布
- 各阶段占比
- 连续达标天数

---

## 🎨 UI/UX 设计

### 健康仪表板布局

```
┌─────────────────────────────────┐
│  健康与睡眠           🔔 设置   │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │   睡眠概览              │   │
│  │   7h 23m  优秀 ⬆️ 12%   │   │
│  └─────────────────────────┘   │
│                                 │
│  睡眠阶段                        │
│  ┌─────────────────────────┐   │
│  │      [环形图]           │   │
│  │   REM 23%  Core 55%     │   │
│  │   Deep 18%  Awake 4%    │   │
│  └─────────────────────────┘   │
│                                 │
│  睡眠质量趋势                    │
│  ┌─────────────────────────┐   │
│  │     [折线图表]          │   │
│  │  优秀 良好 一般 较差    │   │
│  └─────────────────────────┘   │
│                                 │
│  梦境 - 睡眠关联                │
│  ┌─────────────────────────┐   │
│  │  睡眠质量高时：         │   │
│  │  • 梦境清晰度 +35%      │   │
│  │  • 清醒梦发生率 +28%    │   │
│  │  • 积极情绪 +42%        │   │
│  └─────────────────────────┘   │
│                                 │
│  智能推荐                        │
│  ┌─────────────────────────┐   │
│  │  💡 基于昨晚的优秀睡眠  │   │
│  │     推荐尝试创意孵育    │   │
│  │     [开始孵育 →]        │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## 📈 预期成果

### 代码统计

| 类型 | 文件数 | 新增行 | 说明 |
|------|--------|--------|------|
| Swift 模型 | 1 | ~350 | 健康数据模型 |
| Swift 服务 | 2 | ~850 | 健康服务 + 提醒服务 |
| Swift UI | 1 | ~650 | 健康仪表板 |
| Swift 测试 | 1 | ~400 | 单元测试 |
| **总计** | **5** | **~2,250** | |

### 功能完成度

| 功能模块 | 完成度 | 状态 |
|---------|--------|------|
| HealthKit 集成 | 100% | ✅ |
| 睡眠数据同步 | 100% | ✅ |
| 睡眠质量分析 | 100% | ✅ |
| 梦境 - 睡眠关联 | 100% | ✅ |
| 智能推荐 | 100% | ✅ |
| 健康仪表板 UI | 100% | ✅ |
| 智能提醒 | 100% | ✅ |
| 单元测试 | 95%+ | ✅ |

### 代码质量目标

- TODO 标记：0 个 ✅
- FIXME 标记：0 个 ✅
- 强制解包：0 个 ✅
- 测试覆盖率：95%+ ✅

---

## 🚀 实施步骤

### Step 1: 模型与服务层 (2 小时)
- [ ] 创建 DreamHealthIntegrationModels.swift
- [ ] 创建 DreamHealthIntegrationService.swift
- [ ] 实现 HealthKit 授权
- [ ] 实现睡眠数据同步
- [ ] 实现睡眠质量分析

### Step 2: UI 层 (2 小时)
- [ ] 创建 DreamHealthDashboardView.swift
- [ ] 实现睡眠概览卡片
- [ ] 实现睡眠阶段图表
- [ ] 实现睡眠质量趋势图
- [ ] 实现关联分析展示

### Step 3: 提醒服务 (1 小时)
- [ ] 创建 DreamSleepReminderService.swift
- [ ] 实现睡前提醒
- [ ] 实现晨间记录提醒
- [ ] 实现最佳时机提醒

### Step 4: 集成与测试 (2 小时)
- [ ] 更新 DreamLogApp.swift
- [ ] 更新 ContentView.swift / RootView.swift
- [ ] 更新 Info.plist
- [ ] 创建 DreamHealthIntegrationTests.swift
- [ ] 运行所有测试

### Step 5: 文档与优化 (1 小时)
- [ ] 创建 Phase 64 完成报告
- [ ] 更新 README.md
- [ ] 更新 NEXT_SESSION_PLAN.md
- [ ] 代码审查和优化

---

## 📝 验收标准

### 功能验收

- [ ] HealthKit 授权流程正常
- [ ] 睡眠数据正确同步
- [ ] 睡眠质量分析准确
- [ ] 梦境 - 睡眠关联分析合理
- [ ] 智能推荐有意义
- [ ] 仪表板 UI 美观流畅
- [ ] 提醒功能正常工作

### 技术验收

- [ ] 所有测试通过 (95%+ 覆盖率)
- [ ] 无 TODO/FIXME 标记
- [ ] 无强制解包
- [ ] 代码符合 Swift 规范
- [ ] 性能指标达标
- [ ] 内存管理正确

### 文档验收

- [ ] Phase 64 完成报告
- [ ] README.md 更新
- [ ] NEXT_SESSION_PLAN.md 更新
- [ ] 代码注释完整

---

## 🔗 相关资源

- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [HKSleepStageAnalysis](https://developer.apple.com/documentation/healthkit/hksleepstageanalysis)
- [Sleep Data Best Practices](https://developer.apple.com/documentation/healthkit/sleep_data)

---

## 📅 预计时间线

| 里程碑 | 预计时间 | 状态 |
|--------|----------|------|
| Phase 64 启动 | 2026-03-18 02:04 UTC | 📋 |
| 模型与服务完成 | 2026-03-18 04:00 UTC | ⏳ |
| UI 层完成 | 2026-03-18 06:00 UTC | ⏳ |
| 提醒服务完成 | 2026-03-18 07:00 UTC | ⏳ |
| 集成与测试完成 | 2026-03-18 09:00 UTC | ⏳ |
| Phase 64 完成 | 2026-03-18 10:00 UTC | ⏳ |

---

**Phase 64 计划创建完成** 🎉

下一步：开始实施 Phase 64 - 健康集成与睡眠追踪功能
