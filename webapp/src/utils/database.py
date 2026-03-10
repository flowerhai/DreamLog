#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
数据库模块
"""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text
from loguru import logger

from src.utils.config import settings


# 创建异步引擎
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True
)

# 创建会话工厂
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)


class Base(DeclarativeBase):
    """数据库模型基类"""
    pass


async def init_db():
    """初始化数据库"""
    async with engine.begin() as conn:
        # 导入所有模型以创建表
        from src.models.dream import DreamModel, DreamTagModel, TagModel
        
        # 创建所有表
        await conn.run_sync(Base.metadata.create_all)
        logger.info("数据库表创建完成")


async def get_db() -> AsyncSession:
    """获取数据库会话"""
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def check_db_connection():
    """检查数据库连接"""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return True
    except Exception as e:
        logger.error(f"数据库连接失败：{e}")
        return False
