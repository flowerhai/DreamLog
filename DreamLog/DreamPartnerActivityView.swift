//
//  DreamPartnerActivityView.swift
//  DreamLog
//
//  梦境伴侣活动动态 - UI 界面
//  Phase 88 Enhancement: 活动动态与通知增强
//

import SwiftUI
import SwiftData

struct DreamPartnerActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var activityService = DreamPartnerActivityService()
    
    @State private var selectedFilter: ActivityFilter = .all
    @State private var showingSettings = false
    @State private var searchText = ""
    
    @Query private var activities: [PartnerActivity]
    
    enum ActivityFilter: String, CaseIterable {
        case all = "全部"
        case shares = "分享"
        case comments = "评论"
        case reactions = "反应"
        case connections = "连接"
    }
    
    var filteredActivities: [PartnerActivity] {
        var result = activities
        
        // 按类型过滤
        switch selectedFilter {
        case .all:
            break
        case .shares:
            result = result.filter { $0.type == .dreamShared }
        case .comments:
            result = result.filter { $0.type == .commentAdded }
        case .reactions:
            result = result.filter { $0.type == .reactionAdded }
        case .connections:
            result = result.filter { $0.type == .partnerConnected || $0.type == .inviteAccepted }
        }
        
        // 搜索过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.actorName.localizedCaseInsensitiveContains(searchText) ||
                ($0.targetTitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.content?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return result
    }
    
    var unreadCount: Int {
        activities.filter { !$0.isRead }.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选器
                filterBar
                
                // 活动列表
                if filteredActivities.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
            .navigationTitle("活动动态")
            .searchable(text: $searchText, prompt: "搜索活动")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if unreadCount > 0 {
                        Button(action: { activityService.markAllAsRead() }) {
                            Image(systemName: "checkmark.circle")
                                .badge(unreadCount)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                ActivitySettingsView(settings: activityService.getNotificationSettings()) { settings in
                    activityService.updateNotificationSettings(settings)
                }
            }
        }
    }
    
    // MARK: - 筛选器
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActivityFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 活动列表
    
    private var activityList: some View {
        List(filteredActivities) { activity in
            ActivityRowView(
                activity: activity,
                onTap: {
                    activityService.markAsRead(activity)
                }
            )
        }
        .listStyle(.plain)
    }
    
    // MARK: - 空状态
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter == .all ? "bell.slash" : "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(selectedFilter == .all ? "暂无活动" : "没有相关活动")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("当有伴侣互动时，活动将显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 筛选芯片

struct FilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.purple : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - 活动行视图

struct ActivityRowView: View {
    var activity: PartnerActivity
    var onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color(activity.type.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: activity.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(activity.type.color))
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.actorName)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(activity.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(activity.activityDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let content = activity.content, activity.type == .commentAdded {
                    Text(content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            // 未读指示器
            if !activity.isRead {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - 设置视图

struct ActivitySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State var settings: PartnerNotificationSettings
    var onSave: (PartnerNotificationSettings) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("通知类型")) {
                    Toggle("梦境分享", isOn: $settings.enableDreamShared)
                    Toggle("梦境查看", isOn: $settings.enableDreamViewed)
                    Toggle("评论", isOn: $settings.enableCommentAdded)
                    Toggle("反应", isOn: $settings.enableReactionAdded)
                    Toggle("新连接", isOn: $settings.enablePartnerConnected)
                    Toggle("邀请接受", isOn: $settings.enableInviteAccepted)
                }
                
                Section(header: Text("安静时段")) {
                    Toggle("启用安静时段", isOn: $settings.quietHoursEnabled)
                    
                    if settings.quietHoursEnabled {
                        HStack {
                            Text("开始时间")
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: { timeToDate(settings.quietHoursStart) },
                                set: { settings.quietHoursStart = dateToTime($0) }
                            ), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("结束时间")
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: { timeToDate(settings.quietHoursEnd) },
                                set: { settings.quietHoursEnd = dateToTime($0) }
                            ), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                }
                
                Section(header: Text("数据管理")) {
                    Button(role: .destructive) {
                        // 清理旧活动
                    } label: {
                        HStack {
                            Text("清理 30 天前的活动")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .navigationTitle("通知设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onSave(settings)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func timeToDate(_ time: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: time) ?? Date()
    }
    
    private func dateToTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 预览

#Preview {
    DreamPartnerActivityView()
}
