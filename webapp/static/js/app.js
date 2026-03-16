/**
 * DreamLog Web - 前端应用脚本
 */

// API 基础 URL
const API_BASE = '/api';

// 全局状态
let dreams = [];
let isLoading = false;

// DOM 元素
const dreamsGrid = document.getElementById('dreamsGrid');
const loadingState = document.getElementById('loadingState');
const emptyState = document.getElementById('emptyState');
const recordModal = document.getElementById('recordModal');
const dreamForm = document.getElementById('dreamForm');
const searchInput = document.getElementById('searchInput');
const filterSelect = document.getElementById('filterSelect');

// 初始化应用
document.addEventListener('DOMContentLoaded', () => {
    console.log('🌙 DreamLog Web 已加载');
    loadDreams();
    setupEventListeners();
    updateStats();
    loadWeeklyReport();  // 加载周报
});

// 设置事件监听
function setupEventListeners() {
    // 搜索功能
    searchInput.addEventListener('input', debounce(filterDreams, 300));
    
    // 筛选功能
    filterSelect.addEventListener('change', filterDreams);
    
    // 表单提交
    dreamForm.addEventListener('submit', handleFormSubmit);
    
    // 模态框点击外部关闭
    recordModal.addEventListener('click', (e) => {
        if (e.target === recordModal) {
            closeRecordModal();
        }
    });
    
    // ESC 键关闭模态框
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && recordModal.classList.contains('active')) {
            closeRecordModal();
        }
        if (e.key === 'Escape' && document.getElementById('dreamDetailModal')?.classList.contains('active')) {
            closeDreamDetailModal();
        }
    });
    
    // 梦境详情模态框点击外部关闭
    const dreamDetailModal = document.getElementById('dreamDetailModal');
    if (dreamDetailModal) {
        dreamDetailModal.addEventListener('click', (e) => {
            if (e.target === dreamDetailModal) {
                closeDreamDetailModal();
            }
        });
    }
}

// 加载梦境列表
async function loadDreams() {
    if (isLoading) return;
    
    isLoading = true;
    showLoading();
    
    try {
        const response = await fetch(`${API_BASE}/dreams`);
        if (!response.ok) throw new Error('加载失败');
        
        dreams = await response.json();
        renderDreams(dreams);
        updateStats();
    } catch (error) {
        console.error('加载梦境失败:', error);
        showToast('加载梦境失败，请稍后重试', 'error');
        // 使用示例数据演示
        loadDemoData();
    } finally {
        isLoading = false;
        hideLoading();
    }
}

// 加载示例数据（演示用）
function loadDemoData() {
    dreams = [
        {
            id: 1,
            title: '飞翔在星空',
            content: '我梦见自己在夜空中飞翔，周围是闪烁的星星。感觉非常自由，可以看到整个城市在脚下。突然听到闹钟响了...',
            date: '2026-03-10T23:30:00Z',
            emotions: ['peaceful', 'excited'],
            isLucid: true,
            clarity: 5,
            tags: ['飞行', '星空', '自由']
        },
        {
            id: 2,
            title: '迷路的城市',
            content: '在一个陌生的城市里迷路了，街道很复杂，建筑物都很奇怪。想要找人问路但是没有人。后来发现自己在梦里...',
            date: '2026-03-09T07:15:00Z',
            emotions: ['anxious', 'confused'],
            isLucid: false,
            clarity: 3,
            tags: ['迷路', '城市', '焦虑']
        },
        {
            id: 3,
            title: '海底探险',
            content: '潜入深海，看到了五彩斑斓的珊瑚和各种奇异的鱼类。可以像鱼一样呼吸，和海豚一起游泳。非常 peaceful 的感觉。',
            date: '2026-03-08T06:45:00Z',
            emotions: ['peaceful', 'happy'],
            isLucid: false,
            clarity: 4,
            tags: ['海洋', '探险', '平静']
        },
        {
            id: 4,
            title: '被追逐',
            content: '有什么东西在追我，跑了好久好久。腿像灌了铅一样沉重。躲进一个房间，门被敲响...然后醒了。',
            date: '2026-03-07T05:20:00Z',
            emotions: ['scared', 'anxious'],
            isLucid: false,
            clarity: 2,
            tags: ['追逐', '恐惧', '逃跑']
        },
        {
            id: 5,
            title: '回到童年',
            content: '回到了小时候住的老房子，院子里的桂花树还在开花。奶奶在做饭，香味飘满整个屋子。醒来后很怀念。',
            date: '2026-03-06T06:00:00Z',
            emotions: ['happy', 'sad'],
            isLucid: false,
            clarity: 5,
            tags: ['童年', '回忆', '怀念']
        },
        {
            id: 6,
            title: '超能力觉醒',
            content: '突然发现自己可以移动物体，用意念控制东西。开始很害怕，后来慢慢掌握了。梦见自己成了超级英雄。',
            date: '2026-03-05T22:45:00Z',
            emotions: ['excited', 'surprised'],
            isLucid: true,
            clarity: 4,
            tags: ['超能力', '英雄', '惊喜']
        }
    ];
    renderDreams(dreams);
    updateStats();
}

// 渲染梦境列表
function renderDreams(dreamsToRender) {
    if (!dreamsGrid) return;
    
    if (dreamsToRender.length === 0) {
        dreamsGrid.style.display = 'none';
        emptyState.style.display = 'block';
        return;
    }
    
    dreamsGrid.style.display = 'grid';
    emptyState.style.display = 'none';
    
    dreamsGrid.innerHTML = dreamsToRender.map(dream => `
        <div class="dream-card fade-in" onclick="viewDream(${dream.id})">
            <div class="dream-card-header">
                <div>
                    <h3 class="dream-title">${escapeHtml(dream.title)}</h3>
                    <span class="dream-date">${formatDate(dream.date)}</span>
                </div>
                ${dream.isLucid ? '<span class="tag lucid">👁️ 清醒梦</span>' : ''}
            </div>
            <p class="dream-content">${escapeHtml(dream.content)}</p>
            <div class="dream-tags">
                ${dream.tags.map(tag => `<span class="tag">#${escapeHtml(tag)}</span>`).join('')}
            </div>
            <div class="dream-footer">
                <div class="dream-emotions">
                    ${dream.emotions.map(emotion => `<span class="emotion">${getEmotionEmoji(emotion)}</span>`).join('')}
                </div>
                <div class="dream-actions">
                    <button class="action-btn" onclick="event.stopPropagation(); shareDream(${dream.id})" title="分享">📤</button>
                    <button class="action-btn" onclick="event.stopPropagation(); toggleFavorite(${dream.id})" title="收藏">⭐</button>
                </div>
            </div>
        </div>
    `).join('');
}

// 筛选梦境
function filterDreams() {
    const searchTerm = searchInput.value.toLowerCase();
    const filterType = filterSelect.value;
    
    let filtered = dreams;
    
    // 搜索筛选
    if (searchTerm) {
        filtered = filtered.filter(dream => 
            dream.title.toLowerCase().includes(searchTerm) ||
            dream.content.toLowerCase().includes(searchTerm) ||
            dream.tags.some(tag => tag.toLowerCase().includes(searchTerm))
        );
    }
    
    // 类型筛选
    if (filterType !== 'all') {
        switch (filterType) {
            case 'lucid':
                filtered = filtered.filter(d => d.isLucid);
                break;
            case 'recent':
                const weekAgo = new Date();
                weekAgo.setDate(weekAgo.getDate() - 7);
                filtered = filtered.filter(d => new Date(d.date) >= weekAgo);
                break;
            case 'favorite':
                filtered = filtered.filter(d => d.isFavorite);
                break;
        }
    }
    
    renderDreams(filtered);
}

// 打开记录模态框
function openRecordModal() {
    recordModal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

// 关闭记录模态框
function closeRecordModal() {
    recordModal.classList.remove('active');
    document.body.style.overflow = '';
    dreamForm.reset();
}

// 处理表单提交
async function handleFormSubmit(e) {
    e.preventDefault();
    
    const formData = {
        title: document.getElementById('dreamTitle').value,
        content: document.getElementById('dreamContent').value,
        emotions: Array.from(document.querySelectorAll('input[name="emotions"]:checked'))
            .map(cb => cb.value),
        isLucid: document.getElementById('isLucid').checked,
        clarity: parseInt(document.getElementById('clarity').value),
        tags: [] // 可以从内容中自动提取
    };
    
    try {
        const response = await fetch(`${API_BASE}/dreams`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(formData)
        });
        
        if (!response.ok) throw new Error('保存失败');
        
        const newDream = await response.json();
        dreams.unshift(newDream);
        renderDreams(dreams);
        updateStats();
        
        closeRecordModal();
        showToast('梦境记录成功！✨', 'success');
    } catch (error) {
        console.error('保存梦境失败:', error);
        // 演示模式：添加到本地列表
        const newDream = {
            id: Date.now(),
            ...formData,
            date: new Date().toISOString(),
            tags: ['新记录']
        };
        dreams.unshift(newDream);
        renderDreams(dreams);
        updateStats();
        closeRecordModal();
        showToast('梦境记录成功！✨', 'success');
    }
}

// 更新统计
async function updateStats() {
    const totalElement = document.getElementById('totalDreams');
    const lucidElement = document.getElementById('lucidDreams');
    const streakElement = document.getElementById('currentStreak');
    
    if (totalElement) totalElement.textContent = dreams.length;
    if (lucidElement) lucidElement.textContent = dreams.filter(d => d.isLucid).length;
    if (streakElement) streakElement.textContent = calculateStreak(dreams);
}

// 计算连续记录天数
function calculateStreak(dreams) {
    if (dreams.length === 0) return 0;
    
    const sortedDreams = [...dreams].sort((a, b) => 
        new Date(b.date) - new Date(a.date)
    );
    
    let streak = 1;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    let currentDate = new Date(sortedDreams[0].date);
    currentDate.setHours(0, 0, 0, 0);
    
    for (let i = 1; i < sortedDreams.length; i++) {
        const prevDate = new Date(sortedDreams[i].date);
        prevDate.setHours(0, 0, 0, 0);
        
        const diffDays = (currentDate - prevDate) / (1000 * 60 * 60 * 24);
        
        if (diffDays === 1) {
            streak++;
            currentDate = prevDate;
        } else if (diffDays > 1) {
            break;
        }
    }
    
    return streak;
}

// 当前查看的梦境 ID
let currentDetailDreamId = null;

// 查看梦境详情
function viewDream(id) {
    const dream = dreams.find(d => d.id === id);
    if (!dream) return;
    
    currentDetailDreamId = id;
    
    // 填充详情模态框内容
    const detailTitle = document.getElementById('detailTitle');
    const detailDate = document.getElementById('detailDate');
    const detailEmotion = document.getElementById('detailEmotion');
    const detailLucid = document.getElementById('detailLucid');
    const detailContent = document.getElementById('detailContent');
    const tagList = document.getElementById('tagList');
    
    if (detailTitle) detailTitle.textContent = dream.title || '无标题梦境';
    if (detailDate) {
        const date = new Date(dream.date);
        detailDate.textContent = date.toLocaleDateString('zh-CN', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    if (detailEmotion) {
        const emotionMap = {
            'happy': '😊 快乐',
            'sad': '😢 悲伤',
            'anxious': '😰 焦虑',
            'excited': '🤩 兴奋',
            'confused': '😕 困惑',
            'peaceful': '😌 平静',
            'scared': '😱 恐惧',
            'surprised': '😲 惊讶'
        };
        detailEmotion.textContent = dream.emotions?.map(e => emotionMap[e] || e).join(', ') || '😐 中性';
    }
    if (detailLucid) {
        detailLucid.textContent = dream.isLucid ? '🌟 清醒梦' : '';
        detailLucid.style.display = dream.isLucid ? 'inline' : 'none';
    }
    if (detailContent) detailContent.textContent = dream.content || '无内容';
    
    // 渲染标签
    if (tagList) {
        tagList.innerHTML = '';
        const tags = dream.tags || [];
        if (tags.length === 0) {
            tagList.parentElement.style.display = 'none';
        } else {
            tagList.parentElement.style.display = 'block';
            tags.forEach(tag => {
                const tagEl = document.createElement('span');
                tagEl.className = 'tag';
                tagEl.textContent = tag;
                tagList.appendChild(tagEl);
            });
        }
    }
    
    // 显示 AI 解析（如果有）
    const analysisSection = document.getElementById('detailAnalysis');
    if (analysisSection) {
        if (dream.aiAnalysis) {
            analysisSection.style.display = 'block';
            document.getElementById('analysisContent').innerHTML = dream.aiAnalysis;
        } else {
            analysisSection.style.display = 'none';
        }
    }
    
    // 打开模态框
    const modal = document.getElementById('dreamDetailModal');
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

// 关闭梦境详情模态框
function closeDreamDetailModal() {
    const modal = document.getElementById('dreamDetailModal');
    if (modal) {
        modal.classList.remove('active');
        document.body.style.overflow = '';
    }
    currentDetailDreamId = null;
}

// 从详情模态框切换收藏
function toggleFavoriteFromDetail() {
    if (currentDetailDreamId) {
        toggleFavorite(currentDetailDreamId);
        viewDream(currentDetailDreamId); // 刷新显示
    }
}

// 从详情模态框分享
function shareDreamFromDetail() {
    if (currentDetailDreamId) {
        shareDream(currentDetailDreamId);
    }
}

// 从详情模态框编辑
function editDreamFromDetail() {
    if (currentDetailDreamId) {
        const dream = dreams.find(d => d.id === currentDetailDreamId);
        if (dream) {
            closeDreamDetailModal();
            openRecordModal();
            // 填充表单
            document.getElementById('dreamTitle').value = dream.title || '';
            document.getElementById('dreamContent').value = dream.content || '';
            document.getElementById('isLucid').checked = dream.isLucid || false;
            // 设置情绪标签
            document.querySelectorAll('input[name="emotions"]').forEach(cb => {
                cb.checked = dream.emotions?.includes(cb.value) || false;
            });
        }
    }
}

// 分享梦境
function shareDream(id) {
    const dream = dreams.find(d => d.id === id);
    if (!dream) return;
    
    if (navigator.share) {
        navigator.share({
            title: dream.title,
            text: dream.content,
            url: window.location.href
        });
    } else {
        showToast('已复制到剪贴板', 'success');
    }
}

// 切换收藏状态
function toggleFavorite(id) {
    const dream = dreams.find(d => d.id === id);
    if (!dream) return;
    
    dream.isFavorite = !dream.isFavorite;
    showToast(dream.isFavorite ? '已添加到收藏 ⭐' : '已取消收藏', 'success');
    filterDreams(); // 重新渲染
}

// 滚动到梦境区块
function scrollToDreams() {
    document.getElementById('dreams')?.scrollIntoView({ behavior: 'smooth' });
}

// 显示加载状态
function showLoading() {
    if (loadingState) loadingState.style.display = 'block';
}

// 隐藏加载状态
function hideLoading() {
    if (loadingState) loadingState.style.display = 'none';
}

// 显示 Toast 通知
function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    if (!toast) return;
    
    const messageEl = toast.querySelector('.toast-message');
    if (messageEl) messageEl.textContent = message;
    
    toast.className = `toast ${type}`;
    toast.classList.add('active');
    
    setTimeout(() => {
        toast.classList.remove('active');
    }, 3000);
}

// 工具函数

// HTML 转义
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// 日期格式化
function formatDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diff = now - date;
    
    // 今天
    if (diff < 24 * 60 * 60 * 1000 && date.getDate() === now.getDate()) {
        return `今天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
    
    // 昨天
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    if (diff < 48 * 60 * 60 * 1000 && date.getDate() === yesterday.getDate()) {
        return `昨天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
    
    // 其他日期
    return date.toLocaleDateString('zh-CN', {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// 获取情绪表情
function getEmotionEmoji(emotion) {
    const emojis = {
        happy: '😊',
        sad: '😢',
        anxious: '😰',
        excited: '🤩',
        confused: '😕',
        peaceful: '😌',
        scared: '😱',
        surprised: '😲'
    };
    return emojis[emotion] || '😐';
}

// 防抖函数
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// ==================== 周报功能 ====================

// 加载周报数据
async function loadWeeklyReport() {
    try {
        const response = await fetch(`${API_BASE}/stats/weekly-report`);
        if (!response.ok) throw new Error('加载周报失败');
        
        const result = await response.json();
        if (result.success) {
            renderWeeklyReport(result.data);
        }
    } catch (error) {
        console.error('加载周报失败:', error);
        showToast('加载周报失败，请稍后重试', 'error');
    }
}

// 渲染周报
function renderWeeklyReport(report) {
    const statsSection = document.getElementById('stats');
    if (!statsSection) return;
    
    // 创建周报卡片
    const reportCard = document.createElement('div');
    reportCard.className = 'weekly-report-card';
    reportCard.innerHTML = `
        <div class="report-header">
            <h3>📊 梦境周报</h3>
            <span class="report-period">${formatWeekRange(report.weekStartDate, report.weekEndDate)}</span>
        </div>
        <div class="report-stats">
            <div class="report-stat">
                <span class="stat-value">${report.totalDreams}</span>
                <span class="stat-label">梦境总数</span>
            </div>
            <div class="report-stat">
                <span class="stat-value">${report.lucidDreams}</span>
                <span class="stat-label">清醒梦</span>
            </div>
            <div class="report-stat">
                <span class="stat-value">${report.averageClarity.toFixed(1)}</span>
                <span class="stat-label">平均清晰度</span>
            </div>
            <div class="report-stat">
                <span class="stat-value">🔥 ${report.recordingStreak}天</span>
                <span class="stat-label">连续记录</span>
            </div>
        </div>
        ${report.insights.length > 0 ? `
        <div class="report-insights">
            <h4>💡 智能洞察</h4>
            ${report.insights.map(insight => `
                <div class="insight-item">
                    <span class="insight-icon">${insight.icon}</span>
                    <div>
                        <strong>${insight.title}</strong>
                        <p>${insight.description}</p>
                    </div>
                </div>
            `).join('')}
        </div>
        ` : ''}
        ${report.suggestions.length > 0 ? `
        <div class="report-suggestions">
            <h4>📝 建议</h4>
            <ul>
                ${report.suggestions.map(s => `<li>${s}</li>`).join('')}
            </ul>
        </div>
        ` : ''}
    `;
    
    // 插入到统计区域前面
    statsSection.parentNode.insertBefore(reportCard, statsSection);
}

// 格式化周范围
function formatWeekRange(startStr, endStr) {
    const start = new Date(startStr);
    const end = new Date(endStr);
    const options = { month: 'short', day: 'numeric' };
    return `${start.toLocaleDateString('zh-CN', options)} - ${end.toLocaleDateString('zh-CN', options)}`;
}

// 导出函数供全局使用
window.openRecordModal = openRecordModal;
window.closeRecordModal = closeRecordModal;
window.scrollToDreams = scrollToDreams;
window.viewDream = viewDream;
window.shareDream = shareDream;
window.toggleFavorite = toggleFavorite;
window.loadWeeklyReport = loadWeeklyReport;
