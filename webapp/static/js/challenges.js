/**
 * DreamLog Web - 梦境挑战页面脚本
 */

// API 基础 URL
const API_BASE = '/api';

// 全局状态
let challenges = [];
let badges = [];
let currentFilter = 'all';

// 预设挑战模板
const PRESET_CHALLENGES = [
    {
        id: 1,
        title: '晨间记录者',
        type: 'daily',
        difficulty: 'easy',
        description: '养成晨间记录梦境的好习惯',
        tasks: [
            { id: 1, title: '记录 1 个梦境', completed: false },
            { id: 2, title: '添加情绪标签', completed: false },
            { id: 3, title: '添加至少 2 个标签', completed: false }
        ],
        points: 100,
        badges: ['🌅'],
        status: 'available'
    },
    {
        id: 2,
        title: '一周达人',
        type: 'weekly',
        difficulty: 'medium',
        description: '连续一周记录梦境',
        tasks: [
            { id: 1, title: '连续记录 7 天', completed: false },
            { id: 2, title: '总计 7 个梦境', completed: false },
            { id: 3, title: '平均清晰度≥3', completed: false }
        ],
        points: 500,
        badges: ['📅', '🔥'],
        status: 'in-progress'
    },
    {
        id: 3,
        title: '清醒梦初体验',
        type: 'special',
        difficulty: 'hard',
        description: '体验并记录你的第一个清醒梦',
        tasks: [
            { id: 1, title: '记录 1 个清醒梦', completed: false },
            { id: 2, title: '清晰度≥4', completed: false },
            { id: 3, title: '添加详细解析', completed: false }
        ],
        points: 300,
        badges: ['🌟'],
        status: 'available'
    },
    {
        id: 4,
        title: '创意梦境探索',
        type: 'weekly',
        difficulty: 'medium',
        description: '从梦境中获取创意灵感',
        tasks: [
            { id: 1, title: '记录 3 个创意相关的梦', completed: false },
            { id: 2, title: '使用 AI 解析', completed: false },
            { id: 3, title: '生成 1 张 AI 绘画', completed: false }
        ],
        points: 400,
        badges: ['🎨', '💡'],
        status: 'available'
    },
    {
        id: 5,
        title: '飞行梦大师',
        type: 'special',
        difficulty: 'expert',
        description: '探索飞行主题的梦境',
        tasks: [
            { id: 1, title: '记录 5 个飞行梦', completed: false },
            { id: 2, title: '平均清晰度≥4', completed: false },
            { id: 3, title: '创建 1 个 AR 场景', completed: false }
        ],
        points: 800,
        badges: ['✈️', '👑'],
        status: 'available'
    },
    {
        id: 6,
        title: '分享先锋',
        type: 'achievement',
        difficulty: 'easy',
        description: '分享你的梦境到社区',
        tasks: [
            { id: 1, title: '分享 1 个梦境', completed: false },
            { id: 2, title: '获得 5 个点赞', completed: false }
        ],
        points: 200,
        badges: ['📤'],
        status: 'available'
    },
    {
        id: 7,
        title: '冥想修行者',
        type: 'daily',
        difficulty: 'easy',
        description: '通过冥想提升梦境质量',
        tasks: [
            { id: 1, title: '完成 1 次冥想', completed: false },
            { id: 2, title: '记录冥想后的梦', completed: false }
        ],
        points: 150,
        badges: ['🧘'],
        status: 'available'
    },
    {
        id: 8,
        title: '梦境收藏家',
        type: 'achievement',
        difficulty: 'medium',
        description: '收集 50 个梦境',
        tasks: [
            { id: 1, title: '记录 50 个梦境', completed: false },
            { id: 2, title: '平均清晰度≥3.5', completed: false }
        ],
        points: 1000,
        badges: ['📚', '💎'],
        status: 'in-progress'
    }
];

// 预设徽章
const PRESET_BADGES = [
    { id: 1, icon: '🌅', name: '晨鸟', desc: '连续 7 天晨间记录', unlocked: true },
    { id: 2, icon: '🔥', name: '坚持大师', desc: '连续记录 30 天', unlocked: false },
    { id: 3, icon: '🌟', name: '清醒觉醒', desc: '记录第一个清醒梦', unlocked: false },
    { id: 4, icon: '📤', name: '分享先锋', desc: '分享 10 个梦境', unlocked: true },
    { id: 5, icon: '🎨', name: '艺术家', desc: '生成 20 张 AI 绘画', unlocked: false },
    { id: 6, icon: '🧘', name: '冥想者', desc: '完成 10 次冥想', unlocked: false },
    { id: 7, icon: '📚', name: '收藏家', desc: '记录 100 个梦境', unlocked: false },
    { id: 8, icon: '💎', name: '钻石梦', desc: '连续清晰度≥4 达 7 天', unlocked: false },
    { id: 9, icon: '✈️', name: '飞行家', desc: '记录 20 个飞行梦', unlocked: false },
    { id: 10, icon: '👑', name: '梦境之王', desc: '完成所有挑战', unlocked: false },
    { id: 11, icon: '🌙', name: '夜行者', desc: '记录 50 个夜间梦境', unlocked: true },
    { id: 12, icon: '💡', name: '灵感大师', desc: '从梦境获得 10 个创意', unlocked: false }
];

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    console.log('🎯 DreamLog 挑战页面已加载');
    loadChallenges();
    loadBadges();
    setupFilters();
    loadStats();
});

// 加载挑战
async function loadChallenges() {
    try {
        const response = await fetch(`${API_BASE}/challenges`);
        const result = await response.json();
        
        if (result.success) {
            challenges = result.data;
            renderChallenges(challenges);
            updateStats();
        } else {
            console.error('加载挑战失败:', result);
            // 降级到预设数据
            challenges = PRESET_CHALLENGES;
            renderChallenges(challenges);
        }
    } catch (error) {
        console.error('加载挑战出错:', error);
        // 降级到预设数据
        challenges = PRESET_CHALLENGES;
        renderChallenges(challenges);
    }
}

// 加载徽章
async function loadBadges() {
    try {
        const response = await fetch(`${API_BASE}/challenges/badges`);
        const result = await response.json();
        
        if (result.success) {
            badges = result.data;
            renderBadges(badges);
        } else {
            console.error('加载徽章失败:', result);
            // 降级到预设数据
            badges = PRESET_BADGES;
            renderBadges(badges);
        }
    } catch (error) {
        console.error('加载徽章出错:', error);
        // 降级到预设数据
        badges = PRESET_BADGES;
        renderBadges(badges);
    }
}

// 加载统计
async function loadStats() {
    try {
        const response = await fetch(`${API_BASE}/challenges/stats`);
        const result = await response.json();
        
        if (result.success) {
            const stats = result.data;
            document.getElementById('totalChallenges').textContent = stats.total_challenges;
            document.getElementById('completedChallenges').textContent = stats.completed;
            document.getElementById('inProgressChallenges').textContent = stats.in_progress;
            document.getElementById('totalPoints').textContent = stats.total_points;
        }
    } catch (error) {
        console.error('加载统计出错:', error);
    }
}

// 设置筛选器
function setupFilters() {
    const filterBtns = document.querySelectorAll('.filter-btn');
    filterBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            // 更新 active 状态
            filterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            
            // 更新筛选
            currentFilter = btn.dataset.filter;
            filterChallenges();
        });
    });
}

// 筛选挑战
async function filterChallenges() {
    let filtered = [...challenges];
    
    switch (currentFilter) {
        case 'available':
            filtered = challenges.filter(c => c.status === 'available');
            break;
        case 'in-progress':
            filtered = challenges.filter(c => c.status === 'in-progress');
            break;
        case 'completed':
            filtered = challenges.filter(c => c.status === 'completed');
            break;
        case 'daily':
            filtered = challenges.filter(c => c.type === 'daily');
            break;
        case 'weekly':
            filtered = challenges.filter(c => c.type === 'weekly');
            break;
        default:
            filtered = challenges;
    }
    
    renderChallenges(filtered);
}

// 开始挑战
async function handleStartChallenge(e) {
    const challengeId = parseInt(e.target.dataset.challengeId);
    
    try {
        const response = await fetch(`${API_BASE}/challenges/${challengeId}/start`, {
            method: 'POST'
        });
        const result = await response.json();
        
        if (result.success) {
            showToast(`✅ 已开始挑战：${result.data.title}`, 'success');
            // 重新加载挑战列表
            await loadChallenges();
        } else {
            showToast(`❌ ${result.message}`, 'error');
        }
    } catch (error) {
        console.error('开始挑战出错:', error);
        // 降级到本地处理
        const challenge = challenges.find(c => c.id === challengeId);
        if (challenge) {
            challenge.status = 'in-progress';
            showToast(`✅ 已开始挑战：${challenge.title}`, 'success');
            filterChallenges();
            updateStats();
        }
    }
}

// 渲染挑战列表
function renderChallenges(challengesToRender) {
    const grid = document.getElementById('challengesGrid');
    
    if (challengesToRender.length === 0) {
        grid.innerHTML = `
            <div class="empty-state" style="grid-column: 1 / -1;">
                <div class="empty-icon">📋</div>
                <h3>暂无挑战</h3>
                <p>根据你的筛选条件，没有找到挑战</p>
            </div>
        `;
        return;
    }
    
    grid.innerHTML = challengesToRender.map(challenge => createChallengeCard(challenge)).join('');
    
    // 绑定任务复选框事件
    document.querySelectorAll('.task-checkbox').forEach(checkbox => {
        checkbox.addEventListener('change', handleTaskChange);
    });
    
    // 绑定开始挑战按钮事件
    document.querySelectorAll('.btn-start').forEach(btn => {
        btn.addEventListener('click', handleStartChallenge);
    });
}

// 创建挑战卡片
function createChallengeCard(challenge) {
    const progress = calculateProgress(challenge);
    const isCompleted = challenge.status === 'completed';
    const isInProgress = challenge.status === 'in-progress';
    
    let cardClass = 'challenge-card';
    if (challenge.status === 'available') cardClass += ' available';
    if (isCompleted) cardClass += ' completed';
    
    const typeLabels = {
        daily: '每日',
        weekly: '每周',
        special: '特殊',
        achievement: '成就'
    };
    
    const difficultyLabels = {
        easy: '简单',
        medium: '中等',
        hard: '困难',
        expert: '专家'
    };
    
    return `
        <div class="${cardClass}">
            <div class="challenge-header">
                <div>
                    <div class="challenge-title">${challenge.title}</div>
                    <div>
                        <span class="challenge-type type-${challenge.type}">${typeLabels[challenge.type]}</span>
                        <span class="challenge-difficulty difficulty-${challenge.difficulty}">${difficultyLabels[challenge.difficulty]}</span>
                    </div>
                </div>
                ${isCompleted ? '<span style="font-size: 2rem;">✅</span>' : ''}
            </div>
            
            <p class="challenge-description">${challenge.description}</p>
            
            <div class="challenge-tasks">
                ${challenge.tasks.map(task => `
                    <div class="task-item">
                        <input type="checkbox" class="task-checkbox" 
                            data-challenge-id="${challenge.id}" 
                            data-task-id="${task.id}"
                            ${task.completed ? 'checked' : ''}
                            ${isCompleted ? 'disabled' : ''}>
                        <span class="${task.completed ? 'task-completed' : ''}">${task.title}</span>
                    </div>
                `).join('')}
            </div>
            
            <div class="challenge-progress">
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${progress}%"></div>
                </div>
                <div class="progress-text">进度：${challenge.tasks.filter(t => t.completed).length}/${challenge.tasks.length} (${progress}%)</div>
            </div>
            
            <div class="challenge-reward">
                <div class="reward-badges">
                    ${challenge.badges.map(badge => `<span class="badge" title="成就徽章">${badge}</span>`).join('')}
                </div>
                <div class="challenge-points">+${challenge.points} 积分</div>
            </div>
            
            <div class="challenge-actions">
                ${!isInProgress && !isCompleted ? 
                    `<button class="btn btn-primary btn-start" data-challenge-id="${challenge.id}">开始挑战</button>` : 
                    ''}
                ${isInProgress ? 
                    `<button class="btn btn-success" disabled>进行中</button>` : 
                    ''}
                ${isCompleted ? 
                    `<button class="btn btn-secondary" disabled>已完成</button>` : 
                    ''}
                <button class="btn btn-secondary">详情</button>
            </div>
        </div>
    `;
}

// 渲染徽章
function renderBadges(badgesToRender) {
    const grid = document.getElementById('badgesGrid');
    
    grid.innerHTML = badgesToRender.map(badge => `
        <div class="badge-item ${badge.unlocked ? '' : 'locked'}">
            <div class="badge-icon">${badge.icon}</div>
            <div class="badge-name">${badge.name}</div>
            <div class="badge-desc">${badge.desc}</div>
        </div>
    `).join('');
}

// 计算进度百分比
function calculateProgress(challenge) {
    if (challenge.tasks.length === 0) return 0;
    const completed = challenge.tasks.filter(t => t.completed).length;
    return Math.round((completed / challenge.tasks.length) * 100);
}

// 更新统计
async function updateStats() {
    try {
        const response = await fetch(`${API_BASE}/challenges/stats`);
        const result = await response.json();
        
        if (result.success) {
            const stats = result.data;
            document.getElementById('totalChallenges').textContent = stats.total_challenges;
            document.getElementById('completedChallenges').textContent = stats.completed;
            document.getElementById('inProgressChallenges').textContent = stats.in_progress;
            document.getElementById('totalPoints').textContent = stats.total_points;
        } else {
            // 降级到本地计算
            updateStatsLocal();
        }
    } catch (error) {
        console.error('加载统计出错:', error);
        // 降级到本地计算
        updateStatsLocal();
    }
}

// 本地统计更新（降级方案）
function updateStatsLocal() {
    const total = challenges.length;
    const completed = challenges.filter(c => c.status === 'completed').length;
    const inProgress = challenges.filter(c => c.status === 'in-progress').length;
    const totalPoints = challenges
        .filter(c => c.status === 'completed')
        .reduce((sum, c) => sum + c.points, 0);
    
    document.getElementById('totalChallenges').textContent = total;
    document.getElementById('completedChallenges').textContent = completed;
    document.getElementById('inProgressChallenges').textContent = inProgress;
    document.getElementById('totalPoints').textContent = totalPoints;
}

// 处理任务变更
async function handleTaskChange(e) {
    const challengeId = parseInt(e.target.dataset.challengeId);
    const taskId = parseInt(e.target.dataset.taskId);
    const completed = e.target.checked;
    
    try {
        const response = await fetch(`${API_BASE}/challenges/${challengeId}/tasks/${taskId}`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ completed })
        });
        const result = await response.json();
        
        if (result.success) {
            // 更新本地数据
            const challenge = challenges.find(c => c.id === challengeId);
            if (challenge) {
                const task = challenge.tasks.find(t => t.id === taskId);
                if (task) {
                    task.completed = completed;
                }
                // 同步状态
                challenge.status = result.data.status;
            }
            
            if (result.message.includes('恭喜完成')) {
                showToast(result.message, 'success');
            }
            
            // 重新加载挑战列表和统计
            await loadChallenges();
        } else {
            showToast(`❌ ${result.message}`, 'error');
            // 恢复复选框状态
            e.target.checked = !completed;
        }
    } catch (error) {
        console.error('更新任务出错:', error);
        // 降级到本地处理
        const challenge = challenges.find(c => c.id === challengeId);
        if (challenge) {
            const task = challenge.tasks.find(t => t.id === taskId);
            if (task) {
                task.completed = completed;
                
                const allCompleted = challenge.tasks.every(t => t.completed);
                if (allCompleted && challenge.status !== 'completed') {
                    challenge.status = 'completed';
                    showToast(`🎉 恭喜完成挑战：${challenge.title}！`, 'success');
                    updateStats();
                } else if (completed && challenge.status === 'available') {
                    challenge.status = 'in-progress';
                }
                
                filterChallenges();
                updateStats();
            }
        }
    }
}

// 处理开始挑战
function handleStartChallenge(e) {
    const challengeId = parseInt(e.target.dataset.challengeId);
    const challenge = challenges.find(c => c.id === challengeId);
    
    if (challenge) {
        challenge.status = 'in-progress';
        showToast(`✅ 已开始挑战：${challenge.title}`, 'success');
        filterChallenges();
        updateStats();
    }
}

// Toast 通知
function showToast(message, type = 'info') {
    // 创建或获取 toast 元素
    let toast = document.getElementById('toast');
    if (!toast) {
        toast = document.createElement('div');
        toast.id = 'toast';
        toast.className = 'toast';
        document.body.appendChild(toast);
    }
    
    // 移除旧的消息
    toast.innerHTML = '';
    
    // 添加图标
    const icon = document.createElement('span');
    icon.style.fontSize = '1.25rem';
    if (type === 'success') {
        icon.textContent = '✅';
        toast.classList.add('success');
        toast.classList.remove('error');
    } else if (type === 'error') {
        icon.textContent = '❌';
        toast.classList.add('error');
        toast.classList.remove('success');
    } else {
        icon.textContent = 'ℹ️';
        toast.classList.remove('success', 'error');
    }
    toast.appendChild(icon);
    
    // 添加消息
    const messageEl = document.createElement('span');
    messageEl.className = 'toast-message';
    messageEl.textContent = message;
    toast.appendChild(messageEl);
    
    // 显示动画
    toast.classList.add('show');
    
    // 3 秒后自动隐藏
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}
