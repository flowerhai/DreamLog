# 梦境朗读功能文档

## 📋 概述

梦境朗读功能使用文本转语音 (TTS) 技术，将用户记录的梦境内容朗读出来。这个功能特别适合：

- **睡前回顾** - 闭上眼睛聆听自己的梦境
- **无障碍访问** - 为视障用户提供访问支持
- **多任务场景** - 边做其他事情边"听"梦境
- **语言学习** - 帮助非母语用户理解内容

## 🎯 功能特性

### 核心功能

- ✅ 播放/暂停/停止控制
- ✅ 语速调节 (0.3x - 1.0x)
- ✅ 音调调节 (0.5x - 2.0x)
- ✅ 音量调节 (10% - 100%)
- ✅ 多种语音选择 (中文/英文)
- ✅ 语音预览功能
- ✅ 波形动画视觉反馈
- ✅ 自动停止清理

### 用户体验

- **梦境详情页集成** - 在梦境内容下方直接播放
- **设置页面配置** - 个性化语音参数
- **实时状态显示** - 播放中/已暂停/已停止
- **优雅的资源管理** - 页面消失时自动停止播放

## 🏗️ 技术实现

### 文件结构

```
DreamLog/
├── SpeechSynthesisService.swift    # TTS 服务核心
├── DreamDetailView.swift           # 梦境详情页 (集成播放器)
├── SettingsView.swift              # 设置页 (语音设置入口)
└── Docs/
    └── VoicePlayback.md            # 本文档
```

### 核心技术

```swift
import AVFoundation
import SwiftUI

// 使用 AVSpeechSynthesizer 进行语音合成
class SpeechSynthesisService: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        let utterance = AVSpeechSynthesisUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = configuredRate
        utterance.pitchMultiplier = configuredPitch
        utterance.volume = configuredVolume
        synthesizer.speak(utterance)
    }
}
```

### 数据持久化

语音配置保存在 `UserDefaults` 中：

```swift
struct SpeechConfig: Codable {
    var voiceIdentifier: String?
    var rate: Float
    var pitchMultiplier: Float
    var volume: Float
    var language: String
}
```

## 🎨 UI 组件

### AudioPlaybackSection

梦境详情页的播放器组件：

```swift
struct AudioPlaybackSection: View {
    let dreamContent: String
    @StateObject private var speechService = SpeechSynthesisService.shared
    
    var body: some View {
        // 播放控制按钮
        // 状态指示
        // 波形动画
    }
}
```

### SpeechSettingsView

语音设置页面：

```swift
struct SpeechSettingsView: View {
    @StateObject private var speechService = SpeechSynthesisService.shared
    
    var body: some View {
        Form {
            // 语速滑块
            // 音调滑块
            // 音量滑块
            // 语音选择器
            // 语音预览按钮
        }
    }
}
```

## 📱 使用指南

### 播放梦境

1. 打开任意梦境详情页面
2. 找到 "🎧 聆听梦境" 区域
3. 点击 ▶️ 播放按钮开始朗读
4. 点击 ⏸️ 暂停，点击 ⏹️ 停止

### 配置语音

1. 进入 设置 → 语音播放
2. 调整语速、音调、音量
3. 选择喜欢的语音
4. 点击 "预览" 试听效果
5. 设置自动保存

### 推荐配置

**中文梦境**：
- 语速：0.5x (舒缓)
- 音调：1.0x (自然)
- 音量：80%

**英文梦境**：
- 语速：0.6x
- 音调：1.0x
- 音量：80%

**睡前聆听**：
- 语速：0.4x (更慢更放松)
- 音调：0.9x (更低沉)
- 音量：50% (轻柔)

## 🔧 自定义扩展

### 添加新语音

系统会自动加载所有可用的中文和英文语音：

```swift
func loadAvailableVoices() {
    availableVoices = AVSpeechSynthesisVoice.speechVoices()
        .filter { voice in
            voice.language.hasPrefix("zh") || 
            voice.language.hasPrefix("en")
        }
}
```

### 支持更多语言

修改过滤器以支持其他语言：

```swift
.filter { voice in
    ["zh", "en", "ja", "ko", "fr", "de"]
        .contains { voice.language.hasPrefix($0) }
}
```

### 添加进度回调

AVSpeechSynthesizer 不直接提供进度，但可以通过 delegate 实现：

```swift
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, 
                       willSpeakRangeOfSpeechString characterRange: NSRange, 
                       utterance: AVSpeechSynthesisUtterance) {
    // 更新进度 UI
}
```

## 🐛 故障排除

### 问题：没有声音

**解决方案**：
1. 检查设备音量
2. 确认未连接蓝牙耳机
3. 重启应用
4. 检查系统 TTS 设置

### 问题：语音不自然

**解决方案**：
1. 尝试不同的语音
2. 降低语速
3. 调整音调

### 问题：播放中断

**解决方案**：
1. 检查是否有其他音频应用
2. 确保应用在前台运行
3. 重启设备

## 📊 性能考虑

- **内存占用**：< 1MB
- **CPU 使用**：播放时 < 5%
- **启动时间**：< 100ms
- **配置加载**：即时

## 🔒 隐私保护

- 所有语音合成在设备本地完成
- 不需要网络连接
- 不上传任何梦境内容
- 配置数据仅存储在本地

## 🚀 未来计划

- [ ] 支持导出梦境音频文件
- [ ] 添加背景音乐选项
- [ ] 支持多语言混合朗读
- [ ] 实现播放列表功能
- [ ] 添加睡眠定时器
- [ ] 支持 CarPlay 播放

## 📝 版本历史

### v1.0 (2026-03-07)
- ✅ 初始版本发布
- ✅ 基础播放控制
- ✅ 语音配置
- ✅ UI 集成

---

**Made with ❤️ by DreamLog Team**
