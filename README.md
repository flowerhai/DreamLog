# DreamLog 🌙 - AI 梦境日记

> 记录你的梦，发现潜意识的秘密

[![Platform](https://img.shields.io/badge/platform-iOS%2016+-blue.svg)](https://developer.apple.com/ios)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![AI](https://img.shields.io/badge/AI-Powered-purple.svg)](https://developer.apple.com/machine-learning/)

---

## 📱 应用介绍

DreamLog 是一款智能梦境记录应用，帮你捕捉醒来即逝的梦境，用 AI 解析其中的象征意义和隐藏模式。

每个人都会做梦，但 95% 的梦在醒来 5 分钟内被遗忘。DreamLog 帮你：
- ✨ **快速记录** - 语音输入，30 秒完成
- 🧠 **AI 解析** - 发现梦境背后的含义
- 📊 **模式洞察** - 发现重复出现的梦境主题
- 🎨 **梦境画廊** - AI 绘画让梦境可视化

---

## ✨ 核心功能

### 🎤 语音记录
- 按住说话，自动转文字
- AI 自动整理和润色
- 支持文字补充编辑

### 🧠 AI 梦境解析
- 分析梦境象征意义
- 关联情绪和关键词
- 提供心理学解读

### 📊 洞察分析
- 梦境统计概览
- 情绪分布图表
- 热门标签排行
- 时间段分析
- 梦境模式发现

### 🎨 梦境画廊
- AI 绘画生成
- 梦境可视化
- 个人梦境博物馆

### 🏷️ 标签系统
- 智能标签推荐
- 自定义标签
- 按标签筛选

### 😊 情绪追踪
- 10 种基础情绪
- 多情绪标记
- 情绪趋势分析

### 🌙 清醒梦支持
- 清醒梦标记
- 清醒梦训练技巧
- 清醒梦统计

---

## 🎨 界面预览

```
┌─────────────────────────┐
│  DreamLog 🌙            │
│                         │
│  昨晚你梦见了什么？     │
│                         │
│    🎤 按住说话          │
│                         │
│  最近关键词：           │
│  🌊 水  ✈️ 飞行  🏃 追逐│
└─────────────────────────┘
```

---

## 🚀 快速开始

### 系统要求

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/YOUR_USERNAME/DreamLog.git
cd DreamLog
```

2. **打开项目**
```bash
open DreamLog.xcodeproj
```

3. **配置 Team**
- 选择你的开发 Team
- 修改 Bundle Identifier

4. **运行**
```
⌘R 运行到模拟器或真机
```

---

## 📋 开发计划

### Phase 1 - 记录版 ✅

- [x] 语音/文字输入
- [x] 梦境列表
- [x] 标签系统
- [x] 情绪标记
- [x] 数据统计

### Phase 2 - AI 版 🚧

- [x] AI 梦境解析
- [x] 模式分析
- [x] 关键词提取
- [ ] 智能推荐标签
- [ ] 梦境相似度匹配

### Phase 3 - 视觉版 ⏳

- [ ] AI 绘画集成
- [ ] 梦境画廊
- [ ] 分享功能
- [ ] 梦境壁纸生成

### Phase 4 - 进阶功能 ⏳

- [ ] iCloud 同步
- [ ] 清醒梦训练
- [ ] 梦境词典
- [ ] 社区分享 (匿名)
- [ ] Apple Watch 应用

---

## 🏗️ 项目结构

```
DreamLog/
├── Sources/
│   ├── DreamLogApp.swift       # App 入口
│   ├── ContentView.swift        # 主容器
│   ├── HomeView.swift           # 首页
│   ├── RecordView.swift         # 记录页面
│   ├── InsightsView.swift       # 洞察页面
│   ├── GalleryView.swift        # 画廊页面
│   ├── SettingsView.swift       # 设置页面
│   ├── Dream.swift              # 数据模型
│   ├── DreamStore.swift         # 数据存储
│   ├── SpeechService.swift      # 语音服务
│   ├── AIService.swift          # AI 服务
│   └── Theme.swift              # 主题配置
│
├── Docs/
│   ├── Concept.md              # 概念设计
│   └── UI_Design.md            # UI 规范
│
└── README.md                   # 项目说明
```

---

## 🛠️ 技术栈

| 技术 | 用途 |
|------|------|
| **SwiftUI** | 用户界面 |
| **SwiftData** | 数据持久化 |
| **Speech Framework** | 语音识别 |
| **Natural Language** | 文本分析 |
| **Core ML** | 情绪检测 |
| **UserNotifications** | 提醒通知 |

---

## 🧠 AI 功能

### 梦境解析引擎

基于心理学和象征学知识库：

```swift
- 弗洛伊德释梦理论
- 荣格原型理论
- 现代认知心理学
- 跨文化梦境研究
```

### 常见梦境象征

| 元素 | 含义 |
|------|------|
| 💧 水 | 情绪、潜意识 |
| ✈️ 飞行 | 自由、解脱 |
| 🏃 追逐 | 逃避、压力 |
| 🦷 牙齿 | 变化、成长 |
| 🏠 房子 | 自我、心灵 |
| 🚪 门 | 机会、选择 |

---

## 🔒 隐私保护

- **本地优先** - 数据默认存储在本地
- **端到端加密** - iCloud 同步时加密
- **匿名分享** - 可选匿名分享到社区
- **完全删除** - 一键删除所有数据

---

## 📊 数据模型

### Dream (梦境)

```swift
- id: UUID
- title: String
- content: String
- tags: [String]
- emotions: [Emotion]
- clarity: Int (1-5)
- intensity: Int (1-5)
- isLucid: Bool
- aiAnalysis: String?
```

### Emotion (情绪)

```swift
- 平静、快乐、焦虑、恐惧
- 困惑、兴奋、悲伤、愤怒
- 惊讶、中性
```

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 开启 Pull Request

---

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件

---

## 📬 联系方式

- 👤 开发者：starry
- 📧 邮箱：1559743577@qq.com
- 🐛 问题反馈：[GitHub Issues](https://github.com/YOUR_USERNAME/DreamLog/issues)

---

<div align="center">

**Made with ❤️ and 🌙 by DreamLog Team**

[⭐ Star this repo](https://github.com/YOUR_USERNAME/DreamLog)

</div>
