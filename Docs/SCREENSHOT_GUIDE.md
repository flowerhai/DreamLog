# DreamLog App Store 截图拍摄指南 📸

> 自动化截图拍摄脚本和流程指南

**Phase 30.7 - 发布策略**  
**目标尺寸**: 3 种设备尺寸，每种 5 张截图  
**预计时间**: 30-45 分钟

---

## 📋 截图规格要求

### 设备尺寸

| 设备类型 | 分辨率 (像素) | 比例 | 数量 |
|----------|---------------|------|------|
| iPhone 6.7" (Plus/Pro Max) | 1284 x 2778 | 19.5:9 | 5 张 |
| iPhone 6.5" (XS Max/11 Pro Max) | 1242 x 2688 | 19.5:9 | 5 张 |
| iPhone 5.5" (Plus/8 Plus) | 1242 x 2208 | 16:9 | 5 张 |

### 截图清单

| 编号 | 页面 | 说明 | 优先级 |
|------|------|------|--------|
| 1 | 首页 | 梦境列表/时间线视图，展示精美 UI | 🔴 |
| 2 | 记录 | 语音/文字输入界面，展示便捷记录 | 🔴 |
| 3 | AI 解析 | 梦境分析结果，展示 AI 能力 | 🔴 |
| 4 | 画廊 | AI 生成的梦境图像，展示视觉效果 | 🟡 |
| 5 | 统计 | 数据图表/洞察，展示数据分析 | 🟡 |

---

## 🛠️ 自动化截图脚本

### 准备工作

1. **Xcode 项目设置**
   ```bash
   # 确保项目已配置好 Scheme
   cd /path/to/DreamLog
   ```

2. **创建截图脚本**
   
   在 `DreamLog/Screenshots/` 目录下创建 `capture_screenshots.swift`:

```swift
#!/usr/bin/env xcrun

import Foundation
import XCTest

class ScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app, appDelegate: nil)
        app.launch()
    }
    
    func testCaptureScreenshots() {
        // 截图 1: 首页
        captureHomeScreen()
        
        // 截图 2: 记录页面
        captureRecordScreen()
        
        // 截图 3: AI 解析
        captureAIAnalysisScreen()
        
        // 截图 4: 画廊
        captureGalleryScreen()
        
        // 截图 5: 统计
        captureStatsScreen()
    }
    
    private func captureHomeScreen() {
        // 确保在首页
        app.tabBars.buttons["首页"].tap()
        
        // 等待内容加载
        sleep(2)
        
        // 截图
        snapshot("01Home")
    }
    
    private func captureRecordScreen() {
        // 切换到记录标签
        app.tabBars.buttons["记录"].tap()
        
        // 等待动画完成
        sleep(1)
        
        // 截图
        snapshot("02Record")
    }
    
    private func captureAIAnalysisScreen() {
        // 切换到洞察标签
        app.tabBars.buttons["洞察"].tap()
        
        // 选择第一个梦境
        if app.tables.cells.element(boundBy: 0).exists {
            app.tables.cells.element(boundBy: 0).tap()
            
            // 等待详情页面加载
            sleep(2)
            
            // 截图
            snapshot("03AIAnalysis")
        }
    }
    
    private func captureGalleryScreen() {
        // 切换到画廊标签
        app.tabBars.buttons["画廊"].tap()
        
        // 等待网格加载
        sleep(2)
        
        // 截图
        snapshot("04Gallery")
    }
    
    private func captureStatsScreen() {
        // 切换到洞察标签
        app.tabBars.buttons["洞察"].tap()
        
        // 切换到统计子标签（如果有）
        // 或者滚动到统计部分
        
        // 截图
        snapshot("05Stats")
    }
}
```

### 运行截图脚本

```bash
# 1. 安装 snapshot 工具 (Fastlane)
sudo gem install fastlane

# 2. 初始化 snapshot
cd DreamLog
fastlane snapshot init

# 3. 配置 Snapshotfile
# 编辑 snapshot/Snapshotfile:
# - 设置 devices
# - 设置 languages
# - 设置 output_directory

# 4. 运行截图
fastlane snapshot

# 5. 截图输出位置
# ./snapshot_output/[device]/[language]/[screenshot_name].png
```

---

## 📱 手动截图方案 (备选)

如果自动化脚本不可用，可以手动截图：

### iPhone 6.7" (iPhone 15 Pro Max 模拟器)

1. **打开 Xcode**
   ```
   Product → Scheme → Edit Scheme...
   → Run → Info → Simulator → iPhone 15 Pro Max (6.7")
   ```

2. **启动应用**
   ```
   Product → Run (⌘R)
   ```

3. **截图操作**
   ```
   File → New Screen Capture (⌘S)
   或使用快捷键：⌘S
   ```

4. **保存截图**
   ```
   保存到：~/Desktop/DreamLog_Screenshots/6.7_inch/
   命名：01_Home.png, 02_Record.png, 03_AI.png, 04_Gallery.png, 05_Stats.png
   ```

### 调整到其他尺寸

重复上述步骤，切换模拟器设备：
- iPhone 15 Pro Max (6.7") → 1284x2778
- iPhone 14 Pro Max (6.5") → 1242x2688  
- iPhone 8 Plus (5.5") → 1242x2208

---

## 🎨 截图优化建议

### 内容准备

1. **准备示例数据**
   - 至少 10-15 条梦境记录
   - 包含不同情绪和标签
   - 有 AI 生成的图像
   - 有统计图表数据

2. **美化界面**
   - 确保所有文本清晰可读
   - 避免敏感/个人信息
   - 使用示例梦境内容（有趣、正面）

3. **截图时机**
   - 等待所有动画完成
   - 确保数据加载完成
   - 避免加载状态/占位符

### 后期处理

1. **添加设备外壳** (可选)
   - 使用 Apple 官方设备外壳模板
   - 工具：https://developer.apple.com/app-store/marketing/

2. **调整亮度/对比度**
   - 确保截图清晰明亮
   - 突出核心功能

3. **添加标注** (可选)
   - 箭头指示重要功能
   - 简短说明文字

---

## 📤 上传到 App Store Connect

### 步骤

1. **登录 App Store Connect**
   ```
   https://appstoreconnect.apple.com
   ```

2. **选择应用**
   ```
   我的应用 → DreamLog → 1.0 准备提交
   ```

3. **上传截图**
   ```
   App Store 标签 → iOS App
   → 6.7 英寸显示 (iPhone 15 Pro Max)
   → 拖拽 5 张截图
   → 6.5 英寸显示 (iPhone 14 Pro Max)
   → 拖拽 5 张截图
   → 5.5 英寸显示 (iPhone 8 Plus)
   → 拖拽 5 张截图
   ```

4. **排序截图**
   ```
   拖拽调整顺序，确保最重要的截图在前
   推荐顺序：首页 → 记录 → AI 解析 → 画廊 → 统计
   ```

---

## ✅ 截图检查清单

### 技术检查

- [ ] 所有截图分辨率正确
- [ ] 文件格式为 PNG
- [ ] 文件大小 < 10MB 每张
- [ ] 命名规范统一

### 内容检查

- [ ] 展示核心功能
- [ ] 无拼写错误
- [ ] 无敏感信息
- [ ] 界面美观清晰
- [ ] 文案有吸引力

### 合规检查

- [ ] 不包含其他应用截图
- [ ] 不包含设备外壳（除非 Apple 官方）
- [ ] 不包含价格/促销信息
- [ ] 符合 App Store 审核指南

---

## 🔧 故障排除

### 问题：截图模糊

**解决方案**:
- 确保使用 @2x/@3x 模拟器
- 检查截图工具设置
- 避免缩放截图

### 问题：内容未加载

**解决方案**:
- 增加等待时间 (sleep)
- 使用 XCUIElement 的 waitForExistence
- 确保测试数据已准备

### 问题：截图尺寸不对

**解决方案**:
- 确认模拟器设备正确
- 检查 Xcode 版本
- 重新运行截图脚本

---

## 📞 需要帮助？

- Apple 官方文档：https://developer.apple.com/app-store/screenshots/
- Fastlane snapshot 文档：https://docs.fastlane.tools/actions/snapshot/
- App Store Connect 帮助：https://developer.apple.com/app-store-connect/

---

**创建时间**: 2026-03-13 10:04 UTC  
**最后更新**: 2026-03-13 10:04 UTC  
**负责人**: DreamLog 开发团队
