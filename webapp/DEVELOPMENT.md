# DreamLog Web - 开发指南

## 项目结构

```
webapp/
├── src/
│   ├── main.py              # 应用入口
│   ├── routes/
│   │   ├── dreams.py        # 梦境管理 API
│   │   ├── analysis.py      # AI 解析 API
│   │   ├── gallery.py       # 梦境画廊 API
│   │   └── stats.py         # 统计分析 API
│   ├── models/
│   │   ├── dream.py         # 数据库模型
│   │   └── schemas.py       # Pydantic 模型
│   ├── services/
│   │   ├── ai_analyzer.py   # AI 解析服务
│   │   ├── image_gen.py     # 图像生成服务
│   │   └── pattern.py       # 模式分析服务
│   └── utils/
│       ├── config.py        # 配置管理
│       └── database.py      # 数据库连接
├── templates/
│   └── index.html           # 主页面
├── static/
│   ├── css/style.css        # 样式
│   └── js/app.js            # 前端逻辑
├── data/                    # 数据存储
├── .env                     # 环境配置
└── requirements.txt         # 依赖
```

## 快速开始

### 1. 安装依赖

```bash
cd /root/.openclaw/workspace/product/DreamLog/webapp
pip install -r requirements.txt
```

### 2. 配置环境

编辑 `.env` 文件：

```bash
# 如果使用 AI 功能，配置 API Key
LLM_API_KEY=your_openai_api_key
IMAGE_GEN_API_KEY=your_openai_api_key

# 不使用 AI 功能也可以运行，会使用模拟解析
```

### 3. 启动应用

```bash
# 开发模式（自动重载）
python src/main.py

# 或者使用 uvicorn
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

### 4. 访问应用

- 主页：http://localhost:8000
- API 文档：http://localhost:8000/docs
- 健康检查：http://localhost:8000/health

## API 接口

### 梦境管理

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/dreams/ | 创建梦境 |
| GET | /api/dreams/ | 获取梦境列表 |
| GET | /api/dreams/{id} | 获取梦境详情 |
| PUT | /api/dreams/{id} | 更新梦境 |
| DELETE | /api/dreams/{id} | 删除梦境 |
| POST | /api/dreams/quick | 快速记录 |

### AI 解析

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/analysis/analyze | 解析梦境 |
| POST | /api/analysis/{id}/regenerate | 重新解析 |
| GET | /api/analysis/{id}/analysis | 获取解析结果 |

### 梦境画廊

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/gallery/generate | 生成图像 |
| GET | /api/gallery/gallery | 获取画廊 |
| GET | /api/gallery/{id}/image | 获取图像 |

### 统计分析

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/stats/overview | 统计概览 |
| GET | /api/stats/patterns | 模式分析 |
| GET | /api/stats/timeline | 时间线 |
| GET | /api/stats/export | 导出数据 |

## 功能特性

### ✅ 已完成

1. **快速记录**
   - 极简表单界面
   - 情绪、睡眠质量、清晰度评分
   - 清醒梦/重复梦境标记

2. **AI 解析**
   - 梦境摘要生成
   - 主题识别
   - 象征物解读
   - 心理学分析
   - 建议生成

3. **梦境画廊**
   - AI 图像生成
   - 多种艺术风格
   - 画廊展示

4. **统计分析**
   - 数据统计
   - 情绪分布
   - 主题分析
   - 时间规律
   - 模式识别

5. **数据管理**
   - SQLite 存储
   - 标签系统
   - 搜索筛选
   - 数据导出

### 🚧 待开发

1. **用户系统**
   - 注册登录
   - 多用户支持
   - 数据隔离

2. **增强功能**
   - 语音输入
   - 移动端适配
   - PWA 支持
   - 离线记录

3. **AI 增强**
   - 本地模型部署
   - 更精准的解析
   - 个性化建议

4. **社交功能**
   - 梦境分享
   - 公开画廊
   - 梦境社区

## 数据库模型

### Dreams 表

```sql
- id: 主键
- title: 标题
- content: 梦境内容
- summary: AI 摘要
- dream_date: 做梦日期
- recorded_at: 记录时间
- mood: 情绪
- mood_intensity: 情绪强度 (1-10)
- sleep_quality: 睡眠质量 (1-5)
- clarity: 清晰度 (1-5)
- analysis: AI 解析结果 (JSON)
- themes: 主题列表 (JSON)
- symbols: 象征物 (JSON)
- generated_image_url: AI 图像 URL
- is_lucid: 清醒梦
- is_recurring: 重复梦境
```

## 配置说明

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| DATABASE_URL | 数据库连接 | sqlite:///./data/dreamlog.db |
| LLM_API_KEY | LLM API Key | - |
| LLM_MODEL | LLM 模型 | gpt-4o-mini |
| IMAGE_GEN_API_KEY | 图像生成 API Key | - |
| IMAGE_GEN_MODEL | 图像生成模型 | dall-e-3 |
| PORT | 服务端口 | 8000 |
| DEBUG | 调试模式 | true |

## 开发计划

### Phase 1 - MVP (当前)
- [x] 基础架构
- [x] 梦境 CRUD
- [x] AI 解析集成
- [x] 前端界面
- [ ] 测试验证

### Phase 2 - 增强
- [ ] 用户认证
- [ ] 移动端优化
- [ ] 数据导出/导入
- [ ] 通知提醒

### Phase 3 - 高级功能
- [ ] 梦境社区
- [ ] 高级分析
- [ ] API 开放
- [ ] 插件系统

## 故障排除

### 数据库错误
```bash
# 删除数据库重新创建
rm data/dreamlog.db
python src/main.py
```

### 端口占用
```bash
# 修改端口
PORT=8001 python src/main.py
```

### AI 服务不可用
- 无 API Key 时使用模拟解析
- 检查网络连接
- 查看日志：data/logs/app.log

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## License

MIT
