# DreamLog Web - 安装和测试指南

## 📋 当前状态

✅ 代码开发完成
✅ 语法检查通过
✅ 项目结构完整
⚠️ 需要安装 Python 依赖

## 🔧 安装步骤

### 方法 1: 使用 pip (推荐)

```bash
cd /root/.openclaw/workspace/product/DreamLog/webapp

# 安装全部依赖
pip install -r requirements.txt

# 或者手动安装核心依赖
pip install fastapi uvicorn sqlalchemy aiosqlite pydantic pydantic-settings python-multipart jinja2 python-dotenv loguru httpx
```

### 方法 2: 使用 pip3

```bash
pip3 install -r requirements.txt
```

### 方法 3: 如果系统没有 pip

需要先安装 pip：

```bash
# CentOS/RHEL/OpenCloudOS
sudo yum install python3-pip

# 或者使用 get-pip.py
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
```

## ✅ 测试检查

安装依赖后，运行检查脚本：

```bash
python3 test_check.py
```

预期输出：
```
✓ 所有依赖已安装
✓ 所有文件存在
✓ 可以启动
```

## 🚀 启动应用

```bash
# 方式 1: 使用启动脚本
./start.sh

# 方式 2: 直接运行
python3 src/main.py

# 方式 3: 使用 uvicorn
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

## 🧪 功能测试

### 1. 访问主页
打开浏览器访问：http://localhost:8000

### 2. 测试 API
访问 API 文档：http://localhost:8000/docs

测试创建梦境：
```bash
curl -X POST http://localhost:8000/api/dreams/ \
  -H "Content-Type: application/json" \
  -d '{
    "content": "我梦见自己在天空中飞翔",
    "mood": "happy",
    "mood_intensity": 8
  }'
```

### 3. 测试 AI 解析
```bash
curl -X POST http://localhost:8000/api/analysis/analyze \
  -H "Content-Type: application/json" \
  -d '{"dream_id": 1}'
```

## ⚠️ 无 AI API 的情况

如果没有配置 AI API Key，应用仍然可以运行：

- **AI 解析**: 使用内置的关键词匹配模拟解析
- **图像生成**: 返回占位图片
- **其他功能**: 完全正常

## 📝 配置文件

编辑 `.env` 文件（可选）：

```env
# AI 服务配置（可选）
LLM_API_KEY=sk-your-openai-api-key
IMAGE_GEN_API_KEY=sk-your-openai-api-key

# 如果不配置，将使用模拟模式
```

## 🐛 常见问题

### 问题 1: 端口被占用
```bash
# 修改端口
PORT=8001 python3 src/main.py
```

### 问题 2: 数据库错误
```bash
# 删除并重建数据库
rm -f data/dreamlog.db
python3 src/main.py
```

### 问题 3: 导入错误
```bash
# 确保在项目目录运行
cd /root/.openclaw/workspace/product/DreamLog/webapp
python3 src/main.py
```

## 📊 测试清单

- [ ] 依赖安装成功
- [ ] 应用启动成功
- [ ] 主页可以访问
- [ ] API 文档可以访问
- [ ] 可以创建梦境
- [ ] 可以查看梦境列表
- [ ] AI 解析功能（如果有 API Key）
- [ ] 图像生成功能（如果有 API Key）
- [ ] 统计页面正常显示

## 📞 需要帮助？

查看详细文档：
- `README.md` - 项目介绍
- `DEVELOPMENT.md` - 开发指南
- `WEBAPP_COMPLETION_REPORT.md` - 完成报告
