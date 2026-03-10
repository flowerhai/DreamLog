#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DreamLog Web - 测试检查脚本
"""

import sys
from pathlib import Path

print("=" * 50)
print("DreamLog Web - 环境检查")
print("=" * 50)

# 检查 Python 版本
print(f"\n✓ Python: {sys.version}")

# 检查必需模块
modules = {
    'fastapi': 'FastAPI',
    'uvicorn': 'Uvicorn',
    'sqlalchemy': 'SQLAlchemy',
    'aiosqlite': 'AsyncSQLite',
    'pydantic': 'Pydantic',
    'jinja2': 'Jinja2',
    'loguru': 'Loguru',
}

print("\n模块检查:")
missing = []
for module, name in modules.items():
    try:
        __import__(module)
        print(f"  ✓ {name}")
    except ImportError:
        print(f"  ✗ {name} - 未安装")
        missing.append(module)

if missing:
    print("\n⚠ 缺少以下模块，需要安装:")
    print(f"  pip install {' '.join(missing)}")
    print("\n或者安装全部依赖:")
    print("  pip install -r requirements.txt")
else:
    print("\n✓ 所有依赖已安装")

# 检查项目结构
print("\n项目结构检查:")
required_files = [
    'src/main.py',
    'src/utils/config.py',
    'src/utils/database.py',
    'src/models/dream.py',
    'src/routes/dreams.py',
    'templates/index.html',
    'static/css/style.css',
    'static/js/app.js',
]

for file in required_files:
    path = Path(file)
    if path.exists():
        print(f"  ✓ {file}")
    else:
        print(f"  ✗ {file} - 不存在")

# 检查配置文件
print("\n配置文件检查:")
env_file = Path('.env')
if env_file.exists():
    print("  ✓ .env 文件存在")
else:
    print("  ⚠ .env 文件不存在，将使用默认配置")

print("\n" + "=" * 50)
if missing:
    print("状态：⚠ 需要安装依赖")
else:
    print("状态：✓ 可以启动")
print("=" * 50)
