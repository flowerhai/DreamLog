#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
模式分析服务 - 发现梦境中的重复模式和趋势
"""

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, List, Any
from datetime import datetime, timedelta
from collections import Counter
import json

from src.models.dream import DreamModel


class PatternAnalyzer:
    """梦境模式分析器"""
    
    async def analyze_patterns(self, db: AsyncSession, user_id: int = None) -> Dict[str, Any]:
        """
        分析梦境模式
        
        返回:
        - recurring_themes: 重复主题
        - mood_patterns: 情绪模式
        - time_patterns: 时间规律
        - word_frequency: 高频词
        """
        # 获取所有梦境
        query = select(DreamModel).order_by(DreamModel.dream_date.desc())
        result = await db.execute(query)
        dreams = result.scalars().all()
        
        if not dreams:
            return self._empty_result()
        
        # 分析主题模式
        all_themes = []
        for dream in dreams:
            if dream.themes:
                all_themes.extend(dream.themes)
        
        theme_counts = Counter(all_themes)
        recurring_themes = [
            {"theme": theme, "count": count}
            for theme, count in theme_counts.most_common(10)
            if count >= 2
        ]
        
        # 分析情绪模式
        mood_counts = Counter([d.mood for d in dreams if d.mood])
        mood_patterns = [
            {"mood": mood, "count": count, "percentage": round(count / len(dreams) * 100, 1)}
            for mood, count in mood_counts.most_common()
        ]
        
        # 分析时间规律
        time_patterns = self._analyze_time_patterns(dreams)
        
        # 分析梦境内容高频词
        word_frequency = self._analyze_word_frequency(dreams)
        
        # 检测重复梦境
        recurring_dreams = self._detect_recurring_dreams(dreams)
        
        return {
            "recurring_themes": recurring_themes,
            "mood_patterns": mood_patterns,
            "time_patterns": time_patterns,
            "word_frequency": word_frequency[:20],
            "recurring_dreams": recurring_dreams,
            "total_dreams": len(dreams),
            "analysis_date": datetime.utcnow().isoformat()
        }
    
    def _analyze_time_patterns(self, dreams: List[DreamModel]) -> Dict[str, Any]:
        """分析时间规律"""
        # 按星期统计
        weekday_counts = Counter([d.dream_date.weekday() for d in dreams])
        weekday_names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
        weekday_distribution = [
            {"day": weekday_names[i], "count": weekday_counts.get(i, 0)}
            for i in range(7)
        ]
        
        # 按月份统计
        month_counts = Counter([d.dream_date.month for d in dreams])
        month_distribution = [
            {"month": f"{i}月", "count": month_counts.get(i, 0)}
            for i in range(1, 13)
        ]
        
        # 发现活跃期
        recent_30_days = [
            d for d in dreams
            if d.dream_date >= datetime.utcnow() - timedelta(days=30)
        ]
        
        return {
            "weekday_distribution": weekday_distribution,
            "month_distribution": month_distribution,
            "recent_30_days_count": len(recent_30_days),
            "most_active_day": weekday_names[weekday_counts.most_common(1)[0][0]] if weekday_counts else None
        }
    
    def _analyze_word_frequency(self, dreams: List[DreamModel]) -> List[Dict]:
        """分析高频词"""
        # 简单分词（中文需要更复杂的处理）
        stop_words = {'的', '了', '是', '在', '我', '有', '和', '就', '不', '人', '都', '一', '就', '着', '这', '那', '他', '她', '它', '们', '这个', '那个', '什么', '怎么', '为什么', '但是', '然后', '所以', '因为', '如果', '虽然', '但是', '而且', '或者'}
        
        word_counts = Counter()
        for dream in dreams:
            # 简单按字符分组（实际应该用分词工具）
            content = dream.content
            for word in content:
                if len(word.strip()) > 0 and word not in stop_words:
                    word_counts[word] += 1
        
        return [
            {"word": word, "count": count}
            for word, count in word_counts.most_common(20)
        ]
    
    def _detect_recurring_dreams(self, dreams: List[DreamModel]) -> List[Dict]:
        """检测重复梦境"""
        # 基于主题相似度检测
        theme_groups = {}
        for dream in dreams:
            if dream.themes:
                key = tuple(sorted(dream.themes[:3]))
                if key not in theme_groups:
                    theme_groups[key] = []
                theme_groups[key].append({
                    "id": dream.id,
                    "date": dream.dream_date.isoformat(),
                    "title": dream.title or dream.content[:20]
                })
        
        recurring = []
        for themes, dream_list in theme_groups.items():
            if len(dream_list) >= 2:
                recurring.append({
                    "themes": list(themes),
                    "occurrences": len(dream_list),
                    "dreams": dream_list
                })
        
        return sorted(recurring, key=lambda x: x['occurrences'], reverse=True)[:5]
    
    def _empty_result(self) -> Dict[str, Any]:
        """空结果"""
        return {
            "recurring_themes": [],
            "mood_patterns": [],
            "time_patterns": {},
            "word_frequency": [],
            "recurring_dreams": [],
            "total_dreams": 0,
            "analysis_date": datetime.utcnow().isoformat()
        }


# 单例
pattern_analyzer = PatternAnalyzer()
