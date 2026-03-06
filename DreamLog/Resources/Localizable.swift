//
//  Localizable.swift
//  DreamLog
//
//  多语言本地化支持 - 集中管理所有本地化字符串
//

import Foundation

// MARK: - 本地化助手
enum L {
    // MARK: 通用
    static let save = NSLocalizedString("save", comment: "保存按钮")
    static let cancel = NSLocalizedString("cancel", comment: "取消按钮")
    static let delete = NSLocalizedString("delete", comment: "删除按钮")
    static let done = NSLocalizedString("done", comment: "完成按钮")
    static let edit = NSLocalizedString("edit", comment: "编辑按钮")
    static let add = NSLocalizedString("add", comment: "添加按钮")
    static let confirm = NSLocalizedString("confirm", comment: "确认按钮")
    static let loading = NSLocalizedString("loading", comment: "加载中")
    static let success = NSLocalizedString("success", comment: "成功")
    static let error = NSLocalizedString("error", comment: "错误")
    
    // MARK: 首页
    static let homeTitle = NSLocalizedString("homeTitle", comment: "首页标题")
    static let whatDidYouDream = NSLocalizedString("whatDidYouDream", comment: "昨晚你梦见了什么？")
    static let holdToSpeak = NSLocalizedString("holdToSpeak", comment: "按住说话")
    static let releaseToEnd = NSLocalizedString("releaseToEnd", comment: "松开结束")
    static let textInput = NSLocalizedString("textInput", comment: "文字输入")
    static let searchDreams = NSLocalizedString("searchDreams", comment: "搜索梦境、标签...")
    static let noDreamsYet = NSLocalizedString("noDreamsYet", comment: "还没有梦境记录")
    static let startRecording = NSLocalizedString("startRecording", comment: "开始记录第一个梦")
    
    // MARK: 记录页面
    static let recordTitle = NSLocalizedString("recordTitle", comment: "记录梦境")
    static let dreamContent = NSLocalizedString("dreamContent", comment: "梦境内容")
    static let contentPlaceholder = NSLocalizedString("contentPlaceholder", comment: "描述你的梦境...")
    static let selectTags = NSLocalizedString("selectTags", comment: "选择标签")
    static let selectEmotions = NSLocalizedString("selectEmotions", comment: "选择情绪")
    static let clarity = NSLocalizedString("clarity", comment: "清晰度")
    static let intensity = NSLocalizedString("intensity", comment: "强度")
    static let lucidDream = NSLocalizedString("lucidDream", comment: "清醒梦")
    static let aiAnalysis = NSLocalizedString("aiAnalysis", comment: "AI 解析")
    static let analyzing = NSLocalizedString("analyzing", comment: "分析中...")
    
    // MARK: 洞察页面
    static let insightsTitle = NSLocalizedString("insightsTitle", comment: "洞察")
    static let dreamStats = NSLocalizedString("dreamStats", comment: "梦境统计")
    static let totalDreams = NSLocalizedString("totalDreams", comment: "总梦境数")
    static let thisWeek = NSLocalizedString("thisWeek", comment: "本周")
    static let avgClarity = NSLocalizedString("avgClarity", comment: "平均清晰度")
    static let avgIntensity = NSLocalizedString("avgIntensity", comment: "平均强度")
    static let emotionDistribution = NSLocalizedString("emotionDistribution", comment: "情绪分布")
    static let topTags = NSLocalizedString("topTags", comment: "热门标签")
    static let timeDistribution = NSLocalizedString("timeDistribution", comment: "时间段分布")
    
    // MARK: 画廊
    static let galleryTitle = NSLocalizedString("galleryTitle", comment: "梦境画廊")
    static let aiArt = NSLocalizedString("aiArt", comment: "AI 绘画")
    static let generateArt = NSLocalizedString("generateArt", comment: "生成画作")
    static let generatingArt = NSLocalizedString("generatingArt", comment: "正在生成...")
    
    // MARK: 设置
    static let settingsTitle = NSLocalizedString("settingsTitle", comment: "设置")
    static let appearance = NSLocalizedString("appearance", comment: "外观")
    static let darkMode = NSLocalizedString("darkMode", comment: "深色模式")
    static let themeColor = NSLocalizedString("themeColor", comment: "主题色")
    static let widgets = NSLocalizedString("widgets", comment: "小组件")
    static let addWidget = NSLocalizedString("addWidget", comment: "添加小组件")
    static let notifications = NSLocalizedString("notifications", comment: "提醒")
    static let morningReminder = NSLocalizedString("morningReminder", comment: "晨间提醒")
    static let reminderTime = NSLocalizedString("reminderTime", comment: "提醒时间")
    static let autoAnalysis = NSLocalizedString("autoAnalysis", comment: "自动 AI 解析")
    static let dataAndSync = NSLocalizedString("dataAndSync", comment: "数据与同步")
    static let icloudSync = NSLocalizedString("icloudSync", comment: "iCloud 同步")
    static let exportData = NSLocalizedString("exportData", comment: "导出数据")
    static let importData = NSLocalizedString("importData", comment: "导入数据")
    static let deleteAll = NSLocalizedString("deleteAll", comment: "删除所有")
    static let feedback = NSLocalizedString("feedback", comment: "反馈")
    static let rateApp = NSLocalizedString("rateApp", comment: "评分")
    static let about = NSLocalizedString("about", comment: "关于")
    static let version = NSLocalizedString("version", comment: "版本")
    
    // MARK: Siri 快捷指令
    static let siriShortcuts = NSLocalizedString("siriShortcuts", comment: "Siri 与快捷指令")
    static let setupSiri = NSLocalizedString("setupSiri", comment: "设置 Siri 快捷指令")
    static let voiceCommands = NSLocalizedString("voiceCommands", comment: "可用语音命令")
    static let recordMyDream = NSLocalizedString("recordMyDream", comment: "记录我的梦境")
    static let myDreamStats = NSLocalizedString("myDreamStats", comment: "我的梦境统计")
    static let recentDreams = NSLocalizedString("recentDreams", comment: "我最近做了什么梦")
    static let siriTip = NSLocalizedString("siriTip", comment: "试试用 Siri 记录梦境")
    static let siriHint = NSLocalizedString("siriHint", comment: "也可以用 Siri 说\"记录我的梦境\"")
    
    // MARK: 梦境词典
    static let dreamDictionary = NSLocalizedString("dreamDictionary", comment: "梦境词典")
    static let searchSymbols = NSLocalizedString("searchSymbols", comment: "搜索梦境符号")
    static let categories = NSLocalizedString("categories", comment: "分类")
    static let interpretation = NSLocalizedString("interpretation", comment: "解读")
    
    // MARK: 清醒梦训练
    static let lucidTraining = NSLocalizedString("lucidTraining", comment: "清醒梦训练")
    static let realityChecks = NSLocalizedString("realityChecks", comment: "现实检查")
    static let techniques = NSLocalizedString("techniques", comment: "技巧")
    static let trainingPlan = NSLocalizedString("trainingPlan", comment: "训练计划")
    
    // MARK: 目标追踪
    static let goals = NSLocalizedString("goals", comment: "目标")
    static let weeklyGoal = NSLocalizedString("weeklyGoal", comment: "周目标")
    static let streak = NSLocalizedString("streak", comment: "连续记录")
    static let achievements = NSLocalizedString("achievements", comment: "成就")
    
    // MARK: 日历
    static let calendar = NSLocalizedString("calendar", comment: "日历")
    static let today = NSLocalizedString("today", comment: "今天")
    static let thisMonth = NSLocalizedString("thisMonth", comment: "本月")
    
    // MARK: 分享
    static let share = NSLocalizedString("share", comment: "分享")
    static let shareDream = NSLocalizedString("shareDream", comment: "分享梦境")
    static let saveToPhotos = NSLocalizedString("saveToPhotos", comment: "保存到相册")
    static let cardStyle = NSLocalizedString("cardStyle", comment: "选择卡片样式")
    static let classic = NSLocalizedString("classic", comment: "经典")
    static let minimal = NSLocalizedString("minimal", comment: "简约")
    static let dreamy = NSLocalizedString("dreamy", comment: "梦幻")
    static let gradient = NSLocalizedString("gradient", comment: "渐变")
    
    // MARK: 搜索
    static let search = NSLocalizedString("search", comment: "搜索")
    static let advancedSearch = NSLocalizedString("advancedSearch", comment: "高级搜索")
    static let filter = NSLocalizedString("filter", comment: "过滤")
    static let resetFilters = NSLocalizedString("resetFilters", comment: "重置过滤器")
    static let dateRange = NSLocalizedString("dateRange", comment: "日期范围")
    static let sortBy = NSLocalizedString("sortBy", comment: "排序")
    
    // MARK: 通知
    static let notificationsEnabled = NSLocalizedString("notificationsEnabled", comment: "通知已启用")
    static let notificationsDisabled = NSLocalizedString("notificationsDisabled", comment: "通知已禁用")
    static let permissionRequired = NSLocalizedString("permissionRequired", comment: "需要通知权限")
    
    // MARK: 错误信息
    static let noContent = NSLocalizedString("noContent", comment: "内容不能为空")
    static let saveFailed = NSLocalizedString("saveFailed", comment: "保存失败")
    static let loadFailed = NSLocalizedString("loadFailed", comment: "加载失败")
    static let syncFailed = NSLocalizedString("syncFailed", comment: "同步失败")
    static let networkError = NSLocalizedString("networkError", comment: "网络错误")
}

// MARK: - 格式化助手
enum F {
    static func date(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    static func dateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    static func number(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
