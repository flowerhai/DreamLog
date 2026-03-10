#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pydantic 数据模型 - 用于 API 请求/响应验证
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


# ==================== 标签相关 ====================

class TagBase(BaseModel):
    """标签基础模型"""
    name: str = Field(..., min_length=1, max_length=50, description="标签名称")
    color: Optional[str] = Field(default="#6B7280", pattern="^#[0-9A-Fa-f]{6}$", description="标签颜色")


class TagCreate(TagBase):
    """创建标签"""
    pass


class TagResponse(TagBase):
    """标签响应"""
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


# ==================== 梦境相关 ====================

class DreamBase(BaseModel):
    """梦境基础模型"""
    title: Optional[str] = Field(None, max_length=200, description="梦境标题")
    content: str = Field(..., min_length=1, description="梦境内容")
    dream_date: Optional[datetime] = Field(default_factory=datetime.utcnow, description="做梦日期")
    mood: Optional[str] = Field(None, description="情绪状态")
    mood_intensity: Optional[int] = Field(default=5, ge=1, le=10, description="情绪强度 1-10")
    sleep_quality: Optional[int] = Field(None, ge=1, le=5, description="睡眠质量 1-5")
    clarity: Optional[int] = Field(None, ge=1, le=5, description="梦境清晰度 1-5")
    is_lucid: bool = Field(default=False, description="是否为清醒梦")
    is_recurring: bool = Field(default=False, description="是否为重复梦境")
    tag_ids: Optional[List[int]] = Field(default=[], description="标签 ID 列表")


class DreamCreate(DreamBase):
    """创建梦境"""
    pass


class DreamUpdate(BaseModel):
    """更新梦境"""
    title: Optional[str] = Field(None, max_length=200)
    content: Optional[str] = None
    mood: Optional[str] = None
    mood_intensity: Optional[int] = Field(None, ge=1, le=10)
    sleep_quality: Optional[int] = Field(None, ge=1, le=5)
    clarity: Optional[int] = Field(None, ge=1, le=5)
    is_lucid: Optional[bool] = None
    is_recurring: Optional[bool] = None
    tag_ids: Optional[List[int]] = None


class DreamAnalysis(BaseModel):
    """AI 解析结果"""
    summary: str = Field(..., description="梦境摘要")
    themes: List[str] = Field(default=[], description="主题列表")
    symbols: List[Dict[str, str]] = Field(default=[], description="象征物列表")
    interpretation: str = Field(..., description="详细解读")
    psychological_meaning: str = Field(..., description="心理学含义")
    emotional_state: str = Field(..., description="情绪状态分析")
    suggestions: List[str] = Field(default=[], description="建议")


class DreamResponse(DreamBase):
    """梦境响应"""
    id: int
    summary: Optional[str] = None
    analysis: Optional[Dict[str, Any]] = None
    themes: Optional[List[str]] = None
    symbols: Optional[List[Dict[str, str]]] = None
    generated_image_url: Optional[str] = None
    image_prompt: Optional[str] = None
    recorded_at: datetime
    created_at: datetime
    updated_at: datetime
    tags: List[TagResponse] = []
    
    class Config:
        from_attributes = True


class DreamListResponse(BaseModel):
    """梦境列表响应"""
    items: List[DreamResponse]
    total: int
    page: int
    page_size: int
    has_more: bool


# ==================== AI 解析相关 ====================

class AnalysisRequest(BaseModel):
    """AI 解析请求"""
    dream_id: int
    regenerate: bool = Field(default=False, description="是否重新生成")


class AnalysisResponse(BaseModel):
    """AI 解析响应"""
    dream_id: int
    analysis: DreamAnalysis
    generated_at: datetime


# ==================== 图像生成相关 ====================

class ImageGenRequest(BaseModel):
    """图像生成请求"""
    dream_id: int
    style: Optional[str] = Field(default="surreal", description="艺术风格")
    regenerate: bool = Field(default=False, description="是否重新生成")


class ImageGenResponse(BaseModel):
    """图像生成响应"""
    dream_id: int
    image_url: str
    prompt: str
    generated_at: datetime


# ==================== 统计相关 ====================

class StatsOverview(BaseModel):
    """统计概览"""
    total_dreams: int
    total_days: int
    avg_dreams_per_week: float
    most_common_mood: Optional[str]
    most_common_theme: Optional[str]
    lucid_dream_count: int
    recurring_dream_count: int


class MoodStats(BaseModel):
    """情绪统计"""
    mood: str
    count: int
    percentage: float


class ThemeStats(BaseModel):
    """主题统计"""
    theme: str
    count: int
    percentage: float


class StatsResponse(BaseModel):
    """统计响应"""
    overview: StatsOverview
    mood_distribution: List[MoodStats]
    theme_distribution: List[ThemeStats]
    recent_trends: Dict[str, Any]


# ==================== 通用响应 ====================

class APIResponse(BaseModel):
    """通用 API 响应"""
    success: bool
    message: str
    data: Optional[Any] = None


class ErrorResponse(BaseModel):
    """错误响应"""
    success: bool = False
    error: str
    detail: Optional[str] = None
