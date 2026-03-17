//
//  DreamSmartNotificationSettingsView.swift
//  DreamLog
//
//  Phase 61: 智能通知与梦境洞察推送
//  设置界面：通知偏好配置
//

import SwiftUI
import SwiftData

/// 智能通知设置界面
struct DreamSmartNotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configs: [SmartNotificationConfig]
    
    @ObservedObject private var service = DreamSmartNotificationService.shared
    @State private var showingPermissionAlert = false
    @State private var selectedConfig: SmartNotificationConfig?
    
    var body: some View {
        NavigationView {
            Form {
                if configs.isEmpty {
                    ProgressView("加载中...")
                } else {
                    let config = configs[0]
                    
                    // 基础提醒
                    Section("基础提醒") {
                        Toggle("🌙 梦境记录提醒", isOn: $config.isDreamReminderEnabled)
                        
                        if config.isDreamReminderEnabled {
                            TimePickerView(
                                hour: $config.dreamReminderHour,
                                minute: $config.dreamReminderMinute,
                                label: "提醒时间"
                            )
                        }
                        
                        Toggle("😴 睡前提醒", isOn: $config.isBedtimeReminderEnabled)
                        
                        if config.isBedtimeReminderEnabled {
                            TimePickerView(
                                hour: $config.bedtimeHour,
                                minute: $config.bedtimeMinute,
                                label: "睡前时间"
                            )
                        }
                    }
                    
                    // 智能洞察
                    Section("智能洞察") {
                        Toggle("🌅 晨间反思", isOn: $config.isMorningReflectionEnabled)
                        
                        Toggle("📊 每周摘要", isOn: $config.isWeeklySummaryEnabled)
                        
                        Toggle("🧠 月度洞察", isOn: $config.isMonthlyInsightEnabled)
                        
                        Toggle("🔍 模式发现提醒", isOn: $config.isPatternAlertEnabled)
                    }
                    
                    // 挑战与成就
                    Section("挑战与成就") {
                        Toggle("🎯 挑战提醒", isOn: $config.isChallengeReminderEnabled)
                        
                        Toggle("🏆 成就解锁通知", isOn: $config.isAchievementNotificationEnabled)
                    }
                    
                    // 清醒梦提示
                    Section("清醒梦训练") {
                        Toggle("👁️ 现实检查提示", isOn: $config.isLucidDreamPromptEnabled)
                        
                        if config.isLucidDreamPromptEnabled {
                            Picker("提示频率", selection: $config.lucidDreamPromptFrequency) {
                                ForEach(LucidDreamPromptFrequency.allCases, id: \.self) { frequency in
                                    Text(frequency.displayName).tag(frequency)
                                }
                            }
                            
                            Text("清醒梦提示会在白天定期提醒你进行现实检查")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 免打扰
                    Section("免打扰时段") {
                        Toggle("启用免打扰", isOn: $config.isDoNotDisturbEnabled)
                        
                        if config.isDoNotDisturbEnabled {
                            HStack {
                                Text("开始时间")
                                Spacer()
                                Picker("", selection: $config.doNotDisturbStartHour) {
                                    ForEach(0..<24) { hour in
                                        Text(String(format: "%02d:00", hour)).tag(hour)
                                    }
                                }
                                .labelsHidden()
                            }
                            
                            HStack {
                                Text("结束时间")
                                Spacer()
                                Picker("", selection: $config.doNotDisturbEndHour) {
                                    ForEach(0..<24) { hour in
                                        Text(String(format: "%02d:00", hour)).tag(hour)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                    }
                    
                    // 智能定时
                    Section("智能定时") {
                        Toggle("🧠 基于活跃时间自动调整", isOn: $config.isSmartTimingEnabled)
                        
                        if config.isSmartTimingEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(.accentColor)
                                    Text("当前建议时间")
                                        .font(.subheadline)
                                }
                                
                                let optimalTime = service.calculateOptimalReminderTime()
                                Text(String(format: "%02d:%02d", optimalTime.hour, optimalTime.minute))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                                
                                Text("系统会根据你的使用习惯自动调整提醒时间")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // 通知统计
                    Section("通知统计") {
                        HStack {
                            Text("待发送通知")
                            Spacer()
                            Text("\(service.pendingNotifications)")
                                .foregroundColor(.secondary)
                        }
                        
                        if let lastWeekly = service.lastWeeklySummaryDate {
                            HStack {
                                Text("上周摘要发送时间")
                                Spacer()
                                Text(lastWeekly.formatted(.dateTime.day().month().hour().minute()))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 操作
                    Section {
                        Button(role: .destructive) {
                            service.cancelAllNotifications()
                        } label: {
                            HStack {
                                Spacer()
                                Text("取消所有通知")
                                Spacer()
                            }
                        }
                        
                        Button {
                            Task {
                                await service.scheduleAllNotifications()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("立即应用设置")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("智能通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await requestPermission()
                        }
                    } label: {
                        Image(systemName: service.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                            .foregroundColor(service.isAuthorized ? .accentColor : .orange)
                    }
                }
            }
            .alert("需要通知权限", isPresented: $showingPermissionAlert) {
                Button("取消", role: .cancel) {}
                Button("去设置") {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            } message: {
                Text("请在系统设置中允许 DreamLog 发送通知，以便接收梦境提醒和洞察推送。")
            }
            .onAppear {
                if configs.isEmpty {
                    createDefaultConfig()
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func createDefaultConfig() {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString
        let config = SmartNotificationConfig(userId: userId)
        modelContext.insert(config)
        
        try? modelContext.save()
    }
    
    private func requestPermission() async {
        let granted = await service.requestAuthorization()
        
        if !granted {
            showingPermissionAlert = true
        }
    }
}

// MARK: - 时间选择器

struct TimePickerView: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let label: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            
            HStack(spacing: 4) {
                Picker("", selection: $hour) {
                    ForEach(0..<24) { hour in
                        Text(String(format: "%02d", hour)).tag(hour)
                    }
                }
                .frame(width: 60)
                .labelsHidden()
                
                Text(":")
                    .font(.headline)
                
                Picker("", selection: $minute) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                .frame(width: 60)
                .labelsHidden()
            }
            .pickerStyle(.wheel)
        }
    }
}

// MARK: - 预览

#Preview {
    DreamSmartNotificationSettingsView()
        .modelContainer(for: SmartNotificationConfig.self, inMemory: true)
}
