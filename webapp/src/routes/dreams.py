#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
梦境管理 API 路由
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from typing import Optional
from datetime import datetime, timedelta

from src.utils.database import get_db
from src.models.dream import DreamModel, TagModel, dream_tags
from src.models.schemas import (
    DreamCreate, DreamUpdate, DreamResponse, DreamListResponse,
    TagCreate, TagResponse, APIResponse
)

router = APIRouter()


# ==================== 梦境 CRUD ====================

@router.post("/", response_model=DreamResponse, summary="创建梦境")
async def create_dream(
    dream: DreamCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    快速记录一个新梦境
    
    - **content**: 梦境内容（必填）
    - **title**: 梦境标题（可选）
    - **mood**: 情绪状态
    - **mood_intensity**: 情绪强度 1-10
    - **tag_ids**: 标签 ID 列表
    """
    # 创建梦境
    db_dream = DreamModel(
        title=dream.title,
        content=dream.content,
        dream_date=dream.dream_date or datetime.utcnow(),
        mood=dream.mood,
        mood_intensity=dream.mood_intensity,
        sleep_quality=dream.sleep_quality,
        clarity=dream.clarity,
        is_lucid=1 if dream.is_lucid else 0,
        is_recurring=1 if dream.is_recurring else 0,
    )
    
    # 添加标签
    if dream.tag_ids:
        tags = await db.execute(
            select(TagModel).where(TagModel.id.in_(dream.tag_ids))
        )
        db_dream.tags = tags.scalars().all()
    
    db.add(db_dream)
    await db.commit()
    await db.refresh(db_dream)
    
    return db_dream


@router.get("/", response_model=DreamListResponse, summary="获取梦境列表")
async def get_dreams(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    mood: Optional[str] = Query(None, description="按情绪筛选"),
    tag: Optional[str] = Query(None, description="按标签筛选"),
    start_date: Optional[datetime] = Query(None, description="开始日期"),
    end_date: Optional[datetime] = Query(None, description="结束日期"),
    db: AsyncSession = Depends(get_db)
):
    """
    获取梦境列表，支持分页和筛选
    """
    # 构建查询
    query = select(DreamModel)
    
    # 筛选条件
    if mood:
        query = query.where(DreamModel.mood == mood)
    if start_date:
        query = query.where(DreamModel.dream_date >= start_date)
    if end_date:
        query = query.where(DreamModel.dream_date <= end_date)
    if tag:
        tag_subquery = select(TagModel.id).where(TagModel.name == tag)
        query = query.where(
            DreamModel.id.in_(
                select(dream_tags.c.dream_id).where(
                    dream_tags.c.tag_id.in_(tag_subquery)
                )
            )
        )
    
    # 按做梦日期倒序
    query = query.order_by(desc(DreamModel.dream_date))
    
    # 分页
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)
    
    # 执行查询
    result = await db.execute(query)
    dreams = result.scalars().all()
    
    # 获取总数
    count_query = select(func.count()).select_from(DreamModel)
    count_result = await db.execute(count_query)
    total = count_result.scalar()
    
    return DreamListResponse(
        items=dreams,
        total=total,
        page=page,
        page_size=page_size,
        has_more=offset + page_size < total
    )


@router.get("/{dream_id}", response_model=DreamResponse, summary="获取梦境详情")
async def get_dream(
    dream_id: int,
    db: AsyncSession = Depends(get_db)
):
    """获取单个梦境的详细信息"""
    result = await db.execute(
        select(DreamModel).where(DreamModel.id == dream_id)
    )
    dream = result.scalar_one_or_none()
    
    if not dream:
        raise HTTPException(status_code=404, detail="梦境不存在")
    
    return dream


@router.put("/{dream_id}", response_model=DreamResponse, summary="更新梦境")
async def update_dream(
    dream_id: int,
    update: DreamUpdate,
    db: AsyncSession = Depends(get_db)
):
    """更新梦境信息"""
    result = await db.execute(
        select(DreamModel).where(DreamModel.id == dream_id)
    )
    dream = result.scalar_one_or_none()
    
    if not dream:
        raise HTTPException(status_code=404, detail="梦境不存在")
    
    # 更新字段
    update_data = update.model_dump(exclude_unset=True)
    if 'tag_ids' in update_data:
        tag_ids = update_data.pop('tag_ids')
        if tag_ids is not None:
            tags = await db.execute(
                select(TagModel).where(TagModel.id.in_(tag_ids))
            )
            dream.tags = tags.scalars().all()
    
    for field, value in update_data.items():
        setattr(dream, field, value)
    
    await db.commit()
    await db.refresh(dream)
    
    return dream


@router.delete("/{dream_id}", response_model=APIResponse, summary="删除梦境")
async def delete_dream(
    dream_id: int,
    db: AsyncSession = Depends(get_db)
):
    """删除一个梦境"""
    result = await db.execute(
        select(DreamModel).where(DreamModel.id == dream_id)
    )
    dream = result.scalar_one_or_none()
    
    if not dream:
        raise HTTPException(status_code=404, detail="梦境不存在")
    
    await db.delete(dream)
    await db.commit()
    
    return APIResponse(success=True, message="梦境已删除")


# ==================== 标签管理 ====================

@router.get("/tags", response_model=List[TagResponse], summary="获取所有标签")
async def get_tags(db: AsyncSession = Depends(get_db)):
    """获取所有标签"""
    result = await db.execute(select(TagModel).order_by(TagModel.name))
    return result.scalars().all()


@router.post("/tags", response_model=TagResponse, summary="创建标签")
async def create_tag(
    tag: TagCreate,
    db: AsyncSession = Depends(get_db)
):
    """创建新标签"""
    # 检查是否已存在
    existing = await db.execute(
        select(TagModel).where(TagModel.name == tag.name)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="标签已存在")
    
    db_tag = TagModel(name=tag.name, color=tag.color)
    db.add(db_tag)
    await db.commit()
    await db.refresh(db_tag)
    
    return db_tag


@router.delete("/tags/{tag_id}", response_model=APIResponse, summary="删除标签")
async def delete_tag(
    tag_id: int,
    db: AsyncSession = Depends(get_db)
):
    """删除标签"""
    result = await db.execute(
        select(TagModel).where(TagModel.id == tag_id)
    )
    tag = result.scalar_one_or_none()
    
    if not tag:
        raise HTTPException(status_code=404, detail="标签不存在")
    
    await db.delete(tag)
    await db.commit()
    
    return APIResponse(success=True, message="标签已删除")


# ==================== 快捷操作 ====================

@router.post("/quick", response_model=DreamResponse, summary="快速记录梦境")
async def quick_record_dream(
    content: str,
    mood: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    快速记录梦境 - 30 秒内完成
    
    只需提供梦境内容，其他字段可选
    """
    dream = DreamModel(
        content=content,
        mood=mood,
        dream_date=datetime.utcnow(),
    )
    
    db.add(dream)
    await db.commit()
    await db.refresh(dream)
    
    return dream
