//
//  CreateTimeCapsuleView.swift
//  DreamLog - Phase 27: 梦境时间胶囊
//
//  创建时间胶囊界面
//

import SwiftUI
import SwiftData

struct CreateTimeCapsuleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var service = DreamTimeCapsuleService.shared
    
    @State private var config = TimeCapsuleConfig()
    @State private var showingDreamPicker = false
    @State private var showingDatePicker = false
    @State private var showingFriendPicker = false
    @State private var errorMessage: String?
    @State private var isCreating = false
    
    var onDismiss: () -> Void
    
    var canSubmit: Bool {
        !config.title.isEmpty &&
        !config.selectedDreamIds.isEmpty &&
        config.unlockDate > Date()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    TextField("胶囊标题", text: $config.title)
                        .textContentType(.name)
                    
                    TextEditor(text: $config.message)
                        .frame(minHeight: 100)
                        .overlay(
                            Text(config.message.isEmpty ? "写给未来的话..." : "")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .opacity(config.message.isEmpty ? 1 : 0)
                        )
                    
                    Picker("胶囊类型", selection: $config.capsuleType) {
                        ForEach(TimeCapsuleType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                // 选择梦境
                Section("选择梦境") {
                    Button(action: { showingDreamPicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                            Text("选择梦境")
                            Spacer()
                            Text("\(config.selectedDreamIds.count) 个")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !config.selectedDreamIds.isEmpty {
                        ForEach(config.selectedDreamIds, id: \.self) { dreamId in
                            DreamIdRow(dreamId: dreamId, onRemove: {
                                config.selectedDreamIds.removeAll { $0 == dreamId }
                            })
                        }
                    }
                }
                
                // 解锁时间
                Section("解锁时间") {
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            Text("解锁日期")
                            Spacer()
                            Text(config.unlockDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if config.unlockDate > Date() {
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: config.unlockDate).day ?? 0
                        HStack {
                            Image(systemName: "hourglass")
                                .foregroundColor(.secondary)
                            Text("\(days) 天后解锁")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 快捷日期选择
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            QuickDateButton(title: "7 天", days: 7, isSelected: isDaysAway(7)) {
                                selectDays(7)
                            }
                            
                            QuickDateButton(title: "1 个月", days: 30, isSelected: isDaysAway(30)) {
                                selectDays(30)
                            }
                            
                            QuickDateButton(title: "3 个月", days: 90, isSelected: isDaysAway(90)) {
                                selectDays(90)
                            }
                            
                            QuickDateButton(title: "6 个月", days: 180, isSelected: isDaysAway(180)) {
                                selectDays(180)
                            }
                            
                            QuickDateButton(title: "1 年", days: 365, isSelected: isDaysAway(365)) {
                                selectDays(365)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 通知设置
                Section("通知") {
                    Toggle("解锁时提醒我", isOn: $config.notifyOnUnlock)
                }
                
                // 分享设置（仅当类型为分享给朋友时显示）
                if config.capsuleType == .shareWithFriend {
                    Section("分享给朋友") {
                        Button(action: { showingFriendPicker = true }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(.orange)
                                Text("选择好友")
                                Spacer()
                                if let friendId = config.shareWithFriendId {
                                    Text("已选择")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if config.shareWithFriendId != nil {
                            TextField("分享留言", text: Binding(
                                get: { config.shareMessage ?? "" },
                                set: { config.shareMessage = $0 }
                            ))
                            .textContentType(.message)
                        }
                    }
                }
                
                // 标签
                Section("标签") {
                    TextField("添加标签（用逗号分隔）", text: $tagsText)
                        .textContentType(nil)
                }
            }
            .navigationTitle("创建时间胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task { await createCapsule() }
                    }
                    .disabled(!canSubmit || isCreating)
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingDreamPicker) {
                DreamTimeCapsulePickerView(selectedDreamIds: $config.selectedDreamIds)
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $config.unlockDate)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private var tagsText: String {
        get { config.tags.joined(separator: ", ") }
        set { config.tags = newValue.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
    }
    
    private func isDaysAway(_ days: Int) -> Bool {
        let targetDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        let configDate = Calendar.current.startOfDay(for: config.unlockDate)
        let targetDateStart = Calendar.current.startOfDay(for: targetDate)
        return abs(configDate.timeIntervalSince(targetDateStart)) < 86400
    }
    
    private func selectDays(_ days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) {
            config.unlockDate = newDate
        }
    }
    
    private func createCapsule() async {
        isCreating = true
        
        do {
            _ = try await service.createCapsule(config: config)
            dismiss()
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isCreating = false
    }
}

// MARK: - 子组件

struct DreamIdRow: View {
    let dreamId: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "moon.fill")
                .foregroundColor(.purple)
            Text("梦境 \(dreamId.prefix(8))")
                .font(.caption)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

struct QuickDateButton: View {
    let title: String
    let days: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct DreamTimeCapsulePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDreamIds: [String]
    @Query private var dreams: [Dream]
    @State private var searchText = ""
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreams
        }
        return dreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredDreams) { dream in
                    DreamSelectionRow(
                        dream: dream,
                        isSelected: selectedDreamIds.contains(dream.id.uuidString),
                        onToggle: {
                            if selectedDreamIds.contains(dream.id.uuidString) {
                                selectedDreamIds.removeAll { $0 == dream.id.uuidString }
                            } else {
                                selectedDreamIds.append(dream.id.uuidString)
                            }
                        }
                    )
                }
            }
            .navigationTitle("选择梦境")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索梦境")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成 (\(selectedDreamIds.count))") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DreamSelectionRow: View {
    let dream: Dream
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .orange : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dream.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(dream.content.prefix(50))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(dream.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct DatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var tempDate: Date
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                DatePicker(
                    "选择解锁日期",
                    selection: $tempDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Text("时间胶囊将在选定日期自动解锁")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("设置解锁日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        selectedDate = tempDate
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateTimeCapsuleView(onDismiss: {})
        .modelContainer(for: [DreamTimeCapsule.self, Dream.self], inMemory: true)
}
