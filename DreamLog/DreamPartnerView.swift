//
//  DreamPartnerView.swift
//  DreamLog
//
//  梦境伴侣共享系统 - UI 界面
//  Phase 88: 梦境伴侣与家庭共享
//

import SwiftUI
import SwiftData

struct DreamPartnerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service = DreamPartnerService()
    
    @State private var selectedTab = 0
    @State private var showingInviteSheet = false
    @State private var showingAddPartnerSheet = false
    @State private var inviteCode = ""
    @State private var newPartnerName = ""
    @State private var showingSettings = false
    
    @Query private var partners: [DreamPartner]
    
    var activePartners: [DreamPartner] {
        partners.filter { $0.status == .accepted }
    }
    
    var pendingPartners: [DreamPartner] {
        partners.filter { $0.status == .pending }
    }
    
    var stats: PartnerSharingStats {
        service.getSharingStats()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计卡片
                statsCard
                
                // 分段控制器
                Picker("标签页", selection: $selectedTab) {
                    Text("活跃伴侣").tag(0)
                    Text("待处理 (\(pendingPartners.count))").tag(1)
                    Text("统计").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 内容区域
                TabContentView(
                    selectedTab: selectedTab,
                    activePartners: activePartners,
                    pendingPartners: pendingPartners,
                    stats: stats,
                    service: service,
                    partners: partners
                )
            }
            .navigationTitle("梦境伴侣")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInviteSheet = true }) {
                        Image(systemName: "link.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingAddPartnerSheet = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteSheet(service: service, isPresented: $showingInviteSheet)
            }
            .sheet(isPresented: $showingAddPartnerSheet) {
                AddPartnerSheet(
                    name: $newPartnerName,
                    service: service,
                    isPresented: $showingAddPartnerSheet
                )
            }
        }
    }
    
    // MARK: - 统计卡片
    
    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatItem(icon: "person.2", value: "\(stats.activePartners)", label: "活跃伴侣")
                Divider()
                StatItem(icon: "heart", value: "\(stats.totalShares)", label: "总分享")
                Divider()
                StatItem(icon: "eye", value: "\(stats.totalViews)", label: "查看次数")
                Divider()
                StatItem(icon: "bubble.left", value: "\(stats.totalComments)", label: "评论")
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - 标签页内容

struct TabContentView: View {
    var selectedTab: Int
    var activePartners: [DreamPartner]
    var pendingPartners: [DreamPartner]
    var stats: PartnerSharingStats
    var service: DreamPartnerService
    var partners: [DreamPartner]
    
    var body: some View {
        switch selectedTab {
        case 0:
            ActivePartnersView(partners: activePartners, service: service)
        case 1:
            PendingPartnersView(partners: pendingPartners, service: service)
        case 2:
            StatsView(stats: stats, partners: partners)
        default:
            EmptyView()
        }
    }
}

// MARK: - 活跃伴侣视图

struct ActivePartnersView: View {
    var partners: [DreamPartner]
    var service: DreamPartnerService
    
    var body: some View {
        if partners.isEmpty {
            EmptyStateView(
                icon: "person.2",
                title: "暂无伴侣",
                subtitle: "邀请伴侣一起共享梦境旅程"
            )
        } else {
            List {
                ForEach(partners, id: \.id) { partner in
                    PartnerRow(partner: partner, service: service)
                }
            }
        }
    }
}

// MARK: - 待处理伴侣视图

struct PendingPartnersView: View {
    var partners: [DreamPartner]
    var service: DreamPartnerService
    
    var body: some View {
        if partners.isEmpty {
            EmptyStateView(
                icon: "hourglass",
                title: "暂无待处理",
                subtitle: "新的伴侣请求会显示在这里"
            )
        } else {
            List {
                ForEach(partners, id: \.id) { partner in
                    PendingPartnerRow(partner: partner, service: service)
                }
            }
        }
    }
}

// MARK: - 统计视图

struct StatsView: View {
    var stats: PartnerSharingStats
    var partners: [DreamPartner]
    
    var body: some View {
        List {
            Section("概览") {
                StatRow(label: "总伴侣数", value: "\(stats.totalPartners)")
                StatRow(label: "活跃伴侣", value: "\(stats.activePartners)")
                StatRow(label: "待处理邀请", value: "\(stats.pendingInvites)")
            }
            
            Section("分享统计") {
                StatRow(label: "总分享数", value: "\(stats.totalShares)")
                StatRow(label: "总查看数", value: "\(stats.totalViews)")
                StatRow(label: "总评论数", value: "\(stats.totalComments)")
                StatRow(label: "查看率", value: String(format: "%.1f%%", stats.shareViewRate))
            }
            
            Section("时间线") {
                if let lastShared = stats.lastSharedAt {
                    StatRow(label: "最后分享", value: lastShared.formatted())
                }
            }
            
            Section("权限分布") {
                ForEach(SharingPermission.allCases, id: \.self) { permission in
                    let count = partners.filter { $0.myPermission == permission }.count
                    StatRow(label: permission.displayText, value: "\(count)")
                }
            }
        }
    }
}

// MARK: - 邀请表单

struct InviteSheet: View {
    @ObservedObject var service: DreamPartnerService
    @Binding var isPresented: Bool
    
    @State private var message = ""
    @State private var invite: PartnerInvite?
    @State private var showingQR = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let invite = invite {
                    // 已生成邀请
                    VStack(spacing: 16) {
                        Text("邀请已生成")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // 邀请码
                        VStack(spacing: 8) {
                            Text("邀请码")
                                .foregroundColor(.secondary)
                            Text(invite.code)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.purple)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // 有效期
                        HStack {
                            Image(systemName: "clock")
                            Text("有效期：\(invite.timeRemaining)")
                        }
                        .foregroundColor(.orange)
                        
                        // 分享按钮
                        Button("分享邀请码") {
                            // 分享到系统
                        }
                        .buttonStyle(.borderedProminent)
                        
                        // QR 码
                        Button("显示二维码") {
                            showingQR = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    // 生成邀请表单
                    VStack(spacing: 16) {
                        Text("创建伴侣邀请")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("发送邀请码给伴侣，TA 接受后就可以共享梦境了")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        TextField("给伴侣的留言 (可选)", text: $message, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("邀请码 72 小时后过期")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("生成邀请码") {
                            invite = service.createInvite(message: message.isEmpty ? nil : message)
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .navigationTitle("邀请伴侣")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - 添加伴侣表单

struct AddPartnerSheet: View {
    @Binding var name: String
    var service: DreamPartnerService
    @Binding var isPresented: Bool
    
    @StateObject private var permission = SharingPermission.viewOnly
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("伴侣名称", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Form {
                    Section("权限设置") {
                        Picker("访问权限", selection: $permission) {
                            ForEach(SharingPermission.allCases, id: \.self) { permission in
                                Text(permission.displayText).tag(permission)
                            }
                        }
                        
                        Text(permission.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button("发送邀请") {
                    Task {
                        try? await service.addPartner(name: name, permission: permission)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .disabled(name.isEmpty)
            }
            .navigationTitle("添加伴侣")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - 伴侣行组件

struct PartnerRow: View {
    var partner: DreamPartner
    var service: DreamPartnerService
    
    @State private var showingDetail = false
    @State private var showingPermissionSheet = false
    
    var body: some View {
        HStack {
            // 头像
            ZStack {
                Circle()
                    .fill(gradientForName(partner.partnerName))
                    .frame(width: 50, height: 50)
                
                if partner.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .offset(x: 18, y: -18)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(partner.partnerName)
                    .font(.headline)
                
                Text("权限：\(partner.myPermission.displayText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastActive = partner.lastActiveAt {
                    Text("最后活跃：\(lastActive.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: { showingPermissionSheet = true }) {
                    Image(systemName: "shield")
                }
                
                Button(action: { showingDetail = true }) {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDetail) {
            PartnerDetailView(partner: partner, service: service)
        }
        .sheet(isPresented: $showingPermissionSheet) {
            PermissionSheet(partner: partner, service: service)
        }
    }
    
    private func gradientForName(_ name: String) -> LinearGradient {
        let colors: [Color] = [.purple, .blue, .pink, .orange, .green]
        let index = name.hashValue % colors.count
        return LinearGradient(
            colors: [colors[index], colors[(index + 1) % colors.count]],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 待处理伴侣行

struct PendingPartnerRow: View {
    var partner: DreamPartner
    var service: DreamPartnerService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(partner.partnerName)
                    .font(.headline)
                Text("等待对方接受...")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Button("撤销") {
                Task {
                    try? await service.removePartner(partner)
                }
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - 伴侣详情视图

struct PartnerDetailView: View {
    var partner: DreamPartner
    var service: DreamPartnerService
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("信息") {
                    HStack {
                        Text("名称")
                        Spacer()
                        Text(partner.partnerName)
                    }
                    
                    HStack {
                        Text("状态")
                        Spacer()
                        Text(partner.status.displayText)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("连接时间")
                        Spacer()
                        if let connected = partner.connectedAt {
                            Text(connected.formatted())
                        }
                    }
                }
                
                Section("权限") {
                    HStack {
                        Text("对方权限")
                        Spacer()
                        Text(partner.myPermission.displayText)
                    }
                    
                    HStack {
                        Text("我的权限")
                        Spacer()
                        Text(partner.theirPermission.displayText)
                    }
                }
                
                Section("统计") {
                    HStack {
                        Text("分享数")
                        Spacer()
                        Text("\(partner.shareCount)")
                    }
                }
                
                Section("操作") {
                    Button(partner.isFavorite ? "取消收藏" : "收藏") {
                        Task {
                            try? await service.setFavorite(partner, isFavorite: !partner.isFavorite)
                            dismiss()
                        }
                    }
                    
                    Button("移除伴侣", role: .destructive) {
                        Task {
                            try? await service.removePartner(partner)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("伴侣详情")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 权限设置表单

struct PermissionSheet: View {
    var partner: DreamPartner
    var service: DreamPartnerService
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPermission: SharingPermission
    
    init(partner: DreamPartner, service: DreamPartnerService) {
        self.partner = partner
        self.service = service
        _selectedPermission = State(initialValue: partner.myPermission)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("访问权限") {
                    ForEach(SharingPermission.allCases, id: \.self) { permission in
                        Button {
                            selectedPermission = permission
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(permission.displayText)
                                        .foregroundColor(.primary)
                                    Text(permission.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedPermission == permission {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("权限设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            try? await service.updatePermission(for: partner, permission: selectedPermission)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 空状态视图

struct EmptyStateView: View {
    var icon: String
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 统计行组件

struct StatRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 统计项组件

struct StatItem: View {
    var icon: String
    var value: String
    var label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.purple)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    DreamPartnerView()
        .modelContainer(for: DreamPartner.self, inMemory: true)
}
