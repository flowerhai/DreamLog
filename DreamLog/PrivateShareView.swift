//
//  PrivateShareView.swift
//  DreamLog
//
//  私密分享梦境给好友
//

import SwiftUI

struct PrivateShareView: View {
    let dream: Dream
    @ObservedObject var friendService: FriendService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriends: Set<String> = []
    @State private var selectedCircles: Set<UUID> = []
    @State private var shareTab: ShareTab = .friends
    @State private var shareMessage = ""
    @State private var isSharing = false
    @State private var showSuccess = false
    
    enum ShareTab: String, CaseIterable {
        case friends = "好友"
        case circles = "圈子"
        
        var icon: String {
            switch self {
            case .friends: return "person.2"
            case .circles: return "person.3"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 梦境预览
                dreamPreviewSection
                
                Divider()
                
                // 标签选择器
                segmentPicker
                
                Divider()
                
                // 选择列表
                selectionList
                
                Spacer()
                
                // 消息输入
                if !selectedFriends.isEmpty || !selectedCircles.isEmpty {
                    messageInputSection
                }
                
                // 分享按钮
                shareButtonSection
            }
            .navigationTitle("分享给好友")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("分享成功", isPresented: $showSuccess) {
                Button("完成") { dismiss() }
            } message: {
                Text("梦境已分享给 \(selectedFriends.count) 位好友")
            }
        }
        .task {
            await friendService.fetchFriendDreams()
        }
    }
    
    // MARK: - 梦境预览
    private var dreamPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分享预览")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                // 梦境卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text(dream.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(dream.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    HStack(spacing: 8) {
                        if dream.isLucid {
                            Label("清醒梦", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        
                        ForEach(dream.emotions.prefix(3), id: \.self) { emotion in
                            Text(emotion.icon)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                if let aiImage = dream.aiImageUrl {
                    AsyncImage(url: URL(string: aiImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
    }
    
    // MARK: - 分段选择器
    private var segmentPicker: some View {
        Picker("标签", selection: $shareTab) {
            ForEach(ShareTab.allCases, id: \.self) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    // MARK: - 选择列表
    @ViewBuilder
    private var selectionList: some View {
        switch shareTab {
        case .friends:
            friendsListView
        case .circles:
            circlesListView
        }
    }
    
    // MARK: - 好友列表
    private var friendsListView: some View {
        List {
            // 快速选择
            Section {
                HStack(spacing: 12) {
                    QuickSelectButton(
                        title: "全选",
                        icon: "checkmark.seal.fill",
                        isSelected: selectedFriends.count == friendService.friends.count
                    ) {
                        if selectedFriends.count == friendService.friends.count {
                            selectedFriends.removeAll()
                        } else {
                            selectedFriends = Set(friendService.friends.map { $0.userId })
                        }
                    }
                    
                    QuickSelectButton(
                        title: "特别关心",
                        icon: "star.fill",
                        isSelected: false
                    ) {
                        let favoriteIds = friendService.friends
                            .filter { $0.isFavorite }
                            .map { $0.userId }
                        selectedFriends.formUnion(favoriteIds)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 好友列表
            Section("选择好友 (\(selectedFriends.count))") {
                // 特别关心的好友
                if friendService.friends.contains(where: { $0.isFavorite }) {
                    SubtitleRow(title: "特别关心 ⭐")
                    
                    ForEach(friendService.friends.filter { $0.isFavorite }) { friend in
                        FriendSelectionRow(
                            friend: friend,
                            isSelected: selectedFriends.contains(friend.userId)
                        ) {
                            if selectedFriends.contains(friend.userId) {
                                selectedFriends.remove(friend.userId)
                            } else {
                                selectedFriends.insert(friend.userId)
                            }
                        }
                    }
                }
                
                // 其他好友
                SubtitleRow(title: "好友")
                
                ForEach(friendService.friends.filter { !$0.isFavorite }) { friend in
                    FriendSelectionRow(
                        friend: friend,
                        isSelected: selectedFriends.contains(friend.userId)
                    ) {
                        if selectedFriends.contains(friend.userId) {
                            selectedFriends.remove(friend.userId)
                        } else {
                            selectedFriends.insert(friend.userId)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - 梦境圈列表
    private var circlesListView: some View {
        List {
            Section("选择梦境圈") {
                if friendService.dreamCircles.isEmpty {
                    Text("还没有创建梦境圈")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(friendService.dreamCircles) { circle in
                        CircleSelectionRow(
                            circle: circle,
                            isSelected: selectedCircles.contains(circle.id)
                        ) {
                            if selectedCircles.contains(circle.id) {
                                selectedCircles.remove(circle.id)
                            } else {
                                selectedCircles.insert(circle.id)
                            }
                        }
                    }
                }
            }
            
            Section {
                NavigationLink(destination: CreateCircleView(friendService: friendService)) {
                    Label("创建新圈子", systemImage: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - 消息输入
    private var messageInputSection: some View {
        VStack(spacing: 8) {
            HStack {
                TextEditor(text: $shareMessage)
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            HStack {
                Text("\(shareMessage.count)/200")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        shareMessage += " 🌙"
                    }) {
                        Text("🌙")
                            .font(.body)
                    }
                    
                    Button(action: {
                        shareMessage += " ✨"
                    }) {
                        Text("✨")
                            .font(.body)
                    }
                    
                    Button(action: {
                        shareMessage += " 💭"
                    }) {
                        Text("💭")
                            .font(.body)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 分享按钮
    private var shareButtonSection: some View {
        VStack(spacing: 12) {
            // 可见性说明
            HStack {
                Image(systemName: shareTab == .friends ? "person.2.fill" : "person.3.fill")
                    .foregroundColor(.secondary)
                
                Text(shareTab == .friends
                     ? "仅选中的好友可见"
                     : "仅圈子成员可见")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // 分享按钮
            Button(action: performShare) {
                HStack {
                    if isSharing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    
                    Text(isSharing ? "分享中..." : "分享梦境")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedFriends.isEmpty && selectedCircles.isEmpty
                           ? Color.gray
                           : Color.accentColor)
                .cornerRadius(12)
            }
            .disabled(isSharing || (selectedFriends.isEmpty && selectedCircles.isEmpty))
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 执行分享
    private func performShare() async {
        isSharing = true
        
        // 模拟分享延迟
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 分享给好友
        for friendId in selectedFriends {
            // 实际应用中调用 API
            print("分享给好友：\(friendId)")
        }
        
        // 分享到圈子
        for circleId in selectedCircles {
            if let circle = friendService.dreamCircles.first(where: { $0.id == circleId }) {
                await friendService.shareToCircle(dream, circle: circle)
            }
        }
        
        isSharing = false
        showSuccess = true
    }
}

// MARK: - 快速选择按钮
struct QuickSelectButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 副标题行
struct SubtitleRow: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - 好友选择行
struct FriendSelectionRow: View {
    let friend: Friend
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(friend.username.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(friend.username)
                        .font(.headline)
                    
                    if friend.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("\(friend.dreamCount) 个梦境")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .accentColor : .gray)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - 圈子选择行
struct CircleSelectionRow: View {
    let circle: DreamCircle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(circle.name)
                    .font(.headline)
                
                Text("\(circle.members.count) 位成员 · \(circle.sharedDreams.count) 个梦境")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .accentColor : .gray)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - 创建梦境圈视图
struct CreateCircleView: View {
    @ObservedObject var friendService: FriendService
    @Environment(\.dismiss) private var dismiss
    @State private var circleName = ""
    @State private var circleDescription = ""
    @State private var selectedMembers: Set<String> = []
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("圈子信息") {
                    TextField("圈子名称", text: $circleName)
                    
                    TextField("圈子描述（可选）", text: $circleDescription)
                }
                
                Section("选择成员") {
                    ForEach(friendService.friends) { friend in
                        HStack {
                            Text(friend.username)
                            Spacer()
                            if selectedMembers.contains(friend.userId) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedMembers.contains(friend.userId) {
                                selectedMembers.remove(friend.userId)
                            } else {
                                selectedMembers.insert(friend.userId)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: createCircle) {
                        HStack {
                            if isCreating {
                                ProgressView()
                            }
                            Text("创建圈子")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(circleName.isEmpty || selectedMembers.isEmpty || isCreating)
                }
            }
            .navigationTitle("创建梦境圈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
    
    private func createCircle() async {
        isCreating = true
        
        let members = friendService.friends.filter { selectedMembers.contains($0.userId) }
        _ = await friendService.createCircle(
            name: circleName,
            description: circleDescription,
            members: members
        )
        
        isCreating = false
        dismiss()
    }
}

#Preview {
    PrivateShareView(
        dream: Dream(
            title: "测试梦境",
            content: "这是一个测试梦境内容",
            tags: ["测试"],
            emotions: [.happy]
        ),
        friendService: FriendService()
    )
}
