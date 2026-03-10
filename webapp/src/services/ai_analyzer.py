#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI 梦境解析服务
"""

import json
from datetime import datetime
from typing import Dict, Any, Optional
from loguru import logger

from src.utils.config import settings


class AIAnalyzer:
    """AI 梦境解析器"""
    
    def __init__(self):
        self.api_key = settings.LLM_API_KEY
        self.model = settings.LLM_MODEL
        self._client = None
        
    def _get_client(self):
        """获取 API 客户端"""
        if self._client is None and self.api_key:
            try:
                from openai import AsyncOpenAI
                self._client = AsyncOpenAI(api_key=self.api_key)
            except ImportError:
                logger.warning("openai 库未安装，使用模拟解析")
        return self._client
    
    async def analyze(self, dream_content: str, dream_date: datetime = None) -> Dict[str, Any]:
        """
        分析梦境内容
        
        返回:
        - summary: 摘要
        - themes: 主题列表
        - symbols: 象征物列表
        - interpretation: 详细解读
        - psychological_meaning: 心理学含义
        - emotional_state: 情绪状态
        - suggestions: 建议
        """
        client = self._get_client()
        
        if client and self.api_key:
            return await self._analyze_with_llm(dream_content)
        else:
            return self._analyze_mock(dream_content)
    
    async def _analyze_with_llm(self, content: str) -> Dict[str, Any]:
        """使用 LLM 进行真实解析"""
        try:
            prompt = f"""
请分析以下梦境内容，以 JSON 格式返回分析结果：

梦境内容：
{content}

请返回以下格式的 JSON：
{{
    "summary": "50 字以内的梦境摘要",
    "themes": ["主题 1", "主题 2", ...],
    "symbols": [{{"name": "象征物", "meaning": "含义"}}],
    "interpretation": "详细的梦境解读（200-300 字）",
    "psychological_meaning": "从心理学角度的含义分析",
    "emotional_state": "梦境反映的情绪状态",
    "suggestions": ["建议 1", "建议 2", ...]
}}
"""
            response = await self._client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "你是一位专业的梦境解析师，擅长从心理学和象征学角度分析梦境。"},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=1000
            )
            
            result_text = response.choices[0].message.content.strip()
            
            # 提取 JSON
            if result_text.startswith("```json"):
                result_text = result_text[7:-3].strip()
            elif result_text.startswith("```"):
                result_text = result_text[3:-3].strip()
            
            return json.loads(result_text)
            
        except Exception as e:
            logger.error(f"LLM 解析失败：{e}")
            return self._analyze_mock(content)
    
    def _analyze_mock(self, content: str) -> Dict[str, Any]:
        """模拟解析（无 API 时使用）"""
        # 简单的关键词匹配
        content_lower = content.lower()
        
        themes = []
        symbols = []
        
        # 常见梦境主题检测
        theme_keywords = {
            "飞行": ["飞", "飞翔", "空中", "天空"],
            "坠落": ["掉", "坠落", "跌落", "下滑"],
            "追逐": ["追", "逃跑", "追赶", "被追"],
            "考试": ["考试", "考场", "试卷", "题目"],
            "牙齿": ["牙齿", "牙", "掉牙"],
            "水": ["水", "河", "海", "湖", "游泳", "溺水"],
            "蛇": ["蛇", "蟒蛇"],
            "死亡": ["死", "死亡", "葬礼", "墓地"],
            "迷路": ["迷路", "找不到", "陌生"],
        }
        
        for theme, keywords in theme_keywords.items():
            if any(kw in content_lower for kw in keywords):
                themes.append(theme)
                symbols.append({"name": theme, "meaning": self._get_symbol_meaning(theme)})
        
        # 默认主题
        if not themes:
            themes = ["日常生活"]
            symbols = [{"name": "日常场景", "meaning": "反映日常生活的状态"}]
        
        # 情绪检测
        emotions = {
            "焦虑": ["焦虑", "紧张", "担心", "害怕"],
            "快乐": ["开心", "快乐", "高兴", "愉快"],
            "恐惧": ["害怕", "恐惧", "恐怖", "惊恐"],
            "平静": ["平静", "安宁", "放松"],
            "困惑": ["困惑", "迷茫", "不解"],
        }
        
        emotional_state = "平静"
        for emotion, keywords in emotions.items():
            if any(kw in content_lower for kw in keywords):
                emotional_state = emotion
                break
        
        return {
            "summary": content[:50] + "..." if len(content) > 50 else content,
            "themes": themes[:5],
            "symbols": symbols[:5],
            "interpretation": f"这个梦境反映了你近期的心理状态。梦见{'、'.join(themes)}通常与内心深处的某些情感或担忧有关。建议你关注最近的压力源，适当放松身心。",
            "psychological_meaning": f"从心理学角度看，这个梦境可能反映了你潜意识中对{themes[0] if themes else '某些事物'}的关注或焦虑。梦境是内心情感的投射，值得认真对待。",
            "emotional_state": emotional_state,
            "suggestions": [
                "记录梦境细节，寻找模式",
                "关注近期的情绪变化",
                "适当进行放松练习",
                "保持规律的作息时间"
            ]
        }
    
    def _get_symbol_meaning(self, symbol: str) -> str:
        """获取象征物含义"""
        meanings = {
            "飞行": "象征自由、解脱或对现状的超越",
            "坠落": "象征失控感、不安全感或恐惧",
            "追逐": "象征逃避问题或压力",
            "考试": "象征被评价的焦虑或自我要求",
            "牙齿": "象征成长、变化或对衰老的担忧",
            "水": "象征情感、潜意识或生命力",
            "蛇": "象征转化、治愈或潜在的威胁",
            "死亡": "象征结束、转变或新的开始",
            "迷路": "象征迷茫、缺乏方向感",
        }
        return meanings.get(symbol, "需要进一步分析")
    
    async def generate_image_prompt(self, dream_content: str) -> str:
        """生成用于 AI 绘画的 prompt"""
        client = self._get_client()
        
        if client and self.api_key:
            try:
                prompt = f"""
根据以下梦境内容，生成一个适合 AI 绘画的英文 prompt（200 字以内）：

梦境内容：{dream_content}

要求：
- 使用英文
- 描述视觉元素、色彩、氛围
- 风格：surreal, dreamlike, artistic
- 不要包含文字说明
"""
                response = await self._client.chat.completions.create(
                    model=self.model,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.7,
                    max_tokens=300
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.error(f"生成 prompt 失败：{e}")
        
        # 默认 prompt
        return f"surreal dream scene, artistic, dreamlike atmosphere, {dream_content[:100]}"


# 单例
analyzer = AIAnalyzer()
