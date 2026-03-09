//
//  SmartReminderSettingsView.swift
//  DreamLog
//
//  智能提醒设置界面 - Phase 6 个性化体验
//

import SwiftUI

struct SmartReminderSettingsView: View {
    @ObservedObject var service: SmartReminderService
    @ObservedObject var dreamStore: DreamStore
    
    @State private var showingAuthRequest = false
    @State private var bedTime: String = "22:00"
    @State private var morningTime: String = "08:00"
    @State private var weeklyDay: Int = 0 // 0 = Sunday
    
    var body: some View {
        Form {
            // MARK: - 授权状态
            Section(header: Label("通知权限", systemImage: "bell.badge")) {
                HStack {
                    Image(systemName: service.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(service.isAuthorized ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(service.isAuthorized ? "已授权" : "未授权")
                            .font(.headline)
                        Text(service.isAuthorized ? "可以发送提醒通知" : "需要授权才能发送提醒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !service.isAuthorized {
                        Button("授权") {
                            requestAuthorization()
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - 总开关
            Section(header: Label("智能提醒", systemImage: "brain.head.profile")) {
                Toggle("启用智能提醒", isOn: $service.config.isEnabled)
                    .onChange(of: service.config.isEnabled) { _ in
                        service.saveConfig()
                    }
                
                if service.isAuthorized && service.config.isEnabled {
                    // 用户习惯分析
                    if let analysis = service.lastAnalysis {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📊 你的记录习惯")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("最佳记录时间")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(analysis.optimalHour):00")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading) {
                                    Text("连续记录")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(analysis.recordingStreak) 天")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading) {
                                    Text("总梦境数")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(analysis.totalDreams)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.1))
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // MARK: - 提醒类型
            if service.isAuthorized && service.config.isEnabled {
                Section(header: Label("提醒类型", systemImage: "list.bullet")) {
                    // 最佳时间提醒
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("⏰ 最佳时间提醒", systemImage: "clock.fill")
                            Spacer()
                            Toggle("", isOn: $service.config.optimalTimeEnabled)
                                .labelsHidden()
                                .onChange(of: service.config.optimalTimeEnabled) { _ in
                                    service.saveConfig()
                                }
                        }
                        
                        if service.config.optimalTimeEnabled {
                            Text("根据你的记录习惯，在最佳时间提醒你记录梦境")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 睡前提醒
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("🌙 睡前放松提醒", systemImage: "moon.fill")
                            Spacer()
                            Toggle("", isOn: $service.config.bedtimeEnabled)
                                .labelsHidden()
                                .onChange(of: service.config.bedtimeEnabled) { _ in
                                    service.saveConfig()
                                }
                        }
                        
                        if service.config.bedtimeEnabled {
                            HStack {
                                Text("提醒时间")
                                    .font(.subheadline)
                                Spacer()
                                TextField("HH:mm", text: $bedTime)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                                    .onChange(of: bedTime) { newValue in
                                        service.config.bedtimeTime = newValue
                                        service.saveConfig()
                                    }
                            }
                            .padding(.top, 4)
                            
                            Text("睡前回顾梦境，提高梦境回忆能力")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 晨间提醒
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("☀️ 晨间回顾提醒", systemImage: "sun.max.fill")
                            Spacer()
                            Toggle("", isOn: $service.config.morningEnabled)
                                .labelsHidden()
                                .onChange(of: service.config.morningEnabled) { _ in
                                    service.saveConfig()
                                }
                        }
                        
                        if service.config.morningEnabled {
                            HStack {
                                Text("提醒时间")
                                    .font(.subheadline)
                                Spacer()
                                TextField("HH:mm", text: $morningTime)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                                    .onChange(of: morningTime) { newValue in
                                        service.config.morningTime = newValue
                                        service.saveConfig()
                                    }
                            }
                            .padding(.top, 4)
                            
                            Text("起床后尽快记录，避免遗忘")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 每周总结
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("📊 每周总结提醒", systemImage: "calendar")
                            Spacer()
                            Toggle("", isOn: $service.config.weeklySummaryEnabled)
                                .labelsHidden()
                                .onChange(of: service.config.weeklySummaryEnabled) { _ in
                                    service.saveConfig()
                                }
                        }
                        
                        if service.config.weeklySummaryEnabled {
                            Picker("总结日期", selection: $weeklyDay) {
                                Text("周日").tag(0)
                                Text("周一").tag(1)
                                Text("周二").tag(2)
                                Text("周三").tag(3)
                                Text("周四").tag(4)
                                Text("周五").tag(5)
                                Text("周六").tag(6)
                            }
                            .onChange(of: weeklyDay) { newValue in
                                service.config.weeklySummaryDay = newValue
                                service.saveConfig()
                            }
                            
                            Text("每周回顾你的梦境数据和洞察")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 目标达成庆祝
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("🎉 目标达成庆祝", systemImage: "trophy.fill")
                            Spacer()
                            Toggle("", isOn: $service.config.goalCelebrationEnabled)
                                .labelsHidden()
                                .onChange(of: service.config.goalCelebrationEnabled) { _ in
                                    service.saveConfig()
                                }
                        }
                        
                        Text("完成记录目标时发送庆祝通知")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // 连续记录激励
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("🔥 连续记录激励", systemImage: "flame.fill")
                            Spacer()
                            Toggle("", isOn: $service.config.streakReminderEnabled)
                                .labelsHidden()
                                .onChange(of: service.config.streakReminderEnabled) { _ in
                                    service.saveConfig()
                                }
                        }
                        
                        Text("连续记录达到里程碑时发送激励通知")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - 测试通知
                Section(header: Label("测试", systemImage: "play.circle")) {
                    Button(action: sendTestNotification) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("发送测试通知")
                        }
                    }
                }
                
                // MARK: - 说明
                Section(header: Label("说明", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 智能提醒会根据你的记录习惯自动调整最佳提醒时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("📈 记录越多梦境，提醒越精准")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("🔕 可随时在系统设置中关闭通知")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                // 未授权或未启用的提示
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        if !service.isAuthorized {
                            Text("需要通知权限")
                                .font(.headline)
                            Text("请在系统设置中允许 DreamLog 发送通知")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("打开系统设置") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        } else if !service.config.isEnabled {
                            Text("智能提醒已关闭")
                                .font(.headline)
                            Text("开启智能提醒，让 AI 帮你养成记录习惯")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("智能提醒")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            bedTime = service.config.bedtimeTime
            morningTime = service.config.morningTime
            weeklyDay = service.config.weeklySummaryDay
            
            // 更新分析数据
            service.updateAnalysis(from: dreamStore)
        }
    }
    
    private func requestAuthorization() {
        service.requestAuthorization { granted in
            if granted {
                SmartReminderService.registerNotificationCategories()
                service.scheduleAllReminders()
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🌙 测试通知"
        content.body = "如果你看到这条消息，说明智能提醒系统工作正常！"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    NavigationView {
        SmartReminderSettingsView(
            service: SmartReminderService.shared,
            dreamStore: DreamStore.shared
        )
    }
}
