# Phase 40 开发计划 - AR 社交功能 🌐✨

**创建时间**: 2026-03-14 08:14 UTC  
**优先级**: 高 🔴  
**预计工作量**: 12-16 小时  
**分支**: dev

---

## 🎯 Phase 40 目标

实现 AR 社交功能，让用户能够：
- 与他人共享 AR 梦境空间
- 实时协作探索梦境
- 在 AR 空间中发送消息和互动
- 创建多人梦境体验

---

## 📋 任务清单

### 1. 数据模型设计 (优先级：高) 🔴

**目标**: 设计 AR 社交功能的数据模型

**核心模型**:
- [ ] **ARSession** - AR 会话模型
  - sessionID: UUID
  - hostUserID: UUID
  - dreamID: UUID?
  - sceneTemplate: String
  - createdAt: Date
  - expiresAt: Date
  - maxParticipants: Int
  - isPublic: Bool
  - participantIDs: [UUID]

- [ ] **ARParticipant** - 参与者模型
  - participantID: UUID
  - sessionID: UUID
  - userID: UUID
  - displayName: String
  - avatar: Data?
  - joinedAt: Date
  - lastActiveAt: Date
  - position: SIMD3<Float>
  - rotation: SIMD4<Float>

- [ ] **ARElement** - AR 元素模型
  - elementID: UUID
  - sessionID: UUID
  - creatorID: UUID
  - elementType: String (crystal/water/light/etc)
  - position: SIMD3<Float>
  - rotation: SIMD4<Float>
  - scale: SIMD3<Float>
  - color: CGColor
  - metadata: [String: String]
  - createdAt: Date

- [ ] **ARMessage** - AR 消息模型
  - messageID: UUID
  - sessionID: UUID
  - senderID: UUID
  - messageType: String (text/emoji/reaction)
  - content: String
  - position: SIMD3<Float>?
  - targetElementID: UUID?
  - createdAt: Date
  - expiresAt: Date

- [ ] **ARInteraction** - AR 互动模型
  - interactionID: UUID
  - sessionID: UUID
  - actorID: UUID
  - targetID: UUID (participant/element)
  - interactionType: String (tap/wave/send)
  - timestamp: Date

**文件**: `DreamARSocialModels.swift` (~350 行)

---

### 2. AR 会话管理服务 (优先级：高) 🔴

**目标**: 实现 AR 会话的创建、管理和同步

**核心功能**:
- [ ] **创建 AR 会话**
  - 主机创建新会话
  - 设置会话参数（模板/人数限制/公开性）
  - 生成邀请链接/码

- [ ] **加入 AR 会话**
  - 通过邀请码加入
  - 通过链接加入
  - 验证会话有效性

- [ ] **会话同步**
  - 实时同步参与者位置
  - 同步 AR 元素状态
  - 同步消息和互动

- [ ] **会话管理**
  - 主持人权限（踢人/修改设置）
  - 自动过期清理
  - 会话历史记录

**技术实现**:
- 使用 MultipeerConnectivity 进行本地 P2P 连接
- 使用 CloudKit 进行远程同步（可选）
- WebSocket 用于实时通信

**文件**: `DreamARSocialService.swift` (~500 行)

---

### 3. AR 社交 UI 界面 (优先级：高) 🔴

**目标**: 创建 AR 社交功能的用户界面

**核心界面**:
- [ ] **AR 会话列表视图**
  - 显示可用会话
  - 显示会话状态（人数/模板）
  - 创建/加入按钮

- [ ] **AR 会话创建视图**
  - 选择场景模板
  - 设置人数限制
  - 设置公开性
  - 生成邀请

- [ ] **AR 社交空间视图**
  - AR 场景渲染
  - 参与者头像/标识
  - 实时位置指示器
  - 互动控制面板

- [ ] **AR 消息面板**
  - 发送文本消息
  - 发送表情符号
  - 发送反应（点赞/爱心等）
  - 消息历史

- [ ] **参与者列表**
  - 显示所有参与者
  - 显示状态（在线/活跃）
  - 主持人操作菜单

**文件**: `DreamARSocialView.swift` (~900 行)

---

### 4. 实时同步引擎 (优先级：高) 🔴

**目标**: 实现低延迟的实时数据同步

**核心功能**:
- [ ] **位置同步**
  - 参与者位置更新（60 FPS）
  - 平滑插值移动
  - 预测性渲染

- [ ] **元素同步**
  - 新增元素广播
  - 元素状态更新
  - 元素删除同步

- [ ] **消息同步**
  - 实时消息传递
  - 消息持久化
  - 离线消息队列

- [ ] **冲突解决**
  - 最后写入获胜策略
  - 操作转换（OT）
  - 版本向量

**技术实现**:
- 使用 Combine 进行响应式数据流
- 使用 OperationQueue 管理同步任务
- 实现增量同步减少带宽

**文件**: `DreamARSyncEngine.swift` (~400 行)

---

### 5. 邀请系统 (优先级：中) 🟡

**目标**: 实现会话邀请功能

**核心功能**:
- [ ] **邀请码生成**
  - 6 位数字码
  - 二维码生成
  - 短链接生成

- [ ] **分享邀请**
  - 系统分享表单
  - 复制邀请码
  - 发送消息邀请

- [ ] **邀请验证**
  - 验证邀请码有效性
  - 检查会话容量
  - 处理过期邀请

**文件**: `DreamARInviteService.swift` (~200 行)

---

### 6. 权限与安全 (优先级：高) 🔴

**目标**: 实现会话权限管理和安全保障

**核心功能**:
- [ ] **主持人权限**
  - 踢出参与者
  - 静音参与者
  - 修改会话设置
  - 结束会话

- [ ] **参与者权限**
  - 添加/修改自己的元素
  - 发送消息
  - 互动权限

- [ ] **安全措施**
  - 会话密码保护
  - 邀请验证
  - 速率限制
  - 举报机制

**文件**: `DreamARSocialPermissions.swift` (~150 行)

---

### 7. 性能优化 (优先级：高) 🔴

**目标**: 确保多人 AR 体验流畅

**优化项**:
- [ ] **网络优化**
  - 数据压缩
  - 增量更新
  - 连接复用

- [ ] **渲染优化**
  - LOD 系统
  - 视锥体剔除
  - 实例化渲染

- [ ] **内存优化**
  - 对象池
  - 资源懒加载
  - 自动清理

**目标指标**:
- 位置同步延迟 < 50ms
- AR 帧率稳定 60 FPS
- 支持最多 8 人同时在线

---

### 8. 单元测试 (优先级：高) 🔴

**目标**: 确保代码质量和功能正确性

**测试覆盖**:
- [ ] **模型测试** (~10 用例)
  - 数据模型创建
  - 数据验证
  - 序列化/反序列化

- [ ] **服务测试** (~15 用例)
  - 会话创建/加入
  - 参与者管理
  - 元素同步
  - 消息传递

- [ ] **同步引擎测试** (~10 用例)
  - 位置同步
  - 冲突解决
  - 性能测试

- [ ] **集成测试** (~5 用例)
  - 完整会话流程
  - 多人互动场景

**测试文件**: `DreamARSocialTests.swift` (~500 行)

**目标覆盖率**: 90%+

---

## 📅 时间安排

| 阶段 | 任务 | 预计时间 | 完成度 |
|------|------|----------|--------|
| 1 | 数据模型设计 | 2 小时 | 0% |
| 2 | AR 会话管理服务 | 3 小时 | 0% |
| 3 | 实时同步引擎 | 3 小时 | 0% |
| 4 | AR 社交 UI 界面 | 4 小时 | 0% |
| 5 | 邀请系统 | 1 小时 | 0% |
| 6 | 权限与安全 | 1 小时 | 0% |
| 7 | 性能优化 | 1 小时 | 0% |
| 8 | 单元测试 | 1 小时 | 0% |

**总计**: 16 小时

---

## 🎨 界面预览

### AR 会话列表
```
┌─────────────────────────┐
│  AR 社交空间      [+ ]  │
├─────────────────────────┤
│  可用会话               │
│  🌌 星空梦境 (3/8)     ›│
│  🌊 海洋世界 (2/6)     ›│
│  🏔️ 雪山奇境 (1/4)     ›│
├─────────────────────────┤
│  [创建新会话]           │
│  [输入邀请码]           │
└─────────────────────────┘
```

### AR 社交空间
```
┌─────────────────────────┐
│  星空梦境          [≡]  │
├─────────────────────────┤
│                         │
│    [AR 场景渲染]        │
│    👤 👤 👤            │
│    (参与者)             │
│                         │
│  [💬] [✨] [🎮] [⚙️]   │
└─────────────────────────┘
```

### 消息面板
```
┌─────────────────────────┐
│  消息              [×]  │
├─────────────────────────┤
│  👤 Alice: 好美的星空！ │
│  👤 Bob: 看那个流星！  │
│  👤 You: ✨✨✨        │
├─────────────────────────┤
│  [😊] [✨] [❤️] [👍]   │
│  [输入消息...      ] [➤]│
└─────────────────────────┘
```

---

## 🔧 技术架构

```
┌─────────────────────────────────────────┐
│         DreamARSocialView               │
│              (UI Layer)                 │
├─────────────────────────────────────────┤
│       DreamARSocialService              │
│         (Session Management)            │
├─────────────────────────────────────────┤
│         DreamARSyncEngine               │
│        (Real-time Sync)                 │
├─────────────────────────────────────────┤
│  ARSession | ARParticipant | ARElement  │
│         (SwiftData Models)              │
├─────────────────────────────────────────┤
│    MultipeerConnectivity / WebSocket    │
│         (Network Layer)                 │
└─────────────────────────────────────────┘
```

---

## 📊 成功标准

- [ ] 支持最多 8 人同时在线
- [ ] 位置同步延迟 < 50ms
- [ ] AR 帧率稳定 60 FPS
- [ ] 测试覆盖率 > 90%
- [ ] 无崩溃问题
- [ ] 用户体验流畅

---

## 🔗 相关资源

- [MultipeerConnectivity 文档](https://developer.apple.com/documentation/multipeerconnectivity)
- [ARKit 多人协作](https://developer.apple.com/documentation/arkit/collaborative_sessions)
- [CloudKit 实时同步](https://developer.apple.com/documentation/cloudkit/ckdatabase)
- [WebSocket RFC](https://datatracker.ietf.org/doc/html/rfc6455)

---

## 🎯 后续优化建议

### 短期优化
- [ ] 添加更多场景模板
- [ ] 支持语音聊天
- [ ] 添加 AR 小游戏

### 中期优化
- [ ] 跨平台支持（macOS/iPad）
- [ ] 录制和回放功能
- [ ]  spectator 模式

### 长期优化
- [ ] 云端 AR 渲染
- [ ] AI 驱动的 NPC
- [ ] 梦境世界持久化

---

<div align="center">

**Phase 40: AR 社交功能** 🌐✨

[← Phase 39](PHASE39_COMPLETION_REPORT.md) | [DreamLog README](README.md)

</div>
