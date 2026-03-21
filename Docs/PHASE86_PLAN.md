# DreamLog Phase 86 开发计划 - 梦境音乐与氛围音景 🎵💤✨

**创建时间**: 2026-03-21 20:30 UTC  
**优先级**: 高  
**预计工作量**: 6-8 小时  
**分支**: dev  
**完成度**: 0% ⏳

---

## 📋 Phase 86 概述

Phase 86 将为 DreamLog 添加梦境音乐与氛围音景功能，根据梦境内容、情绪和主题生成或推荐个性化的背景音乐和氛围音效，帮助用户更好地回忆、放松或重新体验梦境。

### 核心价值

- 🎵 **梦境配乐** - 为每个梦境生成匹配的背景音乐
- 🌊 **氛围音景** - 根据梦境场景生成环境音 (雨声/海浪/森林等)
- 🧘 **冥想辅助** - 帮助放松和梦境回忆的音景
- 😴 **睡眠辅助** - 基于梦境主题的助眠音效
- 🎼 **个性化播放列表** - 根据情绪和偏好定制

---

## 🎯 核心功能

### 1. 梦境音乐生成与推荐

**功能描述**: 根据梦境的情绪、主题和内容，生成或推荐匹配的背景音乐。

**音乐类型**:
- **情绪匹配**: 平静/快乐/焦虑/悲伤/神秘/兴奋
- **主题匹配**: 飞行/水下/森林/城市/太空/奇幻
- **场景匹配**: 室内/室外/自然/都市/超现实
- **时间匹配**: 白天/夜晚/黄昏/黎明

**推荐算法**:
- 基于梦境情绪标签
- 基于梦境场景关键词
- 基于用户历史偏好
- 基于时间段 (白天/夜晚)

### 2. 氛围音景系统

**环境音类型** (20+ 种):
- **自然音**: 雨声/雷声/海浪/溪流/鸟鸣/风声/树叶沙沙
- **城市音**: 交通/人群/咖啡馆/地铁/雨夜城市
- **室内音**: 壁炉/时钟/键盘/翻书/空调
- **奇幻音**: 魔法/太空/梦境/冥想/空灵
- **白噪音**: 粉红噪音/棕色噪音/白噪音

**音景混合**:
- 支持多层音景叠加 (如：雨声 + 雷声 + 壁炉)
- 每层音量独立调节
- 预设混合模板 (暴风雨夜/宁静森林/海边日落等)

### 3. 睡眠辅助音景

**功能**:
- 渐入渐出 (fade in/out)
- 定时关闭 (15/30/60/90 分钟)
- 智能音量调节 (随时间降低)
- 与睡眠追踪集成

**预设场景**:
- 深度睡眠 (低频白噪音)
- 快速入睡 (渐进放松音景)
- 梦境诱导 (θ波双耳节拍)
- 夜间觉醒 (柔和引导音)

### 4. 梦境回忆辅助

**功能**:
- 播放梦境创建时的背景音景帮助回忆
- 基于梦境内容的音景提示
- 冥想引导音 (帮助进入放松状态)
- 双耳节拍 (binaural beats) 用于清醒梦诱导

### 5. 个性化播放列表

**播放列表类型**:
- **梦境配乐** - 基于单个梦境生成
- **情绪合集** - 相同情绪的梦境配乐
- **主题合集** - 相同主题的梦境配乐
- **每日推荐** - 根据当日状态推荐
- **助眠合集** - 睡前放松音景

**播放控制**:
- 播放/暂停/跳过
- 循环模式 (单曲/列表/随机)
- 收藏管理
- 下载离线播放

### 6. 音频导出与分享

**导出格式**:
- MP3 (通用格式)
- M4A (Apple 设备优化)
- WAV (无损质量)

**分享选项**:
- 导出梦境 + 配乐组合
- 分享播放列表
- 生成音频链接

---

## 📁 新增文件 (预估)

| 文件 | 行数 | 说明 |
|------|------|------|
| `DreamMusicModels.swift` | ~450 | 音乐数据模型 (曲目/音景/播放列表) |
| `DreamMusicService.swift` | ~650 | 音乐推荐与播放服务 |
| `DreamSoundscapeService.swift` | ~500 | 氛围音景生成与混合服务 |
| `DreamAudioPlayerService.swift` | ~400 | 音频播放控制服务 |
| `DreamMusicView.swift` | ~600 | 音乐播放器 UI 界面 |
| `DreamSoundscapeMixerView.swift` | ~450 | 音景混合器 UI |
| `DreamSleepSoundsView.swift` | ~400 | 睡眠音景 UI |
| `DreamMusicTests.swift` | ~500 | 单元测试 |
| **总计** | **~3,950** | |

---

## 🏗️ 技术架构

### 数据模型设计

```swift
// 音乐曲目
struct MusicTrack: Codable {
    var id: UUID
    var title: String
    var artist: String
    var duration: TimeInterval
    var mood: DreamEmotion?
    var themes: [String]
    var tags: [String]
    var audioURL: URL
    var isPremium: Bool
}

// 氛围音景
struct Soundscape: Codable {
    var id: UUID
    var name: String
    var category: SoundscapeCategory // 自然/城市/室内/奇幻/白噪音
    var layers: [SoundscapeLayer]
    var recommendedMoods: [DreamEmotion]
    var recommendedThemes: [String]
}

// 音景层
struct SoundscapeLayer: Codable {
    var id: UUID
    var soundId: String
    var volume: Float // 0.0 - 1.0
    var pan: Float // -1.0 (左) 到 1.0 (右)
    var fadeIn: TimeInterval
    var fadeOut: TimeInterval
}

// 播放列表
struct DreamPlaylist: Codable {
    var id: UUID
    var name: String
    var tracks: [MusicTrack]
    var soundscapes: [Soundscape]
    var createdDate: Date
    var mood: DreamEmotion?
    var theme: String?
}
```

### 服务层设计

```swift
// 音乐推荐服务
class DreamMusicService {
    func recommendMusic(for dream: Dream) async -> [MusicTrack]
    func getMusicByMood(_ mood: DreamEmotion) async -> [MusicTrack]
    func getMusicByTheme(_ theme: String) async -> [MusicTrack]
    func createPlaylist(for dreams: [Dream]) async -> DreamPlaylist
}

// 音景生成服务
class DreamSoundscapeService {
    func generateSoundscape(for dream: Dream) async -> Soundscape
    func getSoundscapeByScene(_ scene: String) async -> Soundscape
    func mixSoundscapes(_ soundscapes: [Soundscape]) async -> Soundscape
    func getSleepSoundscape() async -> Soundscape
}

// 音频播放服务
class DreamAudioPlayerService: ObservableObject {
    @Published var isPlaying: Bool
    @Published var currentTrack: MusicTrack?
    @Published var currentSoundscape: Soundscape?
    
    func play(_ track: MusicTrack)
    func play(_ soundscape: Soundscape)
    func pause()
    func stop()
    func setVolume(_ volume: Float)
    func scheduleSleepTimer(_ minutes: Int)
}
```

### UI 组件设计

```
┌─────────────────────────────────────────────────────────┐
│                   DreamMusicView                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Now Playing Card                    │   │
│  │  ┌─────────┐  梦境配乐 - 飞行之梦               │   │
│  │  │ 封面图   │  艺术家：DreamLog AI              │   │
│  │  │         │  ████████████░░░░  2:34 / 4:12    │   │
│  │  └─────────┘  ⏮️ ▶️ ⏭️  🔄  ❤️                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              推荐音景                            │   │
│  │  🌧️ 暴风雨夜  🌊 海边  🌲 森林  🔥 壁炉         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              播放列表                            │   │
│  │  📋 我的梦境配乐  📋 助眠合集  📋 情绪精选       │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 开发计划

### Session 1: 数据模型与基础服务 (3 小时)

- [ ] 创建 `DreamMusicModels.swift` (~450 行)
  - MusicTrack / Soundscape / SoundscapeLayer
  - DreamPlaylist / SoundscapeCategory
  - 枚举和辅助类型

- [ ] 创建 `DreamMusicService.swift` (~650 行)
  - 音乐推荐算法
  - 播放列表生成
  - 用户偏好学习

- [ ] 创建 `DreamSoundscapeService.swift` (~500 行)
  - 音景生成逻辑
  - 音景混合引擎
  - 预设模板

- [ ] 创建单元测试 (~300 行)

### Session 2: 音频播放与 UI 界面 (3 小时)

- [ ] 创建 `DreamAudioPlayerService.swift` (~400 行)
  - AVFoundation 集成
  - 播放控制
  - 音量管理
  - 定时关闭

- [ ] 创建 `DreamMusicView.swift` (~600 行)
  - 现在播放卡片
  - 推荐音景网格
  - 播放列表视图
  - 播放器控制

- [ ] 创建 `DreamSoundscapeMixerView.swift` (~450 行)
  - 音景层调节
  - 音量滑块
  - 预设保存

- [ ] 创建 `DreamSleepSoundsView.swift` (~400 行)
  - 睡眠音景选择
  - 定时器设置
  - 渐入渐出配置

- [ ] 创建单元测试 (~200 行)

### Session 3: 集成与优化 (2 小时)

- [ ] 集成到梦境详情页面
  - 添加"播放配乐"按钮
  - 梦境 - 音乐关联

- [ ] 集成到首页
  - 添加音乐卡片
  - 快速播放推荐

- [ ] 集成到导航
  - 添加到"成长"或"工具"菜单

- [ ] 性能优化
  - 音频缓存
  - 懒加载
  - 内存管理

- [ ] 完整测试 (~500 行)
- [ ] 文档更新

---

## ✅ 验收标准

### 功能完整性

- [ ] 17+ 种氛围音景可用
- [ ] 音乐推荐算法工作正常
- [ ] 音景混合功能正常
- [ ] 睡眠定时器工作
- [ ] 播放列表创建和管理
- [ ] 音频导出功能

### 代码质量

- [ ] 0 TODO / 0 FIXME
- [ ] 0 强制解包 (非测试)
- [ ] 0 重复类型定义
- [ ] Swift 语法检查通过
- [ ] 括号匹配 100%

### 测试覆盖

- [ ] 40+ 测试用例
- [ ] 模型测试
- [ ] 服务层测试
- [ ] UI 测试
- [ ] 集成测试
- [ ] 测试覆盖率：95%+

### 用户体验

- [ ] 播放控制响应迅速 (<100ms)
- [ ] 音景切换平滑 (无爆音)
- [ ] UI 流畅 (60fps)
- [ ] 无障碍支持 (VoiceOver)
- [ ] 深色模式适配

---

## 🎯 预期成果

**新增代码**: ~3,950 行  
**测试代码**: ~500 行  
**总新增**: ~4,450 行

**功能亮点**:
- 🎵 智能梦境配乐推荐
- 🌊 20+ 种氛围音景
- 🎚️ 多层音景混合
- 😴 睡眠辅助音景
- 📋 个性化播放列表
- 📤 音频导出分享

**用户价值**:
- 增强梦境回忆体验
- 提供放松和冥想辅助
- 改善睡眠质量
- 创造独特的梦境回顾体验

---

## 📝 备注

### 音频资源

**方案 A: 内置音频** (推荐 MVP)
- 使用免版税音频库
- 打包在 App 内
- 优点：离线可用，无依赖
- 缺点：App 体积增大

**方案 B: 流媒体服务** (后续增强)
- 集成 Spotify/Apple Music API
- 优点：海量曲库
- 缺点：需要网络和授权

**方案 C: AI 生成音乐** (未来愿景)
- 使用 AI 模型实时生成
- 优点：完全个性化
- 缺点：技术复杂，计算资源需求高

**MVP 建议**: 方案 A (内置 20-30 首免版税曲目 + 10+ 种音景)

### 技术依赖

- AVFoundation (音频播放)
- AVAudioEngine (音景混合)
- CoreAudio (音频处理)
- UserNotifications (定时关闭通知)

### 后续增强 (Phase 86+)

- [ ] AI 生成音乐集成
- [ ] 流媒体服务集成
- [ ] 社交分享 (分享配乐)
- [ ] 社区音景库
- [ ] 音频可视化 (频谱分析)
- [ ] 与 HomeKit 集成 (智能家居音景)

---

**Phase 86 预计完成时间**: 2026-03-22 08:00 UTC  
**详细进度**: 参见后续 Cron 报告和完成报告
