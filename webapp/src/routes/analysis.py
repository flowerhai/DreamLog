#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI 解析 API 路由
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
import json

from src.utils.database import get_db
from src.models.dream import DreamModel
from src.models.schemas import AnalysisRequest, AnalysisResponse, DreamAnalysis, APIResponse
from src.services.ai_analyzer import analyzer

router = APIRouter()


@router.post("/analyze", response_model=AnalysisResponse, summary="AI 解析梦境")
async def analyze_dream(
    request: AnalysisRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    使用 AI 解析梦境内容
    
    - **dream_id**: 梦境 ID
    - **regenerate**: 是否重新生成（默认 false）
    """
    # 获取梦境
    result = await db.execute(
        select(DreamModel).where(DreamModel.id == request.dream_id)
    )
    dream = result.scalar_one_or_none()
    
    if not dream:
        raise HTTPException(status_code=404, detail="梦境不存在")
    
    # 检查是否已有解析
    if dream.analysis and not request.regenerate:
        return AnalysisResponse(
            dream_id=dream.id,
            analysis=DreamAnalysis(**dream.analysis),
            generated_at=dream.updated_at
        )
    
    # 进行 AI 解析
    analysis_result = await analyzer.analyze(dream.content, dream.dream_date)
    
    # 保存到数据库
    dream.analysis = analysis_result
    dream.summary = analysis_result.get('summary')
    dream.themes = analysis_result.get('themes', [])
    dream.symbols = analysis_result.get('symbols', [])
    
    await db.commit()
    await db.refresh(dream)
    
    return AnalysisResponse(
        dream_id=dream.id,
        analysis=DreamAnalysis(**analysis_result),
        generated_at=datetime.utcnow()
    )


@router.post("/{dream_id}/regenerate", response_model=AnalysisResponse, summary="重新解析梦境")
async def regenerate_analysis(
    dream_id: int,
    db: AsyncSession = Depends(get_db)
):
    """重新生成梦境解析"""
    request = AnalysisRequest(dream_id=dream_id, regenerate=True)
    return await analyze_dream(request, db)


@router.get("/{dream_id}/analysis", response_model=DreamAnalysis, summary="获取解析结果")
async def get_analysis(
    dream_id: int,
    db: AsyncSession = Depends(get_db)
):
    """获取梦境的 AI 解析结果"""
    result = await db.execute(
        select(DreamModel).where(DreamModel.id == dream_id)
    )
    dream = result.scalar_one_or_none()
    
    if not dream:
        raise HTTPException(status_code=404, detail="梦境不存在")
    
    if not dream.analysis:
        raise HTTPException(status_code=404, detail="尚未解析，请先调用分析接口")
    
    return DreamAnalysis(**dream.analysis)


@router.post("/batch/analyze", response_model=APIResponse, summary="批量解析梦境")
async def batch_analyze(
    dream_ids: list[int],
    db: AsyncSession = Depends(get_db)
):
    """
    批量解析多个梦境
    
    适合初次使用或重新解析大量梦境
    """
    success_count = 0
    error_count = 0
    
    for dream_id in dream_ids:
        try:
            result = await db.execute(
                select(DreamModel).where(DreamModel.id == dream_id)
            )
            dream = result.scalar_one_or_none()
            
            if dream and not dream.analysis:
                analysis_result = await analyzer.analyze(dream.content, dream.dream_date)
                dream.analysis = analysis_result
                dream.summary = analysis_result.get('summary')
                dream.themes = analysis_result.get('themes', [])
                dream.symbols = analysis_result.get('symbols', [])
                success_count += 1
        except Exception as e:
            error_count += 1
    
    await db.commit()
    
    return APIResponse(
        success=True,
        message=f"批量解析完成：成功{success_count}个，失败{error_count}个",
        data={"success": success_count, "error": error_count}
    )
