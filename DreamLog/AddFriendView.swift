//
//  AddFriendView.swift
//  DreamLog
//
//  添加好友页面
//

import SwiftUI

struct AddFriendView: View {
    @ObservedObject var friendService: FriendService
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var searchResults: [Friend] = []
    @State private var sendMessage = ""
    @State private var showingMessageSheet = false
    @State private var selectedUser: Friend?
    @State private var showingQRScanner = false
    @State private var myQRCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchSection
                
                Divider()
                
                // 搜索结果
                if isSearching {
                    loadingOrResultsView
                } else {
                    suggestionsView
                }
            }
            .navigationTitle("添加好友")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingQRScanner = true }) {
                        Image(systemName: "qrcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showingMessageSheet) {
                if let user = selectedUser {
                    sendRequestMessageView(user: user)
                }
            }
            .sheet(isPresented: $showingQRScanner) {
                QRScannerView()
            }
        }
    }
    
    // MARK: - 搜索区域
    private var searchSection: some View {
        VStack(spacing: 16) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索用户名", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onChange(of: searchQuery) { _, newValue in
                        Task {
                            await performSearch(newValue)
                        }
                    }
                
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 我的二维码
            HStack {
                Image(systemName: "qrcode")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading) {
                    Text("我的二维码")
                        .font(.headline)
                    Text("分享给好友，互相关注")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("查看") {
                    // 显示二维码
                }
                .foregroundColor(.accentColor)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
    }
    
    // MARK: - 加载或结果
    private var loadingOrResultsView: some View {
        Group {
            if searchResults.isEmpty && !searchQuery.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("正在搜索...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("未找到用户")
                        .font(.headline)
                    Text("试试搜索其他关键词")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section("搜索结果") {
                        ForEach(searchResults) { user in
                            SearchResultRowView(
                                user: user,
                                isFriend: friendService.friends.contains { $0.userId == user.userId }
                            ) {
                                selectedUser = user
                                showingMessageSheet = true
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    // MARK: - 推荐用户
    private var suggestionsView: some View {
        List {
            Section("推荐好友") {
                ForEach(generateSuggestions()) { user in
                    SearchResultRowView(
                        user: user,
                        isFriend: false
                    ) {
                        selectedUser = user
                        showingMessageSheet = true
                    }
                }
            }
            
            Section("邀请好友") {
                HStack {
                    Image(systemName: "envelope")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading) {
                        Text("邀请微信好友")
                            .font(.headline)
                        Text("分享你的 DreamLog 主页")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("邀请") {
                        // 分享
                    }
                    .foregroundColor(.accentColor)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - 发送请求消息
    private func sendRequestMessageView(user: Friend) -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // 用户信息
                VStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(user.username.prefix(1)))
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        )
                    
                    Text(user.username)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("发送好友请求后，对方可以在好友请求中查看")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 消息输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("打招呼（可选）")
                        .font(.headline)
                    
                    TextEditor(text: $sendMessage)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Text("\(sendMessage.count)/100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 发送按钮
                Button(action: {
                    Task {
                        await friendService.sendFriendRequest(to: user.userId, message: sendMessage)
                        dismiss()
                    }
                }) {
                    Text("发送好友请求")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("添加好友")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { showingMessageSheet = false }
                }
            }
        }
    }
    
    // MARK: - 搜索
    private func performSearch(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        searchResults = await friendService.searchFriends(query: query)
    }
    
    // MARK: - 生成推荐
    private func generateSuggestions() -> [Friend] {
        [
            Friend(userId: "sug_001", username: "梦境记录者", dreamCount: 45, bio: "每天记录梦境"),
            Friend(userId: "sug_002", username: "清醒梦练习生", dreamCount: 23, bio: "学习清醒梦中"),
            Friend(userId: "sug_003", username: "解梦师", dreamCount: 189, bio: "心理学背景，擅长解梦"),
            Friend(userId: "sug_004", username: "梦境艺术家", dreamCount: 67, bio: "把梦画出来")
        ]
    }
}

// MARK: - 搜索结果行
struct SearchResultRowView: View {
    let user: Friend
    let isFriend: Bool
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.username.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Label("\(user.dreamCount) 个梦境", systemImage: "moon.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isFriend {
                Text("已添加")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
            } else {
                Button(action: onAdd) {
                    Text("添加")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - QR 扫描视图
struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // 模拟二维码扫描界面
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 250, height: 250)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .frame(width: 250, height: 250)
                    
                    Image(systemName: "qrcode")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
                
                Text("将二维码放入框内，即可自动扫描")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 从相册选择
                Button(action: {
                    // 从相册选择二维码
                }) {
                    Label("从相册选择二维码", systemImage: "photo.on.rectangle")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("扫描二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddFriendView(friendService: FriendService())
}
