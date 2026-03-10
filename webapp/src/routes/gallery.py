#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
梦境画廊 API 路由
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime

from src.utils.database import get_db
from src.models.dream import DreamModel
from src.models.schemas import ImageGenRequest, ImageGenResponse, APIResponse
from src.services.ai_analyzer import analyzer
from src.services.image_gen import image_generator

router = APIRouter()


@router.post("/generate", response_model=ImageGenResponse, summary="生成梦境图像")
async def generate_image(
    request: ImageGenRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    为梦境生成 AI 图像
    
    - **dream_id**: 梦境 ID
    - **style**: 艺术风格 (surreal, realistic, abstract, watercolor)
    - **regenerate**: 是否重新生成
    """
    # 获取梦境
    result = await db.execute(
        select(DreamModel).where(DreamModel.id == request.dream_id)
    )
    dream = result.scalar_one_or_none()
    
    if not dream:
        raise HTTPException(status_code=404, detail="梦境不存在")
    
    # 检查是否已有图像
    if dream.generated_image_url and not request.regenerate:
        return ImageGenResponse(
            dream_id=dream.id,
            image_url=dream.generated_image_url,
            prompt=dream.image_prompt or "",
            generated_at=dream.updated_at
        )
    
    # 获取或生成 prompt
    image_prompt = dream.image_prompt
    if not image_prompt:
        # 如果没有 prompt，使用 AI 生成
        if dream.analysis:
            # 基于解析结果生成
            analysis = dream.analysis
            themes = analysis.get('themes', [])
            symbols = analysis.get('symbols', [])
            content_summary = dream.content[:200]
            
            prompt_text = f"{content_summary}. Themes: {', '.join(themes)}. Symbols: {', '.join([s.get('name', '') for s in symbols])}"
        else:
            # 直接使用梦境内容
            prompt_text = dream.content[:300]
        
        image_prompt = await analyzer.generate_image_prompt(prompt_text)
        dream.image_prompt = image_prompt
    
    # 生成图像
    image_result = await image_generator.generate(
        prompt=image_prompt,
        style=request.style
    )
    
    # 保存结果
    dream.generated_image_url = image_result['image_url']
    
    await db.commit()
    await db.refresh(dream)
    
    return ImageGenResponse(
        dream_id=dream.id,
        image_url=image_result['image_url'],
        prompt=image_prompt,
        generated_at=datetime.utcnow()
    )


@router.post("/{dream_id}/regenerate", response_model=ImageGenResponse, summary="重新生成图像")
async def regenerate_image(
    dream_id: int,
    style: str = "surreal",
    db: AsyncSession = Depends(get_db)
):
    """重新生成梦境图像"""
    request = ImageGenRequest(dream_id=dream_id, style=style, regenerate=True)
    return await generate_image(request, db)


@router.get("/{dream_id}/image", summary="获取梦境图像")
async def get_dream_image(
    dream_id: int,
    db: AsyncSession = Depends(get_db)
):
    """获取梦境的 AI 生成图像"""
    result = await db.execute(
        select(DreamModel).where(DreamModel.id == dream_id)
    )
    dream = result.scalar_one_or_none()
    
    if not dream:
        raise HTTPException(status_code=404, detail="梦境不存在")
    
    if not dream.generated_image_url:
        raise HTTPException(status_code=404, detail="尚未生成图像，请先调用生成接口")
    
    return {
        "dream_id": dream.id,
        "image_url": dream.generated_image_url,
        "prompt": dream.image_prompt
    }


@router.post("/batch/generate", response_model=APIResponse, summary="批量生成图像")
async def batch_generate_images(
    dream_ids: list[int],
    style: str = "surreal",
    db: AsyncSession = Depends(get_db)
):
    """
    批量为多个梦境生成图像
    
    适合初次使用或批量生成
    """
    success_count = 0
    error_count = 0
    
    for dream_id in dream_ids:
        try:
            result = await db.execute(
                select(DreamModel).where(DreamModel.id == dream_id)
            )
            dream = result.scalar_one_or_none()
            
            if dream and not dream.generated_image_url:
                # 生成 prompt
                if not dream.image_prompt:
                    dream.image_prompt = await analyzer.generate_image_prompt(dream.content[:300])
                
                # 生成图像
                image_result = await image_generator.generate(
                    prompt=dream.image_prompt,
                    style=style
                )
                
                dream.generated_image_url = image_result['image_url']
                success_count += 1
        except Exception as e:
            error_count += 1
    
    await db.commit()
    
    return APIResponse(
        success=True,
        message=f"批量生成完成：成功{success_count}个，失败{error_count}个",
        data={"success": success_count, "error": error_count}
    )


@router.get("/gallery", summary="获取梦境画廊")
async def get_gallery(
    limit: int = 20,
    db: AsyncSession = Depends(get_db)
):
    """
    获取梦境画廊 - 所有已生成图像的梦境
    """
    result = await db.execute(
        select(DreamModel)
        .where(DreamModel.generated_image_url.isnot(None))
        .order_by(DreamModel.created_at.desc())
        .limit(limit)
    )
    
    dreams = result.scalars().all()
    
    return {
        "items": [
            {
                "id": dream.id,
                "title": dream.title,
                "image_url": dream.generated_image_url,
                "created_at": dream.created_at.isoformat()
            }
            for dream in dreams
        ],
        "total": len(dreams)
    }
