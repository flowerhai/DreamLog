//
//  DreamLogWidgetBundle.swift
//  DreamLog
//
//  Phase 90 - 交互式小组件注册入口
//

import WidgetKit
import SwiftUI

@main
struct DreamLogWidgetBundle: WidgetBundle {
    
    var body: some Widget {
        // Phase 33 基础小组件
        DreamLogQuickWidget()
        DreamLogWidget()
        
        // Phase 90 新增交互式小组件
        DreamLogInteractiveQuickRecordWidget()
        DreamLogInteractiveDailyInsightWidget()
        DreamLogInteractiveStatsWidget()
        DreamLogInteractiveDreamCardWidget()
        
        // Phase 90 锁屏小组件
        DreamLogLockScreenWidgetBundle()
        
        // Phase 90 实时活动
        DreamLogLiveActivityBundle()
    }
}

// MARK: - 锁屏小组件 Bundle

struct DreamLogLockScreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        DreamLogLockScreenCircularWidget()
        DreamLogLockScreenRectangularWidget()
        DreamLogLockScreenCompactWidget()
    }
}

// MARK: - 实时活动 Bundle

struct DreamLogLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        DreamLogIncubationLiveActivity()
        DreamLogMorningReflectionLiveActivity()
    }
}
