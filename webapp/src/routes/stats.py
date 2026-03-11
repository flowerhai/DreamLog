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
from typing import Optional

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


@router.get("/weekly-report", summary="获取梦境周报")
async def get_weekly_report(
    year: Optional[int] = None,
    week: Optional[int] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    获取梦境周报数据
    
    包括:
    - 基础统计（梦境总数/清醒梦/平均清晰度/连续记录）
    - 情绪分析（情绪分布/情绪趋势）
    - 主题分析（热门标签/新兴主题）
    - 时间分析（时间段分布/最活跃日期）
    - 亮点梦境（本周最佳梦境）
    - 智能洞察与建议
    
    参数:
    - year: 年份（可选，默认当前年）
    - week: 周数 1-53（可选，默认当前周）
    """
    # 确定目标周
    now = datetime.utcnow()
    target_year = year or now.year
    target_week = week or now.isocalendar()[1]
    
    # 计算周的起止日期（周一到周日）
    # ISO 周的第一天是周一
    jan_4 = datetime(target_year, 1, 4)
    start_of_week1 = jan_4 - timedelta(days=jan_4.isocalendar()[2] - 1)
    week_start = start_of_week1 + timedelta(weeks=target_week - 1)
    week_end = week_start + timedelta(days=6, hours=23, minutes=59, seconds=59)
    
    # 获取本周梦境
    result = await db.execute(
        select(DreamModel).where(
            DreamModel.dream_date >= week_start,
            DreamModel.dream_date <= week_end
        )
    )
    dreams = result.scalars().all()
    
    total_dreams = len(dreams)
    
    # 基础统计
    lucid_count = sum(1 for d in dreams if d.is_lucid)
    avg_clarity = round(sum(d.clarity or 3 for d in dreams) / total_dreams, 2) if total_dreams > 0 else 0
    avg_intensity = round(sum(d.mood_intensity or 5 for d in dreams) / total_dreams, 2) if total_dreams > 0 else 0
    
    # 计算连续记录天数
    recording_streak = 0
    if dreams:
        dream_dates = sorted(set(d.dream_date.date() for d in dreams))
        streak = 1
        for i in range(1, len(dream_dates)):
            if (dream_dates[i] - dream_dates[i-1]).days == 1:
                streak += 1
            else:
                streak = 1
        recording_streak = streak
    
    # 情绪分布
    mood_counts = Counter(d.mood for d in dreams if d.mood)
    emotion_distribution = dict(mood_counts)
    dominant_emotion = mood_counts.most_common(1)[0][0] if mood_counts else "未标记"
    
    # 情绪趋势（简化版：基于本周情绪评分）
    mood_trend = "stable"
    if dreams:
        positive_moods = ["happy", "excited", "peaceful"]
        negative_moods = ["sad", "anxious", "scared"]
        positive_count = sum(1 for d in dreams if d.mood in positive_moods)
        negative_count = sum(1 for d in dreams if d.mood in negative_moods)
        if positive_count > negative_count * 1.5:
            mood_trend = "improving"
        elif negative_count > positive_count * 1.5:
            mood_trend = "declining"
        elif abs(positive_count - negative_count) > 2:
            mood_trend = "fluctuating"
    
    # 主题分析
    all_tags = []
    for dream in dreams:
        if dream.tags:
            all_tags.extend([tag.name for tag in dream.tags])
    tag_counts = Counter(all_tags)
    top_tags = [{"tag": tag, "count": count} for tag, count in tag_counts.most_common(5)]
    
    # 时间分析
    dreams_by_time = {"清晨 (5-8 点)": 0, "上午 (8-12 点)": 0, "下午 (12-18 点)": 0, "夜晚 (18-23 点)": 0, "深夜 (23-5 点)": 0}
    dreams_by_weekday = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0}
    
    for dream in dreams:
        hour = dream.dream_date.hour
        if 5 <= hour < 8:
            dreams_by_time["清晨 (5-8 点)"] += 1
        elif 8 <= hour < 12:
            dreams_by_time["上午 (8-12 点)"] += 1
        elif 12 <= hour < 18:
            dreams_by_time["下午 (12-18 点)"] += 1
        elif 18 <= hour < 23:
            dreams_by_time["夜晚 (18-23 点)"] += 1
        else:
            dreams_by_time["深夜 (23-5 点)"] += 1
        
        weekday = dream.dream_date.isocalendar()[2]
        dreams_by_weekday[weekday] = dreams_by_weekday.get(weekday, 0) + 1
    
    most_active_day = max(dreams_by_weekday, key=dreams_by_weekday.get) if dreams_by_weekday else 1
    best_recall_hour = 7  # 简化：默认清晨
    
    # 亮点梦境
    highlight_dreams = []
    if dreams:
        # 最清晰的梦
        clearest = max(dreams, key=lambda d: d.clarity or 0)
        highlight_dreams.append({
            "id": str(clearest.id),
            "title": clearest.title or clearest.content[:30],
            "date": clearest.dream_date.isoformat(),
            "type": "highestClarity",
            "reason": f"清晰度：{clearest.clarity}/5"
        })
        
        # 如果有清醒梦
        lucid_dreams = [d for d in dreams if d.is_lucid]
        if lucid_dreams:
            highlight_dreams.append({
                "id": str(lucid_dreams[0].id),
                "title": lucid_dreams[0].title or lucid_dreams[0].content[:30],
                "date": lucid_dreams[0].dream_date.isoformat(),
                "type": "mostLucid",
                "reason": "清醒梦体验"
            })
    
    # 智能洞察
    insights = []
    if total_dreams > 0:
        if lucid_count > 0:
            insights.append({
                "type": "achievement",
                "title": "清醒梦成就",
                "description": f"本周记录了 {lucid_count} 个清醒梦，继续保持！",
                "icon": "👁️",
                "confidence": 0.9
            })
        
        if recording_streak >= 7:
            insights.append({
                "type": "achievement",
                "title": "连续记录",
                "description": f"已连续记录 {recording_streak} 天，养成好习惯！",
                "icon": "🔥",
                "confidence": 0.95
            })
        
        if len(top_tags) > 0:
            insights.append({
                "type": "pattern",
                "title": "主题模式",
                "description": f"本周最常出现的主题：{top_tags[0]['tag']} ({top_tags[0]['count']}次)",
                "icon": "🔍",
                "confidence": 0.8
            })
    
    # 个性化建议
    suggestions = []
    if total_dreams == 0:
        suggestions.append("本周还没有记录梦境，开始记录你的第一个梦吧！")
    else:
        if avg_clarity < 3:
            suggestions.append("尝试在醒来后立即记录，可以提高梦境清晰度")
        if lucid_count == 0 and total_dreams >= 3:
            suggestions.append("试试在睡前进行现实检查，可能帮助实现清醒梦")
        if recording_streak < 3:
            suggestions.append("设定固定时间记录梦境，有助于养成习惯")
        suggestions.append("继续保持良好的记录习惯！")
    
    # 与上周对比（简化版）
    last_week_start = week_start - timedelta(days=7)
    last_week_end = week_start - timedelta(seconds=1)
    last_week_result = await db.execute(
        select(DreamModel).where(
            DreamModel.dream_date >= last_week_start,
            DreamModel.dream_date <= last_week_end
        )
    )
    last_week_dreams = last_week_result.scalars().all()
    last_week_count = len(last_week_dreams)
    
    dreams_change = total_dreams - last_week_count
    dreams_change_percent = round((dreams_change / last_week_count * 100) if last_week_count > 0 else 0, 1)
    
    comparison = None
    if last_week_count > 0:
        comparison = {
            "dreamsChange": dreams_change,
            "dreamsChangePercent": dreams_change_percent,
            "clarityChange": 0,
            "lucidChange": 0,
            "streakChange": 0,
            "isBetter": dreams_change >= 0
        }
    
    # 构建周报数据
    weekly_report = {
        "id": f"{target_year}-W{target_week:02d}",
        "weekStartDate": week_start.isoformat(),
        "weekEndDate": week_end.isoformat(),
        "generatedAt": now.isoformat(),
        "totalDreams": total_dreams,
        "lucidDreams": lucid_count,
        "averageClarity": avg_clarity,
        "averageIntensity": avg_intensity,
        "recordingStreak": recording_streak,
        "emotionDistribution": emotion_distribution,
        "dominantEmotion": dominant_emotion,
        "moodTrend": mood_trend,
        "topTags": top_tags,
        "emergingThemes": [],
        "fadingThemes": [],
        "dreamsByTimeOfDay": dreams_by_time,
        "dreamsByWeekday": dreams_by_weekday,
        "mostActiveDay": most_active_day,
        "bestRecallHour": best_recall_hour,
        "highlightDreams": highlight_dreams,
        "insights": insights,
        "suggestions": suggestions,
        "lastWeekComparison": comparison
    }
    
    return {
        "success": True,
        "data": weekly_report
    }
