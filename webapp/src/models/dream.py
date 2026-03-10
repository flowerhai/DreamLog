#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
梦境数据模型
"""

from sqlalchemy import Column, Integer, String, Text, DateTime, Float, JSON, ForeignKey, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime

from src.utils.database import Base


# 梦境 - 标签关联表
dream_tags = Table(
    'dream_tags',
    Base.metadata,
    Column('dream_id', Integer, ForeignKey('dreams.id', ondelete='CASCADE'), primary_key=True),
    Column('tag_id', Integer, ForeignKey('tags.id', ondelete='CASCADE'), primary_key=True)
)


class TagModel(Base):
    """标签模型"""
    __tablename__ = 'tags'
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False, index=True)
    color = Column(String(7), default='#6B7280')  # 十六进制颜色
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 关联
    dreams = relationship("DreamModel", secondary=dream_tags, back_populates="tags")
    
    def __repr__(self):
        return f"<Tag {self.name}>"


class DreamModel(Base):
    """梦境模型"""
    __tablename__ = 'dreams'
    
    id = Column(Integer, primary_key=True, index=True)
    
    # 基本信息
    title = Column(String(200), nullable=True)  # 可选标题
    content = Column(Text, nullable=False)  # 梦境内容
    summary = Column(Text, nullable=True)  # AI 生成的摘要
    
    # 时间信息
    dream_date = Column(DateTime, default=datetime.utcnow, index=True)  # 做梦日期
    recorded_at = Column(DateTime, default=datetime.utcnow, index=True)  # 记录时间
    
    # 情绪和评分
    mood = Column(String(50), nullable=True)  # 情绪：happy, scared, anxious, etc.
    mood_intensity = Column(Integer, default=5)  # 情绪强度 1-10
    sleep_quality = Column(Integer, nullable=True)  # 睡眠质量 1-5
    clarity = Column(Integer, nullable=True)  # 梦境清晰度 1-5
    
    # AI 解析结果
    analysis = Column(JSON, nullable=True)  # AI 解析结果
    themes = Column(JSON, nullable=True)  # 识别的主题
    symbols = Column(JSON, nullable=True)  # 识别的象征物
    
    # 图像生成
    generated_image_url = Column(String(500), nullable=True)  # AI 生成的图像 URL
    image_prompt = Column(Text, nullable=True)  # 用于生成图像的 prompt
    
    # 元数据
    is_lucid = Column(Integer, default=0)  # 是否为清醒梦 0/1
    is_recurring = Column(Integer, default=0)  # 是否为重复梦境 0/1
    is_public = Column(Integer, default=0)  # 是否公开 0/1
    
    # 标签
    tags = relationship("TagModel", secondary=dream_tags, back_populates="dreams")
    
    # 时间戳
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<Dream {self.id}: {self.title or self.content[:20]}...>"


class DreamTagModel(Base):
    """梦境标签关联模型（如果需要额外字段）"""
    __tablename__ = 'dream_tag_details'
    
    id = Column(Integer, primary_key=True, index=True)
    dream_id = Column(Integer, ForeignKey('dreams.id', ondelete='CASCADE'), nullable=False)
    tag_id = Column(Integer, ForeignKey('tags.id', ondelete='CASCADE'), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
