# 梦境音乐功能文档

## 概述

梦境音乐功能是 DreamLog Phase 9 的核心特性，通过 AI 分析梦境内容，自动生成匹配的 ambient 音乐，为每个梦境创建专属"原声带"。

## 功能特性

### 🎵 核心功能

1. **AI 情绪分析**
   - 分析梦境的情绪标签
   - 根据情绪决定音乐基调
   - 支持 8 种音乐情绪

2. **智能乐器选择**
   - 基于梦境内容关键词
   - 自动匹配相关乐器/音效
   - 支持 12 种乐器类型

3. **音乐生成**
   - 5 步可视化生成流程
   - 实时进度显示
   - 生成音频层配置

4. **音乐库管理**
   - 保存生成的音乐
   - 收藏功能
   - 删除管理

5. **内置播放器**
   - 播放/暂停/停止
   - 进度条控制
   - 10 秒进退功能

---

## 音乐情绪类型

| 情绪 | 图标 | 颜色 | 描述 | 适用场景 |
|------|------|------|------|----------|
| 平静 🌙 | moon.fill | #5B91F5 | 宁静祥和，如月光般温柔 | 平静的梦境、睡前回顾 |
| 神秘 👁️ | eye.fill | #8B5CF6 | 深邃神秘，探索未知 | 神秘/超自然梦境 |
| 梦幻 ✨ | sparkles | #EC4899 | 飘渺梦幻，如入仙境 | 清晰的清醒梦 |
| 活力 ⚡ | bolt.fill | #F59E0B | 充满活力，动感十足 | 兴奋/活跃的梦境 |
| 忧郁 🌧️ | cloud.rain.fill | #64748B | 略带忧伤，深情内敛 | 悲伤/失落的梦境 |
| 空灵 ☁️ | cloud.sun.fill | #06B6D4 | 超凡脱俗，空灵飘渺 | 灵性/超越性梦境 |
| 紧张 ⚠️ | bolt.horizontal.fill | #DC2626 | 紧张刺激，扣人心弦 | 焦虑/恐惧的梦境 |
| 欢快 ☀️ | sun.max.fill | #10B981 | 欢快明亮，充满喜悦 | 快乐的梦境 |

---

## 乐器类型

| 乐器 | 图标 | 说明 |
|------|------|------|
| 钢琴 🎹 | music.note | 基础旋律乐器 |
| 弦乐 🎻 | guitars.fill | 丰富和声 |
| 长笛 🌬️ | wind | 轻盈高音 |
| 竖琴 🏠 | music.note.house | 梦幻音色 |
| 合成器 〰️ | waveform | 现代电子音色 |
| 氛围 Pad ☁️ | cloud.fill | 背景氛围 |
| 自然音效 🍃 | leaf.fill | 自然环境声 |
| 颂钵 🔔 | bell.fill | 冥想音色 |
| 风铃 ❄️ | wind.snow | 清脆装饰音 |
| 海浪 🌊 | water.waves | 水环境音效 |
| 雨声 🌧️ | cloud.rain.fill | 降雨音效 |
| 森林氛围 🌲 | tree.fill | 森林环境声 |

---

## 节奏类型

| 节奏 | BPM 范围 | 图标 | 说明 |
|------|----------|------|------|
| 极慢 | 40-60 | tortoise | 深度放松，冥想状态 |
| 慢速 | 60-80 | hare | 平静舒缓 |
| 中速 | 80-100 | metronome | 自然节奏 |
| 中快 | 100-120 | speedometer | 轻度活力 |
| 快速 | 120-140 | bolt.fill | 充满活力 |

---

## 使用流程

### 1. 快速生成

```
首页 → 选择梦境 → 点击"生成梦境音乐" → 等待生成 → 播放/保存
```

### 2. 音乐库浏览

```
底部导航 → 音乐 → 浏览音乐库 → 点击播放
```

### 3. 按情绪浏览

```
音乐页面 → 按情绪浏览 → 选择情绪 → 查看该情绪的音乐
```

### 4. 收藏管理

```
音乐列表 → 点击心形图标 → 收藏/取消收藏
音乐页面 → 收藏区域 → 查看收藏的音乐
```

---

## 技术实现

### 数据模型

```swift
struct DreamMusic: Identifiable, Codable {
    var id: UUID
    var dreamId: UUID
    var title: String
    var duration: TimeInterval
    var mood: DreamMusicMood
    var tempo: DreamMusicTempo
    var instruments: [DreamMusicInstrument]
    var audioLayers: [AudioLayer]
    var createdAt: Date
    var isFavorite: Bool
    var filePath: String?
}
```

### 生成流程

1. **情绪分析** (20%)
   - 读取梦境情绪标签
   - 映射到音乐情绪

2. **乐器选择** (40%)
   - 分析梦境内容关键词
   - 选择匹配的乐器

3. **音频层生成** (60%)
   - 配置音量/声像/混响/延迟
   - 创建多层音频配置

4. **音乐对象创建** (80%)
   - 生成标题
   - 设置时长和节奏

5. **完成** (100%)
   - 返回音乐对象
   - 可保存或播放

### 关键词映射

```swift
// 内容关键词 → 乐器
"水/海/河/雨" → .oceanWaves
"森林/树/自然" → .forestAmbience
"风/天空/云" → .windChimes
"冥想/禅/宁静" → .singingBowl
```

### 情绪映射

```swift
// 梦境情绪 → 音乐情绪
"平静/快乐" → .peaceful
"焦虑/恐惧" → .tense
"悲伤" → .melancholic
"兴奋" → .energetic
"惊讶" → .mysterious
清醒梦 → .ethereal
高清晰度 (≥4) → .dreamy
默认 → .peaceful
```

---

## 文件结构

```
DreamLog/
├── DreamMusicService.swift      # 音乐生成服务
│   ├── DreamMusic 模型
│   ├── DreamMusicMood 情绪枚举
│   ├── DreamMusicTempo 节奏枚举
│   ├── DreamMusicInstrument 乐器枚举
│   ├── AudioLayer 音频层结构
│   └── DreamMusicService 服务类
│
├── DreamMusicView.swift         # 音乐界面
│   ├── DreamMusicView 主视图
│   ├── RecentDreamsPicker 梦境选择器
│   ├── MusicListItemView 列表项
│   ├── MusicCardView 卡片视图
│   ├── MoodCardView 情绪卡片
│   ├── DreamMusicGeneratorView 生成器视图
│   └── DreamMusicPlayerView 播放器视图
│
└── ContentView.swift            # 主容器 (已添加音乐标签页)
```

---

## 未来扩展

### Phase 9.5 - 音频合成 (待开发)

- [ ] 使用 AVAudioEngine 实现真实音频合成
- [ ] 集成 AudioKit 音频处理库
- [ ] 支持实时音频效果处理
- [ ] 导出 AAC/MP3 音频文件

### Phase 9.6 - 社交分享 (待开发)

- [ ] 分享音乐到社区
- [ ] 音乐播放列表
- [ ] 好友音乐推荐
- [ ] 音乐评论和点赞

### Phase 9.7 - 高级功能 (待开发)

- [ ] 睡眠定时关闭
- [ ] 与冥想功能深度集成
- [ ] 音乐情绪编辑
- [ ] 自定义乐器配置
- [ ] 音乐模板市场

---

## API 参考

### DreamMusicService

```swift
// 单例
static let shared: DreamMusicService

// 生成音乐
func generateMusic(for dream: Dream) async -> DreamMusic?

// 播放控制
func play(_ music: DreamMusic)
func pause()
func stop()
func seek(to time: TimeInterval)

// 音乐库管理
func saveMusic(_ music: DreamMusic)
func deleteMusic(_ music: DreamMusic)
func toggleFavorite(_ music: DreamMusic)

// 批量生成
func generatePlaylist(for dreams: [Dream]) async -> [DreamMusic]
```

### 发布属性

```swift
@Published var isGenerating: Bool      // 是否正在生成
@Published var generationProgress: Double  // 生成进度 (0.0-1.0)
@Published var currentMusic: DreamMusic?   // 当前生成的音乐
@Published var errorMessage: String?       // 错误信息
@Published var isPlaying: Bool             // 是否正在播放
@Published var currentTime: TimeInterval   // 当前播放时间
@Published var musicLibrary: [DreamMusic]  // 音乐库
```

---

## 注意事项

1. **音频文件**: 当前版本生成的是音频配置，实际音频合成需要 AVAudioEngine 实现
2. **性能**: 生成过程使用 async/await，不会阻塞 UI
3. **存储**: 音乐库保存在 UserDefaults，大量音乐建议使用文件系统
4. **内存**: 播放器使用 Timer，注意内存管理
5. **扩展性**: 模板系统支持轻松添加新的情绪和乐器组合

---

## 测试建议

1. **情绪映射测试**: 验证不同情绪标签生成正确的音乐情绪
2. **关键词识别测试**: 验证梦境内容关键词正确映射到乐器
3. **生成流程测试**: 验证 5 步生成流程的进度显示
4. **播放器测试**: 验证播放/暂停/进度控制功能
5. **存储测试**: 验证音乐保存/加载/删除功能
6. **收藏测试**: 验证收藏功能正常工作

---

## 版本历史

- **v1.0 (2026-03-08)**: Phase 9 初始版本
  - ✅ 音乐生成服务
  - ✅ 音乐界面
  - ✅ 播放器基础功能
  - ✅ 音乐库管理
  - ⏳ 真实音频合成 (待开发)

---

<div align="center">

**DreamLog 🎵 - 为每个梦境配乐**

Made with ❤️ by DreamLog Team

</div>
