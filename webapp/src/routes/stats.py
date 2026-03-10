#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
统计分析 API 路由
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timedelta
from collections import Counter

from src.utils.database import get_db
from src.models.dream import DreamModel, TagModel
from src.models.schemas import (
    StatsResponse, StatsOverview, MoodStats, ThemeStats, APIResponse
)
from src.services.pattern import pattern_analyzer

router = APIRouter()


@router.get("/overview", response_model=StatsResponse, summary="获取统计概览")
async def get_stats_overview(db: AsyncSession = Depends(get_db)):
    """
    获取梦境统计概览
    
    包括:
    - 总梦境数
    - 记录天数
    - 平均每周梦境数
    - 最常见情绪
    - 最常见主题
    - 清醒梦/重复梦境数量
    """
    # 基础统计
    total_result = await db.execute(select(func.count()).select_from(DreamModel))
    total_dreams = total_result.scalar() or 0
    
    # 日期范围
    date_result = await db.execute(
        select(func.min(DreamModel.dream_date), func.max(DreamModel.dream_date))
    )
    min_date, max_date = date_result.fetchone()
    
    total_days = 0
    if min_date and max_date:
        total_days = (max_date - min_date).days + 1
    
    # 平均每周梦境数
    weeks = max(1, total_days // 7)
    avg_per_week = round(total_dreams / weeks, 2)
    
    # 最常见情绪
    mood_result = await db.execute(
        select(DreamModel.mood, func.count()).group_by(DreamModel.mood)
    )
    mood_counts = mood_result.fetchall()
    most_common_mood = max(mood_counts, key=lambda x: x[1])[0] if mood_counts else None
    
    # 情绪分布
    mood_distribution = [
        MoodStats(mood=mood or "未标记", count=count, percentage=round(count / total_dreams * 100, 1) if total_dreams > 0 else 0)
        for mood, count in sorted(mood_counts, key=lambda x: x[1], reverse=True)
    ]
    
    # 最常见主题（从 JSON 中提取）
    all_dreams_result = await db.execute(select(DreamModel))
    all_dreams = all_dreams_result.scalars().all()
    
    all_themes = []
    for dream in all_dreams:
        if dream.themes:
            all_themes.extend(dream.themes)
    
    theme_counts = Counter(all_themes)
    most_common_theme = theme_counts.most_common(1)[0][0] if theme_counts else None
    
    theme_distribution = [
        ThemeStats(theme=theme, count=count, percentage=round(count / len(all_themes) * 100, 1) if all_themes else 0)
        for theme, count in theme_counts.most_common(10)
    ]
    
    # 清醒梦和重复梦境
    lucid_result = await db.execute(
        select(func.count()).where(DreamModel.is_lucid == 1)
    )
    lucid_count = lucid_result.scalar() or 0
    
    recurring_result = await db.execute(
        select(func.count()).where(DreamModel.is_recurring == 1)
    )
    recurring_count = recurring_result.scalar() or 0
    
    # 近期趋势
    recent_7_days = await db.execute(
        select(func.count()).where(
            DreamModel.dream_date >= datetime.utcnow() - timedelta(days=7)
        )
    )
    recent_30_days = await db.execute(
        select(func.count()).where(
            DreamModel.dream_date >= datetime.utcnow() - timedelta(days=30)
        )
    )
    
    recent_trends = {
        "last_7_days": recent_7_days.scalar() or 0,
        "last_30_days": recent_30_days.scalar() or 0,
        "trend": "stable"  # 可以进一步计算趋势
    }
    
    return StatsResponse(
        overview=StatsOverview(
            total_dreams=total_dreams,
            total_days=total_days,
            avg_dreams_per_week=avg_per_week,
            most_common_mood=most_common_mood,
            most_common_theme=most_common_theme,
            lucid_dream_count=lucid_count,
            recurring_dream_count=recurring_count
        ),
        mood_distribution=mood_distribution,
        theme_distribution=theme_distribution,
        recent_trends=recent_trends
    )


@router.get("/patterns", summary="梦境模式分析")
async def get_pattern_analysis(db: AsyncSession = Depends(get_db)):
    """
    深度梦境模式分析
    
    发现:
    - 重复出现的主题
    - 情绪变化规律
    - 时间分布模式
    - 潜在关联
    """
    patterns = await pattern_analyzer.analyze_patterns(db)
    return {
        "success": True,
        "data": patterns
    }


@router.get("/timeline", summary="梦境时间线")
async def get_timeline(
    days: int = 30,
    db: AsyncSession = Depends(get_db)
):
    """
    获取梦境时间线数据
    
    用于绘制图表
    """
    start_date = datetime.utcnow() - timedelta(days=days)
    
    result = await db.execute(
        select(DreamModel)
        .where(DreamModel.dream_date >= start_date)
        .order_by(DreamModel.dream_date.desc())
    )
    
    dreams = result.scalars().all()
    
    # 按日期分组
    by_date = {}
    for dream in dreams:
        date_key = dream.dream_date.strftime("%Y-%m-%d")
        if date_key not in by_date:
            by_date[date_key] = {
                "date": date_key,
                "count": 0,
                "moods": [],
                "dreams": []
            }
        by_date[date_key]["count"] += 1
        if dream.mood:
            by_date[date_key]["moods"].append(dream.mood)
        by_date[date_key]["dreams"].append({
            "id": dream.id,
            "title": dream.title or dream.content[:30],
            "mood": dream.mood
        })
    
    return {
        "timeline": list(by_date.values()),
        "total": len(dreams),
        "days": days
    }


@router.get("/export", summary="导出数据")
async def export_data(db: AsyncSession = Depends(get_db)):
    """
    导出所有梦境数据（JSON 格式）
    """
    result = await db.execute(
        select(DreamModel).order_by(DreamModel.dream_date.desc())
    )
    
    dreams = result.scalars().all()
    
    export_data = [
        {
            "id": dream.id,
            "title": dream.title,
            "content": dream.content,
            "dream_date": dream.dream_date.isoformat(),
            "mood": dream.mood,
            "mood_intensity": dream.mood_intensity,
            "sleep_quality": dream.sleep_quality,
            "analysis": dream.analysis,
            "themes": dream.themes,
            "tags": [tag.name for tag in dream.tags]
        }
        for dream in dreams
    ]
    
    return {
        "success": True,
        "count": len(export_data),
        "exported_at": datetime.utcnow().isoformat(),
        "data": export_data
    }
