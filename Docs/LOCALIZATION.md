# DreamLog 本地化指南 🌍

## 概述

DreamLog 支持多语言本地化，目前支持:
- 🇨🇳 简体中文 (zh-Hans)
- 🇺🇸 英语 (en)

## 文件结构

```
DreamLog/Resources/
├── Localizable.swift          # 本地化助手 (集中管理所有字符串)
├── zh-Hans.lproj/
│   └── Localizable.strings    # 中文翻译
└── en.lproj/
    └── Localizable.strings    # 英文翻译
```

## 使用方法

### 1. 在代码中使用

```swift
// 旧方式 (不推荐)
Text("保存")

// 新方式 (推荐)
Text(L.save)

// 带格式化
Text(F.date(dream.timestamp))
Text(F.relativeDate(dream.timestamp))
```

### 2. 添加新语言

1. 创建新的 `.lproj` 文件夹:
```bash
mkdir -p DreamLog/Resources/ja.lproj
```

2. 复制 `Localizable.strings` 并翻译:
```bash
cp en.lproj/Localizable.strings ja.lproj/Localizable.strings
```

3. 翻译所有字符串

### 3. 添加新字符串

1. 在 `Localizable.swift` 中添加:
```swift
static let myNewString = NSLocalizedString("myNewKey", comment: "描述用途")
```

2. 在所有语言的 `Localizable.strings` 中添加:
```
// zh-Hans.lproj/Localizable.strings
"myNewKey" = "中文翻译";

// en.lproj/Localizable.strings
"myNewKey" = "English translation";
```

## 本地化最佳实践

### ✅ 推荐

- 使用 `L.*` 助手类访问所有字符串
- 为每个字符串提供清晰的注释
- 保持键名有意义 (使用 camelCase)
- 在添加功能时同时添加所有语言翻译

### ❌ 避免

- 硬编码文本字符串
- 使用无意义的键名 (如 "string1", "text2")
- 只添加一种语言
- 在字符串中拼接变量 (使用格式化)

## 格式化支持

### 日期格式化

```swift
// 简单日期
Text(F.date(dream.timestamp))  // "2026 年 3 月 6 日"

// 完整日期时间
Text(F.dateTime(dream.timestamp))  // "2026/3/6 14:30"

// 相对日期
Text(F.relativeDate(dream.timestamp))  // "2 小时前"
```

### 数字格式化

```swift
Text(F.number(dreamCount))  // "1,234"
```

## 测试本地化

### 在模拟器中测试

1. 打开 Xcode
2. 编辑 Scheme → Options → Application Language
3. 选择要测试的语言
4. 运行应用

### 命令行测试

```bash
# 查看当前语言
defaults read -g AppleLanguages

# 临时设置为英文
defaults write -g AppleLanguages '("en")'

# 临时设置为中文
defaults write -g AppleLanguages '("zh-Hans")'

# 恢复默认
defaults delete -g AppleLanguages
```

## 翻译检查清单

在发布新版本前，检查:

- [ ] 所有新字符串都已翻译
- [ ] 翻译准确且自然
- [ ] 没有硬编码的文本
- [ ] 日期/数字格式化正确
- [ ] 特殊字符正确显示
- [ ] 长文本不会溢出 UI

## 贡献翻译

欢迎贡献更多语言翻译！

1. Fork 项目
2. 创建新的 `.lproj` 文件夹
3. 翻译所有字符串
4. 提交 Pull Request

## 资源

- [Apple 本地化指南](https://developer.apple.com/localization/)
- [ NSLocalizedString 文档](https://developer.apple.com/documentation/foundation/nslocalizedstring)

---

最后更新：2026-03-06
