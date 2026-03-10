/**
 * DreamLog - 智能梦境记录应用
 * 前端 JavaScript
 */

// API 基础 URL
const API_BASE = '/api';

// 当前选中的梦境 ID
let currentDreamId = null;

// DOM 元素
const sections = document.querySelectorAll('.section');
const navBtns = document.querySelectorAll('.nav-btn');
const dreamForm = document.getElementById('dreamForm');
const dreamList = document.getElementById('dreamList');
const analysisResult = document.getElementById('analysisResult');
const galleryGrid = document.getElementById('galleryGrid');
const statsOverview = document.getElementById('statsOverview');
const dreamModal = document.getElementById('dreamModal');
const modalBody = document.getElementById('modalBody');

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    initNavigation();
    initForm();
    initModal();
    loadDreams();
    loadStats();
});

// 导航切换
function initNavigation() {
    navBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            const target = btn.getAttribute('href').substring(1);
            
            // 更新激活状态
            navBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            
            // 切换 section
            sections.forEach(section => {
                section.classList.remove('active');
                if (section.id === target) {
                    section.classList.add('active');
                }
            });
            
            // 加载对应数据
            switch(target) {
                case 'dreams':
                    loadDreams();
                    break;
                case 'analysis':
                    if (currentDreamId) loadAnalysis(currentDreamId);
                    break;
                case 'gallery':
                    loadGallery();
                    break;
                case 'stats':
                    loadStats();
                    break;
            }
        });
    });
}

// 表单提交
function initForm() {
    // 情绪强度滑块
    const intensitySlider = document.getElementById('moodIntensity');
    const intensityValue = document.getElementById('intensityValue');
    
    intensitySlider.addEventListener('input', () => {
        intensityValue.textContent = intensitySlider.value;
    });
    
    // 表单提交
    dreamForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const data = {
            title: document.getElementById('dreamTitle').value || null,
            content: document.getElementById('dreamContent').value,
            mood: document.getElementById('dreamMood').value || null,
            mood_intensity: parseInt(document.getElementById('moodIntensity').value),
            sleep_quality: document.getElementById('sleepQuality').value ? parseInt(document.getElementById('sleepQuality').value) : null,
            clarity: document.getElementById('clarity').value ? parseInt(document.getElementById('clarity').value) : null,
            is_lucid: document.getElementById('isLucid').checked,
            is_recurring: document.getElementById('isRecurring').checked
        };
        
        try {
            const response = await fetch(`${API_BASE}/dreams/`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
            
            if (response.ok) {
                const result = await response.json();
                showToast('梦境保存成功！✨', 'success');
                dreamForm.reset();
                intensityValue.textContent = '5';
                currentDreamId = result.id;
                
                // 自动跳转到分析页面
                setTimeout(() => {
                    document.querySelector('[href="#analysis"]').click();
                    loadAnalysis(result.id);
                }, 1000);
            } else {
                throw new Error('保存失败');
            }
        } catch (error) {
            showToast('保存失败，请重试', 'error');
            console.error(error);
        }
    });
}

// 加载梦境列表
async function loadDreams() {
    try {
        const response = await fetch(`${API_BASE}/dreams/?page=1&page_size=50`);
        if (response.ok) {
            const data = await response.json();
            renderDreamList(data.items);
        }
    } catch (error) {
        console.error('加载梦境失败:', error);
    }
}

// 渲染梦境列表
function renderDreamList(dreams) {
    if (!dreams || dreams.length === 0) {
        dreamList.innerHTML = '<div class="empty-state">还没有梦境记录，快去记录第一个梦吧！🌙</div>';
        return;
    }
    
    dreamList.innerHTML = dreams.map(dream => `
        <div class="dream-card" onclick="showDreamDetail(${dream.id})">
            <div class="dream-card-header">
                <div class="dream-title">${dream.title || '无题梦境'}</div>
                <div class="dream-date">${formatDate(dream.dream_date)}</div>
            </div>
            <div class="dream-preview">${dream.content.substring(0, 100)}...</div>
            <div class="dream-tags">
                ${dream.mood ? `<span class="tag mood">${getMoodEmoji(dream.mood)} ${dream.mood}</span>` : ''}
                ${dream.is_lucid ? '<span class="tag">清醒梦</span>' : ''}
                ${dream.is_recurring ? '<span class="tag">重复梦境</span>' : ''}
            </div>
        </div>
    `).join('');
}

// 显示梦境详情
async function showDreamDetail(dreamId) {
    try {
        const response = await fetch(`${API_BASE}/dreams/${dreamId}`);
        if (response.ok) {
            const dream = await response.json();
            currentDreamId = dream.id;
            
            modalBody.innerHTML = `
                <h2>${dream.title || '无题梦境'}</h2>
                <p class="dream-date">${formatDate(dream.dream_date)}</p>
                <hr style="border: 0; border-top: 1px solid var(--border); margin: 1rem 0;">
                <div class="analysis-text">${dream.content}</div>
                ${dream.mood ? `<p><strong>情绪:</strong> ${getMoodEmoji(dream.mood)} ${dream.mood}</p>` : ''}
                ${dream.analysis ? `
                    <div style="margin-top: 1.5rem;">
                        <button class="btn btn-primary" onclick="loadAnalysis(${dream.id})">🧠 AI 解析</button>
                        <button class="btn btn-secondary" onclick="generateImage(${dream.id})">🎨 生成图像</button>
                    </div>
                ` : ''}
            `;
            
            dreamModal.classList.add('active');
        }
    } catch (error) {
        console.error('加载梦境详情失败:', error);
    }
}

// 加载 AI 解析
async function loadAnalysis(dreamId) {
    analysisResult.innerHTML = '<div class="loading"></div> 正在解析梦境...';
    
    try {
        const response = await fetch(`${API_BASE}/analysis/analyze`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ dream_id: dreamId })
        });
        
        if (response.ok) {
            const data = await response.json();
            renderAnalysis(data.analysis);
        } else {
            analysisResult.innerHTML = '<div class="empty-state">解析失败，请重试</div>';
        }
    } catch (error) {
        console.error('解析失败:', error);
        analysisResult.innerHTML = '<div class="empty-state">解析失败，请重试</div>';
    }
}

// 渲染解析结果
function renderAnalysis(analysis) {
    analysisResult.innerHTML = `
        <div class="analysis-section">
            <h3>📝 梦境摘要</h3>
            <p class="analysis-text">${analysis.summary}</p>
        </div>
        
        <div class="analysis-section">
            <h3>🎯 主要主题</h3>
            <div class="theme-list">
                ${analysis.themes.map(t => `<span class="theme-item">${t}</span>`).join('')}
            </div>
        </div>
        
        <div class="analysis-section">
            <h3>🔮 象征物</h3>
            <div class="symbol-list">
                ${analysis.symbols.map(s => `<span class="symbol-item">${s.name}: ${s.meaning}</span>`).join('')}
            </div>
        </div>
        
        <div class="analysis-section">
            <h3>💭 详细解读</h3>
            <p class="analysis-text">${analysis.interpretation}</p>
        </div>
        
        <div class="analysis-section">
            <h3>🧠 心理学含义</h3>
            <p class="analysis-text">${analysis.psychological_meaning}</p>
        </div>
        
        <div class="analysis-section">
            <h3>😊 情绪状态</h3>
            <p class="analysis-text">${analysis.emotional_state}</p>
        </div>
        
        <div class="analysis-section">
            <h3>💡 建议</h3>
            <ul class="suggestion-list">
                ${analysis.suggestions.map(s => `<li>${s}</li>`).join('')}
            </ul>
        </div>
    `;
}

// 生成图像
async function generateImage(dreamId) {
    showToast('正在生成梦境图像...', 'success');
    
    try {
        const response = await fetch(`${API_BASE}/gallery/generate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ dream_id: dreamId, style: 'surreal' })
        });
        
        if (response.ok) {
            const data = await response.json();
            showToast('图像生成成功！🎨', 'success');
            dreamModal.classList.remove('active');
            document.querySelector('[href="#gallery"]').click();
        } else {
            showToast('生成失败，请重试', 'error');
        }
    } catch (error) {
        console.error('生成失败:', error);
        showToast('生成失败，请重试', 'error');
    }
}

// 加载画廊
async function loadGallery() {
    try {
        const response = await fetch(`${API_BASE}/gallery/gallery`);
        if (response.ok) {
            const data = await response.json();
            renderGallery(data.items);
        }
    } catch (error) {
        console.error('加载画廊失败:', error);
    }
}

// 渲染画廊
function renderGallery(items) {
    if (!items || items.length === 0) {
        galleryGrid.innerHTML = '<div class="empty-state">还没有生成的梦境图像<br>先记录梦境并生成吧！🎨</div>';
        return;
    }
    
    galleryGrid.innerHTML = items.map(item => `
        <div class="gallery-item">
            <img src="${item.image_url}" alt="${item.title}" class="gallery-image" onerror="this.src='https://via.placeholder.com/512?text=Dream'">
            <div class="gallery-info">
                <div class="gallery-title">${item.title || '无题梦境'}</div>
                <div class="gallery-date">${formatDate(item.created_at)}</div>
            </div>
        </div>
    `).join('');
}

// 加载统计
async function loadStats() {
    try {
        const response = await fetch(`${API_BASE}/stats/overview`);
        if (response.ok) {
            const data = await response.json();
            renderStats(data);
        }
    } catch (error) {
        console.error('加载统计失败:', error);
    }
}

// 渲染统计
function renderStats(stats) {
    const o = stats.overview;
    
    statsOverview.innerHTML = `
        <div class="stat-card">
            <div class="stat-value">${o.total_dreams}</div>
            <div class="stat-label">总梦境数</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">${o.total_days}</div>
            <div class="stat-label">记录天数</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">${o.avg_dreams_per_week}</div>
            <div class="stat-label">平均每周</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">${o.lucid_dream_count}</div>
            <div class="stat-label">清醒梦</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">${o.recurring_dream_count}</div>
            <div class="stat-label">重复梦境</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">${getMoodEmoji(o.most_common_mood)}</div>
            <div class="stat-label">最常见情绪：${o.most_common_mood || '-'}</div>
        </div>
    `;
}

// 模态框
function initModal() {
    const closeBtn = document.querySelector('.modal-close');
    closeBtn.addEventListener('click', () => {
        dreamModal.classList.remove('active');
    });
    
    dreamModal.addEventListener('click', (e) => {
        if (e.target === dreamModal) {
            dreamModal.classList.remove('active');
        }
    });
}

// 工具函数
function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleDateString('zh-CN', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function getMoodEmoji(mood) {
    const emojis = {
        happy: '😊',
        excited: '🤩',
        calm: '😌',
        anxious: '😰',
        scared: '😨',
        sad: '😢',
        confused: '😕',
        strange: '🤔'
    };
    return emojis[mood] || '😐';
}

function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    setTimeout(() => toast.classList.add('show'), 10);
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}
