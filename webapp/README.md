# DreamLog Web - 智能梦境记录应用

> 🌙 捕捉醒来即逝的梦境，用 AI 解析其中的象征意义和隐藏模式

## 产品简介

DreamLog 是一款智能梦境记录 Web 应用，帮助你：

- ✨ **快速记录** - 30 秒内完成梦境记录
- 🧠 **AI 解析** - 发现梦境背后的含义
- 📊 **模式洞察** - 发现重复出现的梦境主题
- 🎨 **梦境画廊** - AI 绘画让梦境可视化

## 核心功能

### 1. 快速记录
- 极简输入界面，醒来即可记录
- 支持语音输入（可选）
- 自动记录时间、情绪标签
- 离线支持，数据本地存储

### 2. AI 解析
- 梦境象征意义解读
- 心理学角度分析
- 情绪状态评估
- 潜在压力源识别

### 3. 模式洞察
- 梦境主题统计
- 时间规律分析
- 情绪变化趋势
-  recurring dreams 识别

### 4. 梦境画廊
- AI 生成梦境图像
- 梦境可视化展示
- 可分享的梦境卡片

## 技术栈

- **后端**: Python 3.9+ / FastAPI
- **数据库**: SQLite (开发) / PostgreSQL (生产)
- **前端**: HTML5 / CSS3 / JavaScript (轻量级)
- **AI**: 集成大语言模型进行梦境解析
- **绘图**: 集成 AI 绘画 API

## 快速开始

```bash
# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env

# 启动服务
python src/main.py

# 访问应用
# http://localhost:8000
```

## 项目结构

```
webapp/
├── src/
│   ├── main.py           # 应用入口
│   ├── routes/           # API 路由
│   │   ├── dreams.py     # 梦境相关
│   │   ├── analysis.py   # AI 解析
│   │   └── gallery.py    # 梦境画廊
│   ├── models/           # 数据模型
│   │   └── dream.py      # 梦境模型
│   ├── services/         # 业务服务
│   │   ├── ai_analyzer.py    # AI 解析服务
│   │   ├── pattern.py        # 模式分析
│   │   └── image_gen.py      # 图像生成
│   └── utils/            # 工具函数
├── templates/            # HTML 模板
├── static/               # 静态资源
├── data/                 # 数据存储
└── requirements.txt      # 依赖
```

## API 文档

启动后访问：http://localhost:8000/docs

## 配置说明

在 `.env` 文件中配置：

```env
# 数据库
DATABASE_URL=sqlite:///./data/dreamlog.db

# AI 服务 (可选)
LLM_API_KEY=your_api_key
IMAGE_GEN_API_KEY=your_api_key

# 应用配置
SECRET_KEY=your_secret_key
DEBUG=true
```

## 状态

- 📋 需求规划 - 已完成
- 🏗️ 架构设计 - 进行中
- 💻 开发实现 - 进行中
- 🧪 测试验证 - 待开始
- 🚀 部署上线 - 待开始

## License

MIT
