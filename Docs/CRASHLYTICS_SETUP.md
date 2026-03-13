# Crashlytics 集成指南 📊

> 实时崩溃监控与性能追踪

**Phase 30.6 - 数据分析与监控**  
**优先级**: 🔴 高  
**预计时间**: 1 小时

---

## 📋 集成步骤

### 1. 添加 Firebase SDK

#### 方法 A: Swift Package Manager (推荐)

1. 在 Xcode 中选择 `File > Add Package Dependencies...`
2. 输入：`https://github.com/firebase/firebase-ios-sdk`
3. 选择以下组件：
   - `FirebaseCrashlytics`
   - `FirebaseAnalytics` (可选)
   - `FirebasePerformance` (可选)

#### 方法 B: CocoaPods

```ruby
# Podfile
platform :ios, '16.0'

target 'DreamLog' do
  use_frameworks!
  
  pod 'FirebaseCrashlytics'
  pod 'FirebaseAnalytics'
end
```

然后运行：
```bash
pod install
```

---

### 2. 配置 Firebase

#### 2.1 创建 Firebase 项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击 "添加项目"
3. 项目名称：`DreamLog`
4. 启用/禁用 Google Analytics（可选）
5. 创建项目

#### 2.2 添加 iOS 应用

1. 在 Firebase 控制台点击 "添加应用" > iOS
2. 输入 Bundle ID：`com.dreamlog.app` (或你的实际 Bundle ID)
3. 下载 `GoogleService-Info.plist`
4. 将文件拖入 Xcode 项目（确保 "Copy items if needed" 被勾选）

#### 2.3 初始化 Firebase

在 `DreamLogApp.swift` 中添加：

```swift
import FirebaseCore
import FirebaseCrashlytics

@main
struct DreamLogApp: App {
    init() {
        FirebaseApp.configure()
        
        // 配置 Crashlytics
        #if DEBUG
        // 调试模式下启用未捕获异常追踪
        Crashlytics.crashlytics().isCrashlyticsCollectionEnabled = true
        #else
        // 发布模式下自动收集崩溃
        Crashlytics.crashlytics().isCrashlyticsCollectionEnabled = true
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

### 3. 添加崩溃追踪脚本

在 Xcode 中添加 Run Script Build Phase：

1. 选择项目 > Build Phases
2. 点击 "+" > "New Run Script Phase"
3. 拖动到 "Build" 部分底部
4. 输入以下脚本：

```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

如果使用 SPM，使用：

```bash
"${BUILD_DIR%Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

---

### 4. 自定义崩溃报告

#### 4.1 记录非致命错误

```swift
import FirebaseCrashlytics

// 记录错误
func logError(_ error: Error) {
    Crashlytics.crashlytics().record(error: error)
}

// 记录错误消息
func logErrorMessage(_ message: String) {
    Crashlytics.crashlytics().record(errorMessage: message)
}
```

#### 4.2 添加自定义日志

```swift
// 添加自定义日志到崩溃报告
func logToCrashlytics(_ message: String) {
    Crashlytics.crashlytics().log(message)
}

// 示例：在关键操作前后添加日志
func performCriticalOperation() {
    Crashlytics.crashlytics().log("开始导出梦境")
    
    do {
        try exportDreams()
        Crashlytics.crashlytics().log("梦境导出成功")
    } catch {
        Crashlytics.crashlytics().log("梦境导出失败：\(error.localizedDescription)")
        Crashlytics.crashlytics().record(error: error)
    }
}
```

#### 4.3 设置用户标识符（可选）

```swift
// 设置用户 ID（不使用个人信息）
let userID = UUID().uuidString
Crashlytics.crashlytics().setUserID(userID)

// 设置自定义键值
Crashlytics.crashlytics().setCustomValue("standard", forKeys: "analysisDepth")
Crashlytics.crashlytics().setCustomValue("true", forKeys: "iCloudSyncEnabled")
```

---

### 5. 测试崩溃报告

#### 5.1 添加测试崩溃按钮

在设置页面添加调试功能：

```swift
#if DEBUG
Button("测试崩溃报告") {
    fatalError("测试 Crashlytics 集成")
}
.font(.caption)
.foregroundColor(.red)
#endif
```

#### 5.2 验证步骤

1. 运行应用（Release 模式）
2. 触发测试崩溃
3. 等待 1-2 分钟
4. 在 Firebase Console 查看崩溃报告

---

## 📊 监控指标

### 崩溃率目标

| 指标 | 目标 | 警戒线 |
|------|------|--------|
| 崩溃率 | < 0.1% | > 1% |
| 无崩溃用户 | > 99.5% | < 95% |
| 崩溃影响用户 | < 0.5% | > 5% |

### 关键崩溃类型

- **启动崩溃**: 应用启动时崩溃（最高优先级）
- **内存警告崩溃**: 内存不足导致
- **网络相关崩溃**: API 调用失败
- **数据解析崩溃**: JSON/CoreData 解析错误
- **UI 崩溃**: 主线程阻塞

---

## 🔔 告警设置

### 在 Firebase Console 设置告警

1. 进入 Crashlytics > 设置 > 告警
2. 创建新告警：
   - **崩溃率告警**: 崩溃率 > 1% 时发送邮件
   - **新增问题告警**: 出现新崩溃类型时通知
   - **回归告警**: 已修复问题再次出现时通知

### 告警通知渠道

- 📧 邮件通知
- 💬 Slack 集成
- 📱 短信通知（严重问题）

---

## 📈 性能监控（可选）

### 启用 Performance Monitoring

```swift
import FirebasePerformance

// 追踪自定义网络请求
func trackNetworkRequest() {
    let trace = Performance.startTrace(name: "DreamExport")
    
    do {
        try exportDreams()
        trace?.stop()
    } catch {
        trace?.stop()
        Crashlytics.crashlytics().record(error: error)
    }
}

// 追踪自定义代码段
func trackCustomCode() {
    let trace = Performance.startTrace(name: "AIAnalysis")
    trace?.start()
    
    analyzeDream()
    
    trace?.stop()
}
```

---

## 🛡️ 隐私保护

### 数据收集说明

在隐私政策中添加：

```markdown
### 崩溃数据收集

为了改进应用稳定性，我们使用 Firebase Crashlytics 收集：

- 崩溃堆栈信息
- 设备型号和系统版本
- 应用版本号
- 自定义日志（不包含个人数据）

**不收集的信息**:
- 梦境内容
- 用户个人信息
- 账户凭证
- 位置信息

所有崩溃数据经过匿名化处理，仅用于技术分析和 bug 修复。
```

### 禁用选项

在设置中添加开关：

```swift
Toggle("发送崩溃报告（帮助改进应用）", isOn: $sendCrashReports)
    .onChange(of: sendCrashReports) { newValue in
        Crashlytics.crashlytics().isCrashlyticsCollectionEnabled = newValue
    }
```

---

## 📝 检查清单

- [ ] Firebase 项目创建
- [ ] iOS 应用添加到 Firebase
- [ ] `GoogleService-Info.plist` 下载并添加到项目
- [ ] Firebase SDK 安装（SPM 或 CocoaPods）
- [ ] `DreamLogApp.swift` 初始化代码
- [ ] Run Script Build Phase 添加
- [ ] 测试崩溃报告功能
- [ ] 自定义错误追踪集成到关键功能
- [ ] 隐私政策更新
- [ ] 告警设置配置
- [ ] 团队访问权限配置

---

## 🔗 参考资源

- [Firebase Crashlytics 官方文档](https://firebase.google.com/docs/crashlytics)
- [自定义崩溃报告](https://firebase.google.com/docs/crashlytics/customize-crash-reports)
- [性能监控](https://firebase.google.com/docs/perf-mon)
- [Firebase 隐私政策](https://firebase.google.com/support/privacy)

---

**最后更新**: 2026-03-13  
**Phase 30.6 进度**: 20% → 60% 📈
