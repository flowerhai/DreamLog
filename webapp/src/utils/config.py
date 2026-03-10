#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
配置管理模块
"""

from pydantic_settings import BaseSettings
from pathlib import Path
from functools import lru_cache


class Settings(BaseSettings):
    """应用配置"""
    
    # 应用配置
    APP_NAME: str = "DreamLog Web"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    SECRET_KEY: str = "dreamlog-secret-key-change-in-production"
    
    # 数据库
    DATABASE_URL: str = "sqlite:///./data/dreamlog.db"
    
    # AI 服务
    LLM_PROVIDER: str = "openai"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "gpt-4o-mini"
    
    IMAGE_GEN_PROVIDER: str = "openai"
    IMAGE_GEN_API_KEY: str = ""
    IMAGE_GEN_MODEL: str = "dall-e-3"
    
    # 服务器
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # 日志
    LOG_LEVEL: str = "INFO"
    
    @property
    def BASE_DIR(self) -> Path:
        """项目根目录"""
        return Path(__file__).parent.parent
    
    @property
    def DATA_DIR(self) -> Path:
        """数据目录"""
        data_dir = self.BASE_DIR / "data"
        data_dir.mkdir(parents=True, exist_ok=True)
        return data_dir
    
    @property
    def LOG_PATH(self) -> Path:
        """日志目录"""
        log_path = self.DATA_DIR / "logs"
        log_path.mkdir(parents=True, exist_ok=True)
        return log_path
    
    @property
    def DB_PATH(self) -> Path:
        """数据库文件路径"""
        if self.DATABASE_URL.startswith("sqlite:///"):
            db_path = self.DATA_DIR / self.DATABASE_URL.replace("sqlite:///./", "")
            db_path.parent.mkdir(parents=True, exist_ok=True)
            return db_path
        return self.DATA_DIR / "dreamlog.db"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """获取配置单例"""
    return Settings()


settings = get_settings()
