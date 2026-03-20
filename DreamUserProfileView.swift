//
//  DreamUserProfileView.swift
//  DreamLog - 用户档案 UI
//
//  Phase 73: 梦境协作功能增强
//  创建时间：2026-03-20
//

import SwiftUI
import SwiftData

// MARK: - 用户档案视图

struct DreamUserProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamUserProfile.createdAt) private var users: [DreamUserProfile]
    
    let userId: String?
    @State private var isEditing = false
    @State private var showSettings = false
    
    var currentUserId: String? {
        userId ?? UserDefaults.standard.string(forKey: "dreamlog_current_user_id")
    }
    
    var currentUser: DreamUserProfile? {
        guard let id = currentUserId else { return nil }
        return users.first { $0.id == id }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部信息
                    profileHeader
                    
                    // 统计卡片
                    statsCards
                    
                    // 专长领域
                    if let user = currentUser, !user.specialties.isEmpty {
                        specialtiesSection
                    }
                    
                    // 成就徽章
                    badgesSection
                    
                    // 个人简介
                    if let user = currentUser, let bio = user.bio {
                        bioSection(bio: bio)
                    }
                    
                    // 社交关系
                    socialSection
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(currentUser?.displayName ?? "我的档案")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if userId == nil {
                        Button(action: { isEditing.toggle() }) {
                            Image(systemName: "pencil.circle")
                                .font(.title2)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if userId == nil {
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                EditProfileView(user: currentUser)
            }
            .sheet(isPresented: $showSettings) {
                UserSettingsView()
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                if let avatar = currentUser?.avatar, !avatar.isEmpty {
                    Image(uiImage: loadImage(from: avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Text(currentUser?.displayName.first.map(String.init) ?? "U")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // 用户名和显示名
            VStack(spacing: 4) {
                Text(currentUser?.displayName ?? "用户")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("@\(currentUser?.username ?? "username")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 活跃度等级
            if let stats = currentUser?.stats {
                HStack(spacing: 4) {
                    Text(stats.activityLevel.icon)
                    Text(stats.activityLevel.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: stats.activityLevel.color)?.opacity(0.15))
                .cornerRadius(16)
            }
            
            // 影响力评分
            if let stats = currentUser?.stats {
                HStack(spacing: 20) {
                    StatItem(icon: "🏆", value: "\(stats.influenceScore)", label: "影响力")
                    StatItem(icon: "💡", value: "\(stats.interpretationsAdded)", label: "解读")
                    StatItem(icon: "👥", value: "\(stats.followersCount)", label: "粉丝")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Stats Cards
    
    private var statsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "📝",
                title: "创建会话",
                value: "\(currentUser?.stats.sessionsCreated ?? 0)",
                color: .blue
            )
            
            StatCard(
                icon: "💬",
                title: "发布评论",
                value: "\(currentUser?.stats.commentsPosted ?? 0)",
                color: .green
            )
            
            StatCard(
                icon: "❤️",
                title: "获得点赞",
                value: "\(currentUser?.stats.likesReceived ?? 0)",
                color: .red
            )
            
            StatCard(
                icon: "🔥",
                title: "连续活跃",
                value: "\(currentUser?.stats.currentStreak ?? 0) 天",
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Specialties Section
    
    private var specialtiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("专长领域")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(currentUser?.specialties ?? [], id: \.self) { specialty in
                    SpecialtyChip(specialty: specialty)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Badges Section
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就徽章")
                .font(.headline)
            
            if let badges = currentUser?.badges, !badges.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                    ForEach(badges, id: \.id) { badge in
                        VStack(spacing: 4) {
                            Text(badge.icon)
                                .font(.system(size: 32))
                            Text(badge.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("暂无徽章，继续参与协作解锁更多成就！")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Bio Section
    
    private func bioSection(bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("个人简介")
                .font(.headline)
            
            Text(bio)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Social Section
    
    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("社交关系")
                .font(.headline)
            
            HStack(spacing: 20) {
                SocialStatItem(
                    icon: "👥",
                    title: "关注",
                    count: currentUser?.stats.followingCount ?? 0
                )
                
                Divider()
                    .frame(height: 40)
                
                SocialStatItem(
                    icon: "🌟",
                    title: "粉丝",
                    count: currentUser?.stats.followersCount ?? 0
                )
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
    private func loadImage(from string: String) -> UIImage {
        // 尝试从 URL 加载
        if string.hasPrefix("http"), let url = URL(string: string),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        
        // 尝试从本地数据加载
        if let data = Data(base64Encoded: string),
           let image = UIImage(data: data) {
            return image
        }
        
        // 默认返回系统图标
        return UIImage(systemName: "person.fill") ?? UIImage()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title3)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct SpecialtyChip: View {
    let specialty: DreamSpecialty
    
    var body: some View {
        HStack(spacing: 4) {
            Text(specialty.icon)
            Text(specialty.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct SocialStatItem: View {
    let icon: String
    let title: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(icon)
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let user: DreamUserProfile?
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedSpecialties: [DreamSpecialty] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("显示名称", text: $displayName)
                    TextField("个人简介", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("专长领域")) {
                    ForEach(DreamSpecialty.allCases, id: \.self) { specialty in
                        Button(action: {
                            if selectedSpecialties.contains(specialty) {
                                selectedSpecialties.removeAll { $0 == specialty }
                            } else {
                                selectedSpecialties.append(specialty)
                            }
                        }) {
                            HStack {
                                Text(specialty.icon)
                                VStack(alignment: .leading) {
                                    Text(specialty.rawValue)
                                        .font(.body)
                                    Text(specialty.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedSpecialties.contains(specialty) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("编辑档案")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                displayName = user?.displayName ?? ""
                bio = user?.bio ?? ""
                selectedSpecialties = user?.specialties ?? []
            }
        }
    }
    
    private func saveChanges() {
        guard let user = user else { return }
        
        // 更新用户档案
        user.displayName = displayName
        user.bio = bio.isEmpty ? nil : bio
        user.specialties = selectedSpecialties
        user.updatedAt = Date()
        
        // 保存更改
        do {
            try user.modelContext?.save()
            print("✅ 用户档案已保存")
        } catch {
            print("❌ 保存失败：\(error)")
        }
    }
}

// MARK: - User Settings View

struct UserSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enableNotifications = true
    @State private var showOnlineStatus = true
    @State private var theme: UserTheme = .system
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("通知")) {
                    Toggle("启用通知", isOn: $enableNotifications)
                }
                
                Section(header: Text("隐私")) {
                    Toggle("显示在线状态", isOn: $showOnlineStatus)
                }
                
                Section(header: Text("外观")) {
                    Picker("主题", selection: $theme) {
                        ForEach(UserTheme.allCases, id: \.self) { theme in
                            Text("\(theme.icon) \(theme.rawValue)").tag(theme)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DreamUserProfileView()
}
