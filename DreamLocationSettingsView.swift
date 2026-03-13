//
//  DreamLocationSettingsView.swift
//  DreamLog - 位置服务设置
//
//  Phase 31: 梦境地图功能
//  创建时间：2026-03-13
//

import SwiftUI
import CoreLocation

struct DreamLocationSettingsView: View {
    @EnvironmentObject var locationService: DreamLocationService
    @State private var showPermissionAlert = false
    
    var body: some View {
        Form {
            // 权限状态
            Section(header: Text("位置权限")) {
                HStack {
                    Text("权限状态")
                    Spacer()
                    HStack {
                        Circle()
                            .fill(permissionColor)
                            .frame(width: 10, height: 10)
                        Text(locationService.permissionStatus.description)
                            .foregroundColor(.secondary)
                    }
                }
                
                if locationService.permissionStatus == .denied {
                    Button("前往设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // 位置追踪设置
            Section(header: Text("位置追踪")) {
                Toggle("启用位置追踪", isOn: $locationService.config.enableLocationTracking)
                
                if locationService.config.enableLocationTracking {
                    Toggle("自动记录位置", isOn: $locationService.config.autoRecordLocation)
                    
                    TextField("默认位置名称", text: Binding(
                        get: { locationService.config.defaultLocationName ?? "" },
                        set: { locationService.updateConfig { $0.defaultLocationName = $0.isEmpty ? nil : $0 } }
                    ))
                    .placeholder(when: (locationService.config.defaultLocationName ?? "").isEmpty) {
                        Text("例如：家、卧室")
                    }
                }
            }
            
            // 隐私设置
            Section(header: Text("隐私与安全")) {
                Toggle("隐私模式", isOn: $locationService.config.privacyMode)
                    .description(Text("启用后位置信息会被模糊处理"))
                
                Toggle("在地图上显示", isOn: $locationService.config.showInMap)
            }
            
            // 使用说明
            Section(header: Text("使用说明")) {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "location.fill", text: "记录梦境时会自动保存当前位置")
                    InfoRow(icon: "map.fill", text: "在地图视图查看梦境分布")
                    InfoRow(icon: "shield.fill", text: "位置数据仅存储在本地，不会上传")
                    InfoRow(icon: "gearshape.fill", text: "可随时在设置中关闭位置追踪")
                }
            }
            
            // 统计数据
            Section(header: Text("统计")) {
                let stats = locationService.getLocationStatistics()
                HStack {
                    Text("已记录位置")
                    Spacer()
                    Text("\(stats.totalLocations) 个")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("覆盖城市")
                    Spacer()
                    Text("\(stats.uniqueCities) 个")
                        .foregroundColor(.secondary)
                }
                
                if !stats.countries.isEmpty {
                    HStack {
                        Text("覆盖国家")
                        Spacer()
                        Text("\(stats.countries.count) 个")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("位置服务")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationService.checkPermissionStatus()
        }
        .alert("需要位置权限", isPresented: $showPermissionAlert) {
            Button("取消", role: .cancel) { }
            Button("前往设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("位置权限用于记录梦境发生的地点，帮助你在地图上查看梦境分布。")
        }
    }
    
    private var permissionColor: Color {
        switch locationService.permissionStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notDetermined:
            return .gray
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        DreamLocationSettingsView()
            .environmentObject(DreamLocationService.shared)
    }
}
