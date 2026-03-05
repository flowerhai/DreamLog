//
//  SettingsView.swift
//  DreamLog
//
//  设置页面
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = "08:00"
    @AppStorage("icloudSync") private var icloudSync = false
    @AppStorage("autoAnalysis") private var autoAnalysis = true
    
    var body: some View {
        NavigationView {
            Form {
                // 提醒设置
                Section(header: Text("提醒")) {
                    Toggle("晨间提醒", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        HStack {
                            Text("提醒时间")
                            Spacer()
                            TextField("HH:mm", text: $reminderTime)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("自动 AI 解析", isOn: $autoAnalysis)
                }
                
                // 数据与同步
                Section(header: Text("数据与同步")) {
                    Toggle("iCloud 同步", isOn: $icloudSync)
                    
                    Button("导出数据") {
                        // TODO: 导出功能
                    }
                    
                    Button("导入数据") {
                        // TODO: 导入功能
                    }
                    
                    Button("删除所有梦境", role: .destructive) {
                        // TODO: 删除功能
                    }
                }
                
                // 隐私
                Section(header: Text("隐私")) {
                    Link("隐私政策", destination: URL(string: "https://dreamlog.app/privacy")!)
                    
                    Link("服务条款", destination: URL(string: "https://dreamlog.app/terms")!)
                    
                    Toggle("匿名分享梦境", isOn: .constant(false))
                }
                
                // 关于
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("反馈问题") {
                        // TODO: 反馈功能
                    }
                    
                    Button("评分") {
                        // TODO: 评分功能
                    }
                }
                
                // 开发者选项
                Section(header: Text("开发者")) {
                    Button("清除缓存") {
                        // TODO: 清除缓存
                    }
                    
                    Toggle("调试模式", isOn: .constant(false))
                    
                    Button("测试 AI 解析") {
                        // TODO: 测试功能
                    }
                }
            }
            .navigationTitle("设置 ⚙️")
        }
    }
}

#Preview {
    SettingsView()
}
