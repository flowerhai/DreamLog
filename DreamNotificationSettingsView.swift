//
//  DreamNotificationSettingsView.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  通知设置 UI
//

import SwiftUI

struct DreamNotificationSettingsView: View {
    @StateObject private var notificationService = DreamNotificationService.shared
    @StateObject private var scheduler = DreamNotificationScheduler.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isShowingPermissionAlert = false
    @State private var selectedNotificationType: DreamNotificationType?
    
    var body: some View {
        NavigationView {
            Form {
                // 全局设置
                Section(header: Text("全局设置")) {
                    Toggle("启用通知", isOn: $notificationService.settings.isNotificationsEnabled)
                        .onChange(of: notificationService.settings.isNotificationsEnabled) { newValue in
                            Task {
                                if newValue {
                                    try? await notificationService.requestAuthorization()
                                }
                            }
                        }
                    
                    Toggle("智能调度", isOn: $notificationService.settings.isSmartSchedulingEnabled)
                        .onChange(of: notificationService.settings.isSmartSchedulingEnabled) { _ in
                            Task {
                                await scheduler.rescheduleAllNotifications()
                            }
                        }
                    
                    HStack {
                        Text("安静时间开始")
                        Spacer()
                        TimePicker(time: $notificationService.settings.quietHoursStart)
                    }
                    
                    HStack {
                        Text("安静时间结束")
                        Spacer()
                        TimePicker(time: $notificationService.settings.quietHoursEnd)
                    }
                }
                
                // 通知类型设置
                Section(header: Text("通知类型")) {
                    ForEach(notificationService.settings.configurations, id: \.id) { config in
                        NotificationConfigRow(
                            config: config,
                            isOn: Binding(
                                get: { config.isEnabled },
                                set: { isEnabled in
                                    Task {
                                        await notificationService.toggleNotification(
                                            type: config.type,
                                            enabled: isEnabled
                                        )
                                    }
                                }
                            ),
                            onSelect: {
                                selectedNotificationType = config.type
                            }
                        )
                    }
                }
                
                // 统计信息
                Section(header: Text("统计")) {
                    HStack {
                        Text("总发送数")
                        Spacer()
                        Text("\(notificationService.statistics.totalSent)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("打开率")
                        Spacer()
                        Text("\(String(format: "%.1f", notificationService.statistics.openRate * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastSent = notificationService.statistics.lastSentDate {
                        HStack {
                            Text("最后发送")
                            Spacer()
                            Text(lastSent, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 即将到来的通知
                if !scheduler.upcomingNotifications.isEmpty {
                    Section(header: Text("即将到来的通知")) {
                        ForEach(scheduler.upcomingNotifications.prefix(5)) { notification in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: notification.type.icon)
                                        .foregroundColor(.purple)
                                        .frame(width: 24)
                                    
                                    Text(notification.title)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    if notification.isRecurring {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text(notification.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 操作
                Section {
                    Button("重新调度所有通知") {
                        Task {
                            await scheduler.rescheduleAllNotifications()
                        }
                    }
                    
                    Button("请求通知权限") {
                        Task {
                            try? await notificationService.requestAuthorization()
                        }
                    }
                }
            }
            .navigationTitle("通知设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await notificationService.checkAuthorizationStatus()
                }
            }
        }
    }
}

// MARK: - 通知配置行

struct NotificationConfigRow: View {
    let config: DreamNotificationConfig
    let isOn: Binding<Bool>
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // 图标
                Image(systemName: config.type.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: config.type.color))
                    .frame(width: 32)
                
                // 信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let time = config.scheduledTime {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("·")
                                .foregroundColor(.secondary)
                            
                            Text(config.frequency.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 开关
                Toggle("", isOn: isOn)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 时间选择器

struct TimePicker: View {
    @Binding var time: String
    
    var body: some View {
        HStack {
            Picker("小时", selection: hour) {
                ForEach(0..<24) { hour in
                    Text(String(format: "%02d", hour)).tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60)
            
            Text(":")
            
            Picker("分钟", selection: minute) {
                ForEach(0..<60) { minute in
                    Text(String(format: "%02d", minute)).tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60)
        }
        .frame(height: 100)
    }
    
    private var hour: Binding<Int> {
        Binding(
            get: { Int(time.split(separator: ":").first ?? "0") ?? 0 },
            set: { hour in
                let minute = Int(time.split(separator: ":").last ?? "0") ?? 0
                time = String(format: "%02d:%02d", hour, minute)
            }
        )
    }
    
    private var minute: Binding<Int> {
        Binding(
            get: { Int(time.split(separator: ":").last ?? "0") ?? 0 },
            set: { minute in
                let hour = Int(time.split(separator: ":").first ?? "0") ?? 0
                time = String(format: "%02d:%02d", hour, minute)
            }
        )
    }
}

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 预览

struct DreamNotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DreamNotificationSettingsView()
    }
}
