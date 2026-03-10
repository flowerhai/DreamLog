#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI 图像生成服务
"""

import base64
from pathlib import Path
from datetime import datetime
from typing import Optional
from loguru import logger

from src.utils.config import settings


class ImageGenerator:
    """AI 图像生成器"""
    
    def __init__(self):
        self.api_key = settings.IMAGE_GEN_API_KEY
        self.model = settings.IMAGE_GEN_MODEL
        self._client = None
        
    def _get_client(self):
        """获取 API 客户端"""
        if self._client is None and self.api_key:
            try:
                from openai import AsyncOpenAI
                self._client = AsyncOpenAI(api_key=self.api_key)
            except ImportError:
                logger.warning("openai 库未安装，使用模拟生成")
        return self._client
    
    async def generate(
        self,
        prompt: str,
        style: str = "surreal",
        size: str = "1024x1024"
    ) -> dict:
        """
        生成梦境图像
        
        参数:
        - prompt: 图像描述
        - style: 艺术风格 (surreal, realistic, abstract, watercolor)
        - size: 图像尺寸
        
        返回:
        - image_url: 图像 URL 或 base64
        - prompt: 使用的 prompt
        """
        client = self._get_client()
        
        # 风格前缀
        style_prefixes = {
            "surreal": "surreal dreamlike painting,",
            "realistic": "photorealistic,",
            "abstract": "abstract art,",
            "watercolor": "watercolor painting,",
            "oil": "oil painting,",
            "digital": "digital art,",
        }
        
        enhanced_prompt = f"{style_prefixes.get(style, 'surreal dreamlike painting,')} {prompt}"
        
        if client and self.api_key:
            return await self._generate_with_dalle(enhanced_prompt, size)
        else:
            return self._generate_mock(enhanced_prompt, style)
    
    async def _generate_with_dalle(self, prompt: str, size: str) -> dict:
        """使用 DALL-E 生成图像"""
        try:
            response = await self._client.images.generate(
                model=self.model,
                prompt=prompt,
                size=size,
                quality="standard",
                n=1
            )
            
            image_url = response.data[0].url
            
            return {
                "image_url": image_url,
                "prompt": prompt,
                "generated_at": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"DALL-E 生成失败：{e}")
            return self._generate_mock(prompt, "surreal")
    
    def _generate_mock(self, prompt: str, style: str) -> dict:
        """模拟生成（无 API 时使用）"""
        # 返回一个占位图
        return {
            "image_url": f"https://via.placeholder.com/1024x1024/6B7280/FFFFFF?text=Dream+Image",
            "prompt": prompt,
            "generated_at": datetime.utcnow().isoformat(),
            "mock": True
        }
    
    async def save_image(self, image_data: bytes, dream_id: int) -> str:
        """保存图像到本地"""
        images_dir = settings.DATA_DIR / "images"
        images_dir.mkdir(parents=True, exist_ok=True)
        
        filename = f"dream_{dream_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.png"
        filepath = images_dir / filename
        
        with open(filepath, 'wb') as f:
            f.write(image_data)
        
        return f"/static/images/{filename}"


# 单例
image_generator = ImageGenerator()
