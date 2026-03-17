"""
DreamLog Web - 梦境挑战 API 路由
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import random

router = APIRouter()

# ==================== 数据模型 ====================

class Task(BaseModel):
    id: int
    title: str
    completed: bool = False

class Challenge(BaseModel):
    id: int
    title: str
    type: str  # daily, weekly, special, achievement
    difficulty: str  # easy, medium, hard, expert
    description: str
    tasks: List[Task]
    points: int
    badges: List[str]
    status: str = "available"  # available, in-progress, completed
    progress: int = 0
    created_at: Optional[str] = None
    completed_at: Optional[str] = None

class Badge(BaseModel):
    id: int
    icon: str
    name: str
    desc: str
    unlocked: bool = False
    unlocked_at: Optional[str] = None

class ChallengesResponse(BaseModel):
    success: bool
    data: List[Challenge]
    total: int

class ChallengeDetailResponse(BaseModel):
    success: bool
    data: Challenge

class BadgesResponse(BaseModel):
    success: bool
    data: List[Badge]
    total: int
    unlocked_count: int

class StatsResponse(BaseModel):
    success: bool
    data: Dict[str, Any]

class UpdateTaskRequest(BaseModel):
    completed: bool

class StartChallengeResponse(BaseModel):
    success: bool
    message: str
    data: Optional[Challenge] = None

# ==================== 预设数据 ====================

PRESET_CHALLENGES = [
    {
        "id": 1,
        "title": "晨间记录者",
        "type": "daily",
        "difficulty": "easy",
        "description": "养成晨间记录梦境的好习惯",
        "tasks": [
            {"id": 1, "title": "记录 1 个梦境", "completed": False},
            {"id": 2, "title": "添加情绪标签", "completed": False},
            {"id": 3, "title": "添加至少 2 个标签", "completed": False}
        ],
        "points": 100,
        "badges": ["🌅"],
        "status": "available"
    },
    {
        "id": 2,
        "title": "一周达人",
        "type": "weekly",
        "difficulty": "medium",
        "description": "连续一周记录梦境",
        "tasks": [
            {"id": 1, "title": "连续记录 7 天", "completed": False},
            {"id": 2, "title": "总计 7 个梦境", "completed": False},
            {"id": 3, "title": "平均清晰度≥3", "completed": False}
        ],
        "points": 500,
        "badges": ["📅", "🔥"],
        "status": "in-progress"
    },
    {
        "id": 3,
        "title": "清醒梦初体验",
        "type": "special",
        "difficulty": "hard",
        "description": "体验并记录你的第一个清醒梦",
        "tasks": [
            {"id": 1, "title": "记录 1 个清醒梦", "completed": False},
            {"id": 2, "title": "清晰度≥4", "completed": False},
            {"id": 3, "title": "添加详细解析", "completed": False}
        ],
        "points": 300,
        "badges": ["🌟"],
        "status": "available"
    },
    {
        "id": 4,
        "title": "创意梦境探索",
        "type": "weekly",
        "difficulty": "medium",
        "description": "从梦境中获取创意灵感",
        "tasks": [
            {"id": 1, "title": "记录 3 个创意相关的梦", "completed": False},
            {"id": 2, "title": "使用 AI 解析", "completed": False},
            {"id": 3, "title": "生成 1 张 AI 绘画", "completed": False}
        ],
        "points": 400,
        "badges": ["🎨", "💡"],
        "status": "available"
    },
    {
        "id": 5,
        "title": "飞行梦大师",
        "type": "special",
        "difficulty": "expert",
        "description": "探索飞行主题的梦境",
        "tasks": [
            {"id": 1, "title": "记录 5 个飞行梦", "completed": False},
            {"id": 2, "title": "平均清晰度≥4", "completed": False},
            {"id": 3, "title": "创建 1 个 AR 场景", "completed": False}
        ],
        "points": 800,
        "badges": ["✈️", "👑"],
        "status": "available"
    },
    {
        "id": 6,
        "title": "分享先锋",
        "type": "achievement",
        "difficulty": "easy",
        "description": "分享你的梦境到社区",
        "tasks": [
            {"id": 1, "title": "分享 1 个梦境", "completed": False},
            {"id": 2, "title": "获得 5 个点赞", "completed": False}
        ],
        "points": 200,
        "badges": ["📤"],
        "status": "available"
    },
    {
        "id": 7,
        "title": "冥想修行者",
        "type": "daily",
        "difficulty": "easy",
        "description": "通过冥想提升梦境质量",
        "tasks": [
            {"id": 1, "title": "完成 1 次冥想", "completed": False},
            {"id": 2, "title": "记录冥想后的梦", "completed": False}
        ],
        "points": 150,
        "badges": ["🧘"],
        "status": "available"
    },
    {
        "id": 8,
        "title": "梦境收藏家",
        "type": "achievement",
        "difficulty": "medium",
        "description": "收集 50 个梦境",
        "tasks": [
            {"id": 1, "title": "记录 50 个梦境", "completed": False},
            {"id": 2, "title": "平均清晰度≥3.5", "completed": False}
        ],
        "points": 1000,
        "badges": ["📚", "💎"],
        "status": "in-progress"
    },
    {
        "id": 9,
        "title": "夜间探索者",
        "type": "daily",
        "difficulty": "easy",
        "description": "记录深夜时段的梦境",
        "tasks": [
            {"id": 1, "title": "记录 1 个深夜梦", "completed": False},
            {"id": 2, "title": "添加梦境时间标签", "completed": False}
        ],
        "points": 120,
        "badges": ["🌙"],
        "status": "available"
    },
    {
        "id": 10,
        "title": "解析大师",
        "type": "weekly",
        "difficulty": "medium",
        "description": "深入解析梦境含义",
        "tasks": [
            {"id": 1, "title": "使用 AI 解析 5 个梦", "completed": False},
            {"id": 2, "title": "添加个人反思", "completed": False},
            {"id": 3, "title": "标记 3 个主题", "completed": False}
        ],
        "points": 350,
        "badges": ["🔮"],
        "status": "available"
    }
]

PRESET_BADGES = [
    {"id": 1, "icon": "🌅", "name": "晨鸟", "desc": "连续 7 天晨间记录", "unlocked": True},
    {"id": 2, "icon": "🔥", "name": "坚持大师", "desc": "连续记录 30 天", "unlocked": False},
    {"id": 3, "icon": "🌟", "name": "清醒觉醒", "desc": "记录第一个清醒梦", "unlocked": False},
    {"id": 4, "icon": "📤", "name": "分享先锋", "desc": "分享 10 个梦境", "unlocked": True},
    {"id": 5, "icon": "🎨", "name": "艺术家", "desc": "生成 20 张 AI 绘画", "unlocked": False},
    {"id": 6, "icon": "🧘", "name": "冥想者", "desc": "完成 10 次冥想", "unlocked": False},
    {"id": 7, "icon": "📚", "name": "收藏家", "desc": "记录 100 个梦境", "unlocked": False},
    {"id": 8, "icon": "💎", "name": "钻石梦", "desc": "连续清晰度≥4 达 7 天", "unlocked": False},
    {"id": 9, "icon": "✈️", "name": "飞行家", "desc": "记录 20 个飞行梦", "unlocked": False},
    {"id": 10, "icon": "👑", "name": "梦境之王", "desc": "完成所有挑战", "unlocked": False},
    {"id": 11, "icon": "🌙", "name": "夜行者", "desc": "记录 50 个夜间梦境", "unlocked": True},
    {"id": 12, "icon": "💡", "name": "灵感大师", "desc": "从梦境获得 10 个创意", "unlocked": False},
    {"id": 13, "icon": "🔮", "name": "解梦师", "desc": "解析 50 个梦境", "unlocked": False},
    {"id": 14, "icon": "⚡", "name": "闪电记录", "desc": "1 分钟内快速记录梦境", "unlocked": False},
    {"id": 15, "icon": "🎯", "name": "目标达成", "desc": "完成 25 个挑战", "unlocked": False}
]

# ==================== 辅助函数 ====================

def calculate_progress(challenge: dict) -> int:
    """计算挑战进度百分比"""
    if not challenge["tasks"]:
        return 0
    completed = sum(1 for task in challenge["tasks"] if task["completed"])
    return round((completed / len(challenge["tasks"])) * 100)

def get_challenge_by_id(challenge_id: int) -> Optional[dict]:
    """根据 ID 获取挑战"""
    for challenge in PRESET_CHALLENGES:
        if challenge["id"] == challenge_id:
            return challenge
    return None

def get_badge_by_id(badge_id: int) -> Optional[dict]:
    """根据 ID 获取徽章"""
    for badge in PRESET_BADGES:
        if badge["id"] == badge_id:
            return badge
    return None

# ==================== API 路由 ====================

@router.get("/challenges", response_model=ChallengesResponse)
async def get_challenges(
    filter_type: Optional[str] = None,
    status: Optional[str] = None
):
    """
    获取挑战列表
    
    - **filter_type**: 筛选类型 (daily/weekly/special/achievement)
    - **status**: 筛选状态 (available/in-progress/completed)
    """
    filtered_challenges = PRESET_CHALLENGES.copy()
    
    # 应用筛选
    if filter_type:
        filtered_challenges = [c for c in filtered_challenges if c["type"] == filter_type]
    
    if status:
        filtered_challenges = [c for c in filtered_challenges if c["status"] == status]
    
    # 计算进度
    for challenge in filtered_challenges:
        challenge["progress"] = calculate_progress(challenge)
    
    return ChallengesResponse(
        success=True,
        data=filtered_challenges,
        total=len(filtered_challenges)
    )

@router.get("/challenges/{challenge_id}", response_model=ChallengeDetailResponse)
async def get_challenge_detail(challenge_id: int):
    """获取挑战详情"""
    challenge = get_challenge_by_id(challenge_id)
    
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    challenge_copy = challenge.copy()
    challenge_copy["progress"] = calculate_progress(challenge)
    
    return ChallengeDetailResponse(
        success=True,
        data=challenge_copy
    )

@router.get("/badges", response_model=BadgesResponse)
async def get_badges(
    unlocked_only: Optional[bool] = False
):
    """
    获取徽章列表
    
    - **unlocked_only**: 只返回已解锁的徽章
    """
    filtered_badges = PRESET_BADGES.copy()
    
    if unlocked_only:
        filtered_badges = [b for b in filtered_badges if b["unlocked"]]
    
    unlocked_count = sum(1 for b in PRESET_BADGES if b["unlocked"])
    
    return BadgesResponse(
        success=True,
        data=filtered_badges,
        total=len(filtered_badges),
        unlocked_count=unlocked_count
    )

@router.get("/challenges/stats", response_model=StatsResponse)
async def get_challenges_stats():
    """获取挑战统计信息"""
    total = len(PRESET_CHALLENGES)
    completed = sum(1 for c in PRESET_CHALLENGES if c["status"] == "completed")
    in_progress = sum(1 for c in PRESET_CHALLENGES if c["status"] == "in-progress")
    available = sum(1 for c in PRESET_CHALLENGES if c["status"] == "available")
    total_points = sum(c["points"] for c in PRESET_CHALLENGES if c["status"] == "completed")
    unlocked_badges = sum(1 for b in PRESET_BADGES if b["unlocked"])
    
    return StatsResponse(
        success=True,
        data={
            "total_challenges": total,
            "completed": completed,
            "in_progress": in_progress,
            "available": available,
            "total_points": total_points,
            "unlocked_badges": unlocked_badges,
            "total_badges": len(PRESET_BADGES),
            "completion_rate": round((completed / total) * 100, 1) if total > 0 else 0
        }
    )

@router.post("/challenges/{challenge_id}/start", response_model=StartChallengeResponse)
async def start_challenge(challenge_id: int):
    """开始一个挑战"""
    challenge = get_challenge_by_id(challenge_id)
    
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    if challenge["status"] == "completed":
        return StartChallengeResponse(
            success=False,
            message="挑战已完成，无法重新开始"
        )
    
    challenge["status"] = "in-progress"
    challenge["created_at"] = datetime.now().isoformat()
    
    return StartChallengeResponse(
        success=True,
        message=f"已开始挑战：{challenge['title']}",
        data=challenge
    )

@router.patch("/challenges/{challenge_id}/tasks/{task_id}", response_model=StartChallengeResponse)
async def update_task(
    challenge_id: int,
    task_id: int,
    request: UpdateTaskRequest
):
    """更新任务状态"""
    challenge = get_challenge_by_id(challenge_id)
    
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    task = None
    for t in challenge["tasks"]:
        if t["id"] == task_id:
            task = t
            break
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task["completed"] = request.completed
    
    # 如果任务被勾选且挑战未开始，自动开始挑战
    if request.completed and challenge["status"] == "available":
        challenge["status"] = "in-progress"
        challenge["created_at"] = datetime.now().isoformat()
    
    # 检查是否所有任务都完成了
    all_completed = all(t["completed"] for t in challenge["tasks"])
    if all_completed and challenge["status"] != "completed":
        challenge["status"] = "completed"
        challenge["completed_at"] = datetime.now().isoformat()
        return StartChallengeResponse(
            success=True,
            message=f"🎉 恭喜完成挑战：{challenge['title']}！获得 {challenge['points']} 积分",
            data=challenge
        )
    
    return StartChallengeResponse(
        success=True,
        message="任务已更新",
        data=challenge
    )

@router.get("/challenges/daily", response_model=ChallengesResponse)
async def get_daily_challenges():
    """获取每日挑战"""
    daily_challenges = [c for c in PRESET_CHALLENGES if c["type"] == "daily"]
    
    for challenge in daily_challenges:
        challenge["progress"] = calculate_progress(challenge)
    
    return ChallengesResponse(
        success=True,
        data=daily_challenges,
        total=len(daily_challenges)
    )

@router.get("/challenges/weekly", response_model=ChallengesResponse)
async def get_weekly_challenges():
    """获取每周挑战"""
    weekly_challenges = [c for c in PRESET_CHALLENGES if c["type"] == "weekly"]
    
    for challenge in weekly_challenges:
        challenge["progress"] = calculate_progress(challenge)
    
    return ChallengesResponse(
        success=True,
        data=weekly_challenges,
        total=len(weekly_challenges)
    )

@router.get("/challenges/recommended", response_model=ChallengeDetailResponse)
async def get_recommended_challenge():
    """获取推荐挑战（基于用户进度的智能推荐）"""
    # 简单实现：返回一个未完成的挑战
    available_challenges = [c for c in PRESET_CHALLENGES if c["status"] == "available"]
    
    if not available_challenges:
        # 如果所有挑战都完成了，返回一个已完成挑战
        challenge = PRESET_CHALLENGES[0]
    else:
        # 随机推荐一个
        challenge = random.choice(available_challenges)
    
    challenge_copy = challenge.copy()
    challenge_copy["progress"] = calculate_progress(challenge)
    
    return ChallengeDetailResponse(
        success=True,
        data=challenge_copy
    )
