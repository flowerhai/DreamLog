#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DreamLog Web - 智能梦境记录应用
主入口文件
"""

import uvicorn
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger
from contextlib import asynccontextmanager

from src.utils.config import settings
from src.utils.database import init_db
from src.routes import dreams, analysis, gallery, stats, challenges


# 配置日志
logger.remove()
logger.add(
    settings.LOG_PATH / "app.log",
    rotation="10 MB",
    retention="30 days",
    level=settings.LOG_LEVEL,
    format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {name}:{function}:{line} | {message}"
)
logger.add(
    lambda msg: print(msg, end=""),
    level=settings.LOG_LEVEL,
    format="<green>{time:HH:mm:ss}</green> | <level>{level}</level> | <cyan>{message}</cyan>"
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时初始化
    logger.info("🌙 DreamLog Web 启动中...")
    await init_db()
    logger.info("✓ 数据库初始化完成")
    logger.info(f"✓ 服务运行在 http://{settings.HOST}:{settings.PORT}")
    
    yield
    
    # 关闭时清理
    logger.info("🌙 DreamLog Web 关闭中...")


# 创建 FastAPI 应用
app = FastAPI(
    title="DreamLog Web",
    description="智能梦境记录应用 - 捕捉醒来即逝的梦境，用 AI 解析其中的象征意义",
    version="1.0.0",
    lifespan=lifespan
)

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 挂载静态文件
static_path = Path(__file__).parent / "static"
static_path.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=str(static_path)), name="static")

# 配置模板
templates_path = Path(__file__).parent / "templates"
templates_path.mkdir(parents=True, exist_ok=True)
templates = Jinja2Templates(directory=str(templates_path))

# 注册路由
app.include_router(dreams.router, prefix="/api/dreams", tags=["梦境管理"])
app.include_router(analysis.router, prefix="/api/analysis", tags=["AI 解析"])
app.include_router(gallery.router, prefix="/api/gallery", tags=["梦境画廊"])
app.include_router(stats.router, prefix="/api/stats", tags=["统计分析"])
app.include_router(challenges.router, prefix="/api/challenges", tags=["梦境挑战"])


@app.get("/")
async def root(request: Request):
    """首页"""
    return templates.TemplateResponse("index.html", {"request": request})


@app.get("/weekly-report")
async def weekly_report(request: Request):
    """梦境周报页面"""
    return templates.TemplateResponse("weekly-report.html", {"request": request})


@app.get("/dashboard")
async def dashboard(request: Request):
    """统计仪表板页面"""
    return templates.TemplateResponse("dashboard.html", {"request": request})


@app.get("/challenges")
async def challenges(request: Request):
    """梦境挑战页面"""
    return templates.TemplateResponse("challenges.html", {"request": request})


@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy", "version": "1.0.0"}


if __name__ == "__main__":
    uvicorn.run(
        "src.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
