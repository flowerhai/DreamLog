//
//  DigitalWellnessSettingsView.swift
//  DreamLog
//
//  Phase 93: 数字健康设置界面
//

import SwiftUI
import UIKit

struct DigitalWellnessSettingsView: View {
    @StateObject private var service = DreamScreenTimeService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showingExportConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var exportSuccess = false
    @State private var exportError: String?
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - 追踪设置
                
                Section("追踪设置") {
                    Toggle("启用屏幕时间追踪", isOn: $service.isTracking)
                    
                    Toggle("自动导入 iOS 屏幕时间", isOn: $service.settings.autoImport)
                    
                    Picker("数据刷新频率", selection: $service.settings.refreshInterval) {
                        Text("实时").tag(RefreshInterval.realtime)
                        Text("每 15 分钟").tag(RefreshInterval.fifteenMinutes)
                        Text("每 30 分钟").tag(RefreshInterval.thirtyMinutes)
                        Text("每小时").tag(RefreshInterval.hourly)
                    }
                }
                
                // MARK: - 使用限制
                
                Section("使用限制") {
                    HStack {
                        Text("每日屏幕时间限制")
                        Spacer()
                        Stepper("\(service.settings.dailyLimitMinutes) 分钟", value: $service.settings.dailyLimitMinutes, in: 30...480, step: 30)
                    }
                    
                    HStack {
                        Text("每日启动次数限制")
                        Spacer()
                        Stepper("\(service.settings.pickupLimit) 次", value: $service.settings.pickupLimit, in: 10...100, step: 5)
                    }
                    
                    HStack {
                        Text("睡前免打扰时间")
                        Spacer()
                        Stepper("\(service.settings.windDownMinutes) 分钟", value: $service.settings.windDownMinutes, in: 15...120, step: 15)
                    }
                }
                
                // MARK: - 通知设置
                
                Section("通知与提醒") {
                    Toggle("使用限制提醒", isOn: $service.settings.limitReminders)
                    
                    Toggle("睡前提醒", isOn: $service.settings.bedtimeReminders)
                    
                    Toggle("成就通知", isOn: $service.settings.achievementNotifications)
                    
                    if service.settings.bedtimeReminders {
                        DatePicker("提醒时间", selection: $service.settings.bedtimeReminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                // MARK: - 隐私设置
                
                Section("隐私") {
                    Toggle("隐藏通知内容", isOn: $service.settings.hideNotificationContent)
                    
                    Toggle("在小组件中隐藏数据", isOn: $service.settings.hideInWidgets)
                    
                    Button("导出屏幕时间数据") {
                        exportData()
                    }
                    
                    Button("清除所有屏幕时间数据") {
                        clearData()
                    }
                    .foregroundColor(.red)
                }
                
                // MARK: - 关于
                
                Section("关于") {
                    HStack {
                        Text("数据开始日期")
                        Spacer()
                        Text(formatDate(service.settings.trackingStartDate))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("总追踪天数")
                        Spacer()
                        Text("\(service.settings.trackingStartDate.map { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 } ?? 0) 天")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("数字健康设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onChange(of: service.settings) { _, _ in
                service.saveSettings()
            }
            .alert("导出成功", isPresented: $exportSuccess) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("屏幕时间数据已成功导出")
            }
            .alert("导出失败", isPresented: .constant(exportError != nil)) {
                Button("好的", role: .cancel) {
                    exportError = nil
                }
            } message: {
                Text(exportError ?? "未知错误")
            }
            .confirmationDialog("导出数据", isPresented: $showingExportConfirmation) {
                Button("导出为 JSON") {
                    performExport()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将导出所有屏幕时间数据、设置和成就为 JSON 文件")
            }
            .confirmationDialog("清除数据", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                Button("清除所有数据", role: .destructive) {
                    performClear()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作将删除所有屏幕时间记录和成就，但保留设置。此操作不可恢复！")
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未设置" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func exportData() {
        showingExportConfirmation = true
    }
    
    private func clearData() {
        showingClearConfirmation = true
    }
    
    private func performExport() {
        guard let exportData = service.exportData() else {
            exportError = service.errorMessage ?? "导出失败"
            return
        }
        
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let filename = "screen_time_export_\(dateFormatter.string(from: Date())).json"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try exportData.write(to: fileURL)
            
            // 使用 UIActivityViewController 分享文件
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // 获取窗口场景
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                // 适配 iPad
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = rootViewController.view
                    popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                rootViewController.present(activityVC, animated: true)
            }
            
            exportSuccess = true
        } catch {
            exportError = "保存文件失败：\(error.localizedDescription)"
        }
    }
    
    private func performClear() {
        service.clearAllData(keepSettings: true)
    }
}

extension DigitalWellnessSettingsView {
    private var exportConfirmationAlert: some View {
        ConfirmationDialog("导出数据", isPresented: $showingExportConfirmation) {
            Button("导出为 JSON") {
                performExport()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将导出所有屏幕时间数据、设置和成就为 JSON 文件")
        }
    }
    
    private var clearConfirmationAlert: some View {
        ConfirmationDialog("清除数据", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("清除所有数据", role: .destructive) {
                performClear()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作将删除所有屏幕时间记录和成就，但保留设置。此操作不可恢复！")
        }
    }
    
    private var exportSuccessAlert: some View {
        Alert(
            title: Text("导出成功"),
            message: Text("屏幕时间数据已成功导出"),
            dismissButton: .default(Text("好的"))
        )
    }
    
    private var exportErrorAlert: some View {
        Alert(
            title: Text("导出失败"),
            message: Text(exportError ?? "未知错误"),
            dismissButton: .default(Text("好的"))
        )
    }
}

#Preview {
    DigitalWellnessSettingsView()
}
