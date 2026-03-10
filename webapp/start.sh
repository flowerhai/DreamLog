#!/bin/bash
# DreamLog Web 启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🌙 DreamLog Web - 智能梦境记录应用"
echo "===================================="
echo ""

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误：未找到 Python3"
    exit 1
fi

echo "✓ Python: $(python3 --version)"

# 检查依赖
echo ""
echo "检查依赖..."
python3 -c "import fastapi" 2>/dev/null && echo "✓ FastAPI" || echo "⚠ FastAPI 未安装"
python3 -c "import uvicorn" 2>/dev/null && echo "✓ Uvicorn" || echo "⚠ Uvicorn 未安装"
python3 -c "import sqlalchemy" 2>/dev/null && echo "✓ SQLAlchemy" || echo "⚠ SQLAlchemy 未安装"

# 创建必要目录
mkdir -p data data/logs data/images

# 检查配置文件
if [ ! -f ".env" ]; then
    echo ""
    echo "⚠ 未找到 .env 文件，从示例复制..."
    cp .env.example .env
    echo "✓ 已创建 .env 文件，请编辑配置 API Key"
fi

echo ""
echo "启动服务..."
echo "访问地址：http://localhost:8000"
echo "API 文档：http://localhost:8000/docs"
echo ""
echo "按 Ctrl+C 停止服务"
echo "===================================="
echo ""

# 启动应用
exec python3 src/main.py
