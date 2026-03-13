# Phase 33 计划 - iOS 小组件与锁屏增强 📱✨

**创建日期**: 2026 年 3 月 13 日  
**预计完成时间**: 2-3 小时  
**优先级**: 高

---

## 📋 任务概述

增强 DreamLog 的 iOS 小组件和锁屏体验，提供更丰富的快捷功能和个性化选项。

### 核心目标

1. **锁屏小组件** - iOS 16+ 锁屏快捷查看
2. **交互式小组件** - 直接操作无需打开 App
3. **更多尺寸选择** - 小/中/大三种尺寸
4. **实时活动** - 梦境记录提醒/连续记录激励
5. **个性化主题** - 8 种精美主题同步

---

## 🎯 功能列表

### 1. 锁屏小组件 (Lock Screen Widgets)

- [ ] **快速记录按钮**
  - 一键开始语音记录
  - Haptic 反馈确认
  - 后台录音支持

- [ ] **今日梦境统计**
  - 本周记录天数
  - 连续记录天数
  - 本月梦境总数

- [ ] **梦境名言**
  - 随机显示用户梦境片段
  - 精美排版
  - 可配置显示来源

- [ ] **快速情绪标记**
  - 5 种常用情绪快捷标记
  - 一键记录当前心情

### 2. 交互式小组件 (Interactive Widgets)

- [ ] **点赞/收藏操作**
  - 直接在小组件点赞梦境
  - 收藏常用梦境

- [ ] **标签快捷筛选**
  - 点击标签直接筛选
  - 支持 3 个常用标签

- [ ] **语音记录快捷方式**
  - 长按录音
  - 松开停止
  - 自动保存

### 3. 新增小组件尺寸

- [ ] **小型 (Small)**
  - 快速记录按钮
  - 今日统计

- [ ] **中型 (Medium)**
  - 梦境列表预览
  - 统计图表

- [ ] **大型 (Large)**
  - 完整梦境画廊
  - 详细统计分析
  - 热力图展示

### 4. 实时活动 (Live Activities)

- [ ] **梦境记录提醒**
  - 睡前提醒记录
  - 晨间提醒回顾

- [ ] **连续记录激励**
  - 显示连续记录天数
  - 达成目标通知

- [ ] **梦境挑战**
  - 每周记录目标
  - 进度实时显示

### 5. 个性化增强

- [ ] **主题同步**
  - 8 种主题自动同步
  - 独立小组件主题配置

- [ ] **自定义布局**
  - 选择显示内容
  - 调整元素位置

- [ ] **智能推荐**
  - 根据使用习惯推荐布局
  - 自动优化显示内容

---

## 📦 新增文件

### 数据模型

1. **DreamWidgetModels.swift** (~200 行)
   - WidgetConfiguration
   - WidgetTheme
   - WidgetLayout
   - WidgetIntent

### 锁屏小组件

2. **DreamLockScreenWidgets.swift** (~350 行)
   - QuickRecordWidget
   - StatsWidget
   - QuoteWidget
   - MoodWidget

### 交互式小组件

3. **DreamInteractiveWidgets.swift** (~400 行)
   - LikeButtonWidget
   - TagFilterWidget
   - VoiceRecordWidget

### 实时活动

4. **DreamLiveActivities.swift** (~300 行)
   - RecordReminderActivity
   - StreakActivity
   - ChallengeActivity

### 配置界面

5. **DreamWidgetConfigurationView.swift** (~250 行)
   - 主题选择
   - 布局配置
   - 内容筛选

### 服务层

6. **DreamWidgetService.swift** (~350 行)
   - 数据提供
   - 状态管理
   - 意图处理

### 单元测试

7. **DreamLogTests/DreamWidgetTests.swift** (~400 行)
   - 模型测试
   - 服务测试
   - 意图测试

---

## 🎨 UI 设计

### 锁屏小组件样式

```
┌─────────────────┐
│ 🌙 DreamLog     │
│                 │
│ [🎤 记录]       │
│                 │
│ 连续 7 天 🔥     │
└─────────────────┘
```

### 交互式小组件样式

```
┌─────────────────────────┐
│ 🌙 梦境社区             │
│                         │
│ ┌─────┐ ┌─────┐ ┌─────┐│
│ │飞行 │ │追逐 │ │水   ││
│ └─────┘ └─────┘ └─────┘│
│                         │
│ [👍 128] [⭐ 收藏]      │
└─────────────────────────┘
```

---

## 🔧 技术实现

### 1. WidgetKit 2.0

```swift
import WidgetKit

@main
struct DreamLogWidgets: WidgetBundle {
    var body: some WidgetBundle {
        // 锁屏小组件
        DreamLockScreenWidgets()
        // 交互式小组件
        DreamInteractiveWidgets()
        // 实时活动
        DreamLiveActivities()
    }
}
```

### 2. App Intent

```swift
struct QuickRecordIntent: AppIntent {
    static var title: String = "快速记录梦境"
    
    func perform() async throws -> some IntentResult {
        // 启动录音
        await DreamService.shared.startRecording()
        return .result()
    }
}
```

### 3. ActivityKit

```swift
import ActivityKit

struct DreamRecordAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var streakDays: Int
        var lastRecordDate: Date
    }
}
```

---

## 🧪 测试计划

### 单元测试

- [ ] 数据模型测试
- [ ] 服务层测试
- [ ] 意图处理测试
- [ ] 配置编码/解码测试

### UI 测试

- [ ] 锁屏小组件渲染
- [ ] 交互式小组件操作
- [ ] 实时活动更新
- [ ] 主题切换测试

### 兼容性测试

- [ ] iOS 16.0+ 锁屏小组件
- [ ] iOS 17.0+ 交互式小组件
- [ ] iOS 16.1+ 实时活动
- [ ] 不同设备尺寸

---

## 📊 验收标准

- [ ] 所有锁屏小组件正常显示
- [ ] 交互式小组件操作响应
- [ ] 实时活动正确更新
- [ ] 主题同步功能正常
- [ ] 单元测试覆盖率 > 95%
- [ ] 无明显性能问题
- [ ] 文档完整

---

## 📝 Git 提交计划

```bash
# Phase 33 完成提交
feat(phase33): iOS 小组件与锁屏增强 - 锁屏小组件/交互式小组件/实时活动/主题同步 ✨

新增功能:
- 锁屏小组件 (4 种)
- 交互式小组件 (3 种)
- 实时活动 (3 种)
- 8 种主题同步
- 自定义布局配置

总新增代码：~2250 行
Phase 33 完成度：100%
```

---

## 🚀 后续优化建议

1. **更多小组件类型**
   - 梦境地图小组件
   - AI 解析小组件
   - 音乐播放小组件

2. **高级交互**
   - 3D Touch 快捷操作
   - 手势控制

3. **个性化 AI**
   - 基于 AI 推荐小组件内容
   - 智能布局优化

---

## ⏱️ 时间估算

| 任务 | 预计时间 |
|------|----------|
| 数据模型 | 20 分钟 |
| 锁屏小组件 | 40 分钟 |
| 交互式小组件 | 45 分钟 |
| 实时活动 | 35 分钟 |
| 配置界面 | 25 分钟 |
| 服务层 | 30 分钟 |
| 单元测试 | 30 分钟 |
| 文档更新 | 15 分钟 |
| **总计** | **~4 小时** |

---

**Phase 33 开始时间**: 2026-03-13 16:12 UTC
