# Phase 42 开发计划 - 梦境社区功能 🌐💚

**创建时间**: 2026-03-14 12:30 UTC  
**优先级**: 中 🟡  
**预计工作量**: 10-15 小时

---

## 🎯 Phase 42 目标

构建安全、匿名的梦境社区，让用户可以分享梦境、发现共鸣、获得启发，同时保护隐私。

---

## 📋 核心功能

### 1. 匿名分享系统 (优先级：高) 🔴

**目标**: 让用户安全地分享梦境，无需担心隐私泄露

**功能清单**:
- [ ] **匿名化处理**
  - 自动移除人名/地名/具体日期
  - 模糊化处理敏感信息
  - 用户可选择分享范围（公开/仅关注者/私密）

- [ ] **分享配置**
  - 选择分享字段（标题/内容/情绪/标签/AI 解析）
  - 选择可见范围（公开/仅关注者/私密）
  - 设置评论权限（开放/仅关注者/关闭）

- [ ] **分享历史**
  - 追踪已分享的梦境
  - 查看互动数据（点赞/评论/收藏）
  - 随时删除或转为私密

---

### 2. 梦境发现 (优先级：高) 🔴

**目标**: 帮助用户发现有趣、有共鸣的梦境

**功能清单**:
- [ ] **推荐算法**
  - 基于标签相似度推荐
  - 基于情绪匹配推荐
  - 基于时间段推荐（今日热门/本周精选）

- [ ] **分类浏览**
  - 按梦境类型分类（冒险/奇幻/恐怖/浪漫等）
  - 按情绪分类（平静/兴奋/焦虑/喜悦等）
  - 按标签分类（飞行/坠落/追逐/考试等）

- [ ] **搜索功能**
  - 关键词搜索
  - 标签筛选
  - 情绪筛选
  - 日期范围筛选

---

### 3. 互动系统 (优先级：中) 🟡

**目标**: 促进用户之间的良性互动

**功能清单**:
- [ ] **点赞系统**
  - 简单点赞功能
  - 查看点赞数
  - 取消点赞

- [ ] **收藏功能**
  - 收藏喜欢的梦境
  - 收藏夹管理
  - 私密收藏

- [ ] **评论系统**
  - 发表评论
  - 回复评论
  - 评论点赞
  - 举报不当评论

- [ ] **关注系统**
  - 关注感兴趣的匿名用户
  - 关注者/关注中列表
  - 动态推送（可选）

---

### 4. 社区统计 (优先级：中) 🟡

**目标**: 展示社区整体数据和趋势

**功能清单**:
- [ ] **全球统计**
  - 今日分享数
  - 总梦境数
  - 活跃用户数
  - 热门梦境类型

- [ ] **趋势分析**
  - 本周热门梦境
  - 本月情绪趋势
  - 热门标签排行

- [ ] **共鸣发现**
  - "和你相似的人也在做这样的梦"
  - "这个梦境被 X 人收藏"
  - "Y 人有类似经历"

---

### 5. 隐私与安全 (优先级：高) 🔴

**目标**: 确保用户隐私和安全

**功能清单**:
- [ ] **内容审核**
  - 自动检测敏感内容
  - 用户举报机制
  - 管理员审核队列

- [ ] **隐私保护**
  - 严格匿名化
  - 不收集个人信息
  - 数据加密传输
  - 本地存储优先

- [ ] **用户控制**
  - 随时删除分享内容
  - 转为私密
  - 屏蔽其他用户
  - 隐私设置

---

## 📦 数据模型

### 共享梦境 (SharedDream)

```swift
@Model
final class SharedDream {
    var id: UUID
    var anonymousId: String          // 匿名 ID
    var title: String
    var content: String
    var emotions: [String]
    var tags: [String]
    var dreamType: String?
    var aiAnalysis: String?          // 可选分享 AI 解析
    
    var visibility: Visibility       // public/followers/private
    var allowComments: Bool
    
    var likeCount: Int
    var commentCount: Int
    var favoriteCount: Int
    
    var createdAt: Date
    var updatedAt: Date
    
    var isDeleted: Bool
    var deletedAt: Date?
}
```

### 社区用户 (CommunityUser)

```swift
@Model
final class CommunityUser {
    var id: UUID
    var anonymousId: String
    var avatarSeed: Int              // 基于 ID 生成的头像
    
    var followingCount: Int
    var followerCount: Int
    var sharedCount: Int
    
    var createdAt: Date
    
    var blockedUsers: [String]       // 屏蔽的用户 ID
}
```

### 评论 (CommunityComment)

```swift
@Model
final class CommunityComment {
    var id: UUID
    var sharedDreamId: UUID
    var anonymousId: String
    var content: String
    
    var likeCount: Int
    var parentCommentId: UUID?       // 回复评论
    
    var createdAt: Date
    var isDeleted: Bool
}
```

---

## 🎨 UI 设计

### 社区主界面

```
┌─────────────────────────┐
│  🌐 梦境社区            │
├─────────────────────────┤
│ [发现] [热门] [关注]     │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ 😊 平静             │ │
│ │ "我在云端飞翔..."    │ │
│ │ ❤️ 234  💬 45  ⭐ 89 │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ 🎨 奇幻             │ │
│ │ "海底的水晶城堡..."  │ │
│ │ ❤️ 189  💬 32  ⭐ 67 │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

### 分享界面

```
┌─────────────────────────┐
│  分享梦境               │
├─────────────────────────┤
│ [x] 分享标题            │
│ [x] 分享内容            │
│ [ ] 分享 AI 解析          │
│                         │
│ 可见范围:               │
│ ○ 公开 (所有人可见)     │
│ ○ 仅关注者             │
│ ○ 私密 (仅自己可见)     │
│                         │
│ 评论权限:               │
│ [x] 允许评论            │
│                         │
│      [取消] [分享]      │
└─────────────────────────┘
```

---

## 🔧 技术实现

### 后端架构

**方案 A: 纯本地 + iCloud 同步**
- 优点：隐私最好，无需服务器
- 缺点：无法实现真正的社区功能

**方案 B: 轻量级后端服务**
- 使用 Cloudflare Workers 或 Supabase
- 仅存储匿名化数据
- 端到端加密
- 推荐方案

**方案 C: 去中心化存储**
- 使用 IPFS 或类似技术
- 完全去中心化
- 技术复杂度高

### 匿名化算法

```swift
func anonymizeDream(_ dream: Dream) -> SharedDream {
    // 1. 移除人名
    let content = removeNames(dream.content)
    
    // 2. 模糊化地名
    let content =模糊化 locations(content)
    
    // 3. 移除具体日期
    let content = removeSpecificDates(content)
    
    // 4. 生成匿名 ID
    let anonymousId = generateAnonymousId()
    
    return SharedDream(...)
}
```

---

## 📅 时间安排

| 阶段 | 任务 | 时间 |
|------|------|------|
| Day 1-2 | 数据模型设计 + 匿名化算法 | 4-6 小时 |
| Day 3-4 | 后端服务搭建（如需要） | 6-8 小时 |
| Day 5-6 | 分享功能实现 | 6-8 小时 |
| Day 7-8 | 发现和浏览功能 | 6-8 小时 |
| Day 9-10 | 互动系统（点赞/评论/收藏） | 6-8 小时 |
| Day 11 | 隐私和安全功能 | 4-6 小时 |
| Day 12 | 测试和优化 | 4-6 小时 |

**总预计**: 10-15 小时

---

## 🧪 测试计划

### 单元测试
- [ ] 匿名化算法测试
- [ ] 数据模型测试
- [ ] 可见性逻辑测试

### 集成测试
- [ ] 分享流程测试
- [ ] 互动功能测试
- [ ] 隐私设置测试

### 安全测试
- [ ] 敏感内容检测
- [ ] 举报机制测试
- [ ] 数据加密测试

---

## 📊 成功标准

- [ ] 匿名化准确率 > 99%
- [ ] 用户隐私零泄露
- [ ] 分享功能流畅无卡顿
- [ ] 互动响应时间 < 1 秒
- [ ] 测试覆盖率 > 90%
- [ ] 无严重安全漏洞

---

## ⚠️ 风险与缓解

### 风险 1: 隐私泄露
**缓解**: 
- 严格的匿名化算法
- 多层审核机制
- 用户可随时删除

### 风险 2: 不当内容
**缓解**:
- 自动内容检测
- 用户举报机制
- 快速响应团队

### 风险 3: 服务器成本
**缓解**:
- 使用免费层服务
- 限制单用户存储
- 定期清理旧数据

---

## 🔗 相关资源

- [Supabase](https://supabase.com/)
- [Cloudflare Workers](https://workers.cloudflare.com/)
- [内容审核 API](https://azure.microsoft.com/zh-cn/services/cognitive-services/content-moderator/)

---

<div align="center">

**Phase 42: 梦境社区** 🌐💚

[← Phase 41](PHASE41_COMPLETION_REPORT.md) | [DreamLog README](README.md)

</div>
