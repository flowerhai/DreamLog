//
//  LucidDreamTraining.swift
//  DreamLog
//
//  清醒梦训练功能 - 提供清醒梦技巧、训练计划和现实检查提醒
//

import SwiftUI

// MARK: - 数据结构

/// 清醒梦技巧类型
enum LucidTechniqueType: String, CaseIterable, Identifiable {
    case realityCheck = "reality_check"
    case milt = "milt"
    case wbtc = "wbtc"
    case ssild = "ssild"
    case dild = "dild"
    case meditation = "meditation"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .realityCheck: return "现实检查法"
        case .milt: return "MILD (记忆诱导)"
        case .wbtc: return "WBTB (睡中觉醒)"
        case .ssild: return "SSILD (感官切换)"
        case .dild: return "DILD (梦中知梦)"
        case .meditation: return "冥想训练"
        }
    }
    
    var iconName: String {
        switch self {
        case .realityCheck: return "hand.raised"
        case .milt: return "brain.head.profile"
        case .wbtc: return "alarm"
        case .ssild: return "eye"
        case .dild: return "moon.stars"
        case .meditation: return "figure.mind.and.body"
        }
    }
    
    var description: String {
        switch self {
        case .realityCheck: return "通过定期检查现实状态来培养知梦意识"
        case .milt: return "睡前重复意图记忆，提高梦中自我意识"
        case .wbtc: return "睡眠中途醒来后再入睡，增加清醒梦概率"
        case .ssild: return "快速切换注意力于不同感官，训练觉知"
        case .dild: return "在梦中意识到自己在做梦的技巧"
        case .meditation: return "通过冥想提升整体觉知能力"
        }
    }
    
    var difficulty: Int {
        switch self {
        case .realityCheck: return 1
        case .milt: return 2
        case .wbtc: return 2
        case .ssild: return 3
        case .dild: return 3
        case .meditation: return 2
        }
    }
    
    var estimatedDays: Int {
        switch self {
        case .realityCheck: return 7
        case .milt: return 14
        case .wbtc: return 10
        case .ssild: return 21
        case .dild: return 30
        case .meditation: return 14
        }
    }
}

/// 清醒梦技巧详情
struct LucidTechnique: Identifiable, Codable {
    let id: UUID
    let type: LucidTechniqueType
    var level: Int // 1-5 等级
    var totalPracticeDays: Int // 累计练习天数
    var successCount: Int // 成功次数
    var lastPracticeDate: Date?
    var notes: String
    
    init(type: LucidTechniqueType) {
        self.id = UUID()
        self.type = type
        self.level = 1
        self.totalPracticeDays = 0
        self.successCount = 0
        self.lastPracticeDate = nil
        self.notes = ""
    }
    
    var progressPercentage: Double {
        min(Double(level) / 5.0, 1.0)
    }
    
    var successRate: Double {
        guard totalPracticeDays > 0 else { return 0 }
        return Double(successCount) / Double(totalPracticeDays)
    }
}

/// 现实检查类型
enum RealityCheckType: String, CaseIterable, Identifiable {
    case nosePinch = "nose_pinch"
    case handLook = "hand_look"
    case textRead = "text_read"
    case lightSwitch = "light_switch"
    case mirrorCheck = "mirror_check"
    case fingerPush = "finger_push"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .nosePinch: return "捏鼻呼吸"
        case .handLook: return "观察手掌"
        case .textRead: return "阅读文字"
        case .lightSwitch: return "开关灯"
        case .mirrorCheck: return "照镜子"
        case .fingerPush: return "手指穿透"
        }
    }
    
    var instructions: String {
        switch self {
        case .nosePinch: return "捏住鼻子尝试呼吸，在梦中通常仍能呼吸"
        case .handLook: return "仔细观察手掌，梦中手掌可能变形或有异常"
        case .textRead: return "阅读文字后移开视线再看，梦中文字会变化"
        case .lightSwitch: return "开关灯，梦中灯光通常不会正常变化"
        case .mirrorCheck: return "照镜子，梦中镜像可能扭曲或不存在"
        case .fingerPush: return "尝试用手指穿透另一只手掌，梦中可能穿透"
        }
    }
}

/// 现实检查记录
struct RealityCheckEntry: Identifiable, Codable {
    let id: UUID
    let type: RealityCheckType
    let timestamp: Date
    let result: CheckResult
    var note: String
    
    enum CheckResult: String, Codable {
        case normal = "normal"
        case anomalous = "anomalous" // 异常结果，可能是在梦中
    }
}

/// 训练计划
struct TrainingPlan: Identifiable, Codable {
    let id: UUID
    let name: String
    let durationDays: Int
    let techniques: [LucidTechniqueType]
    let dailyReminders: [ReminderTime]
    var startDate: Date?
    var completedDays: Int
    var isActive: Bool
    
    struct ReminderTime: Codable, Hashable {
        let hour: Int
        let minute: Int
        
        var displayString: String {
            String(format: "%02d:%02d", hour, minute)
        }
    }
    
    var progressPercentage: Double {
        guard durationDays > 0 else { return 0 }
        return Double(completedDays) / Double(durationDays)
    }
    
    var daysRemaining: Int {
        max(durationDays - completedDays, 0)
    }
}

// MARK: - 训练服务

class LucidTrainingService: ObservableObject {
    static let shared = LucidTrainingService()
    
    @Published var techniques: [LucidTechnique] = []
    @Published var realityChecks: [RealityCheckEntry] = []
    @Published var activePlan: TrainingPlan?
    @Published var availablePlans: [TrainingPlan] = []
    
    private let userDefaultsKey = "lucid_training_data"
    
    init() {
        load()
        if techniques.isEmpty {
            initializeTechniques()
        }
        if availablePlans.isEmpty {
            initializePlans()
        }
    }
    
    func initializeTechniques() {
        techniques = LucidTechniqueType.allCases.map { LucidTechnique(type: $0) }
        save()
    }
    
    func initializePlans() {
        availablePlans = [
            TrainingPlan(
                id: UUID(),
                name: "新手入门",
                durationDays: 14,
                techniques: [.realityCheck, .milt],
                dailyReminders: [.init(hour: 10, minute: 0), .init(hour: 15, minute: 0), .init(hour: 21, minute: 0)],
                completedDays: 0,
                isActive: false
            ),
            TrainingPlan(
                id: UUID(),
                name: "进阶训练",
                durationDays: 30,
                techniques: [.realityCheck, .milt, .wbtc, .ssild],
                dailyReminders: [.init(hour: 9, minute: 0), .init(hour: 14, minute: 0), .init(hour: 18, minute: 0), .init(hour: 22, minute: 0)],
                completedDays: 0,
                isActive: false
            ),
            TrainingPlan(
                id: UUID(),
                name: "深度修行",
                durationDays: 60,
                techniques: LucidTechniqueType.allCases,
                dailyReminders: [.init(hour: 8, minute: 0), .init(hour: 12, minute: 0), .init(hour: 16, minute: 0), .init(hour: 20, minute: 0), .init(hour: 23, minute: 0)],
                completedDays: 0,
                isActive: false
            )
        ]
        save()
    }
    
    // MARK: - 技巧练习
    
    func recordPractice(techniqueType: LucidTechniqueType, success: Bool) {
        guard let index = techniques.firstIndex(where: { $0.type == techniqueType }) else { return }
        
        techniques[index].totalPracticeDays += 1
        techniques[index].lastPracticeDate = Date()
        if success {
            techniques[index].successCount += 1
        }
        
        // 升级逻辑
        let successRate = techniques[index].successRate
        if successRate > 0.7 && techniques[index].level < 5 {
            techniques[index].level += 1
        }
        
        save()
    }
    
    // MARK: - 现实检查
    
    func recordRealityCheck(type: RealityCheckType, result: RealityCheckEntry.CheckResult, note: String = "") {
        let entry = RealityCheckEntry(
            id: UUID(),
            type: type,
            timestamp: Date(),
            result: result,
            note: note
        )
        realityChecks.insert(entry, at: 0)
        
        // 保留最近 500 条记录
        if realityChecks.count > 500 {
            realityChecks.removeLast(realityChecks.count - 500)
        }
        
        save()
    }
    
    func getRealityCheckStats() -> (total: Int, anomalous: Int, rate: Double) {
        let total = realityChecks.count
        let anomalous = realityChecks.filter { $0.result == .anomalous }.count
        let rate = total > 0 ? Double(anomalous) / Double(total) : 0
        return (total, anomalous, rate)
    }
    
    // MARK: - 训练计划
    
    func startPlan(_ plan: TrainingPlan) {
        var newPlan = plan
        newPlan.startDate = Date()
        newPlan.isActive = true
        activePlan = newPlan
        
        if let index = availablePlans.firstIndex(where: { $0.id == plan.id }) {
            availablePlans[index] = newPlan
        }
        
        save()
    }
    
    func completeDay() {
        guard var plan = activePlan else { return }
        plan.completedDays += 1
        
        if plan.completedDays >= plan.durationDays {
            plan.isActive = false
        }
        
        activePlan = plan
        
        if let index = availablePlans.firstIndex(where: { $0.id == plan.id }) {
            availablePlans[index] = plan
        }
        
        save()
    }
    
    func stopPlan() {
        activePlan?.isActive = false
        save()
    }
    
    // MARK: - 持久化
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            struct StoredData: Codable {
                var techniques: [LucidTechnique]
                var realityChecks: [RealityCheckEntry]
                var activePlan: TrainingPlan?
                var availablePlans: [TrainingPlan]
            }
            
            let stored = try decoder.decode(StoredData.self, from: data)
            techniques = stored.techniques
            realityChecks = stored.realityChecks
            activePlan = stored.activePlan
            availablePlans = stored.availablePlans
        } catch {
            print("Failed to load lucid training data: \(error)")
        }
    }
    
    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            struct StoredData: Codable {
                var techniques: [LucidTechnique]
                var realityChecks: [RealityCheckEntry]
                var activePlan: TrainingPlan?
                var availablePlans: [TrainingPlan]
            }
            
            let stored = StoredData(
                techniques: techniques,
                realityChecks: realityChecks,
                activePlan: activePlan,
                availablePlans: availablePlans
            )
            
            let data = try encoder.encode(stored)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save lucid training data: \(error)")
        }
    }
}

// MARK: - 视图组件

struct LucidTrainingView: View {
    @StateObject private var service = LucidTrainingService.shared
    @State private var selectedTab = 0
    @State private var showingNewCheck = false
    @State private var selectedCheckType: RealityCheckType = .nosePinch
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部统计卡片
                if let plan = service.activePlan, plan.isActive {
                    ActivePlanCard(plan: plan, onCompleteDay: {
                        service.completeDay()
                    })
                }
                
                // 标签页选择
                Picker("训练", selection: $selectedTab) {
                    Text("技巧").tag(0)
                    Text("现实检查").tag(1)
                    Text("计划").tag(2)
                    Text("统计").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    TechniquesListView(service: service)
                        .tag(0)
                    
                    RealityChecksView(service: service, showingNewCheck: $showingNewCheck, selectedCheckType: $selectedCheckType)
                        .tag(1)
                    
                    TrainingPlansView(service: service)
                        .tag(2)
                    
                    TrainingStatsView(service: service)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("清醒梦训练")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewCheck = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingNewCheck) {
                NewRealityCheckSheet(
                    type: selectedCheckType,
                    onSave: { result, note in
                        service.recordRealityCheck(type: selectedCheckType, result: result, note: note)
                    }
                )
            }
        }
    }
}

// MARK: - 活跃计划卡片

struct ActivePlanCard: View {
    let plan: TrainingPlan
    let onCompleteDay: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.purple)
                Text("当前训练：\(plan.name)")
                    .font(.headline)
                Spacer()
                Text("\(plan.daysRemaining)天剩余")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: plan.progressPercentage)
                .progressViewStyle(.linear)
            
            HStack {
                Text("已完成 \(plan.completedDays)/\(plan.durationDays) 天")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onCompleteDay) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 技巧列表视图

struct TechniquesListView: View {
    @ObservedObject var service: LucidTrainingService
    @State private var selectedTechnique: LucidTechnique?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(service.techniques) { technique in
                    TechniqueCard(technique: technique, onTap: {
                        selectedTechnique = technique
                    })
                }
            }
            .padding()
        }
        .sheet(item: $selectedTechnique) { technique in
            TechniqueDetailSheet(technique: technique, service: service)
        }
    }
}

struct TechniqueCard: View {
    let technique: LucidTechnique
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: technique.type.iconName)
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading) {
                    Text(technique.type.displayName)
                        .font(.headline)
                    Text(technique.type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < technique.level ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(index < technique.level ? .yellow : .gray.opacity(0.3))
                        }
                    }
                    Text("练习 \(technique.totalPracticeDays) 次")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: technique.progressPercentage)
                .progressViewStyle(.linear)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
        .onTapGesture(perform: onTap)
    }
}

struct TechniqueDetailSheet: View {
    let technique: LucidTechnique
    @ObservedObject var service: LucidTrainingService
    @Environment(\.dismiss) var dismiss
    @State private var hadSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题和图标
                    HStack {
                        Image(systemName: technique.type.iconName)
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text(technique.type.displayName)
                                .font(.title2)
                                .bold()
                            Text("难度：\(String(repeating: "●", count: technique.type.difficulty))\(String(repeating: "○", count: 5 - technique.type.difficulty))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // 预计掌握时间
                    InfoCard(title: "预计掌握时间", value: "\(technique.type.estimatedDays) 天", icon: "clock")
                    
                    // 详细说明
                    DetailSection(title: "技巧说明", content: technique.type.description)
                    
                    // 练习指南
                    DetailSection(title: "练习指南", content: getPracticeGuide(technique.type))
                    
                    // 个人进度
                    VStack(alignment: .leading, spacing: 12) {
                        Text("个人进度")
                            .font(.headline)
                        
                        HStack {
                            Text("练习次数")
                            Spacer()
                            Text("\(technique.totalPracticeDays) 次")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("成功次数")
                            Spacer()
                            Text("\(technique.successCount) 次")
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("成功率")
                            Spacer()
                            Text("\(String(format: "%.1f", technique.successRate * 100))%")
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("等级")
                            Spacer()
                            Text("Lv.\(technique.level)")
                                .foregroundColor(.purple)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 记录练习
                    VStack(alignment: .leading, spacing: 12) {
                        Text("记录本次练习")
                            .font(.headline)
                        
                        Toggle("本次练习成功知梦", isOn: $hadSuccess)
                        
                        Button(action: {
                            service.recordPractice(techniqueType: technique.type, success: hadSuccess)
                            dismiss()
                        }) {
                            Text("保存记录")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 备注
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注")
                            .font(.headline)
                        TextEditor(text: .constant(technique.notes))
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("技巧详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    func getPracticeGuide(_ type: LucidTechniqueType) -> String {
        switch type {
        case .realityCheck:
            return "1. 每天设置 5-10 次现实检查提醒\n2. 每次检查时认真质疑当前状态\n3. 问自己：'我现在在做梦吗？'\n4. 观察周围环境是否有异常\n5. 坚持至少 2 周形成习惯"
        case .milt:
            return "1. 睡前回顾最近的梦境\n2. 识别梦境中的异常信号\n3. 重复意图：'下次做梦时，我会记得自己在做梦'\n4. 想象自己在梦中知梦的场景\n5. 保持放松入睡"
        case .wbtc:
            return "1. 设置闹钟在睡后 4-6 小时响起\n2. 醒来后保持清醒 20-60 分钟\n3. 阅读关于清醒梦的资料\n4. 进行现实检查练习\n5. 带着知梦意图重新入睡"
        case .ssild:
            return "1. 躺下后快速切换注意力\n2. 关注视觉（闭眼看到的图像）3-5 秒\n3. 关注听觉（周围声音）3-5 秒\n4. 关注身体感觉 3-5 秒\n5. 循环 4-6 次后自然入睡"
        case .dild:
            return "1. 培养批判性思维习惯\n2. 白天经常问'我在做梦吗'\n3. 寻找梦境信号（异常事件）\n4. 在梦中保持冷静\n5. 稳定梦境后探索"
        case .meditation:
            return "1. 每天冥想 10-20 分钟\n2. 专注于呼吸觉知\n3. 培养元认知能力\n4. 练习观察念头而不评判\n5. 将觉知带入睡眠"
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

// MARK: - 现实检查视图

struct RealityChecksView: View {
    @ObservedObject var service: LucidTrainingService
    @Binding var showingNewCheck: Bool
    @Binding var selectedCheckType: RealityCheckType
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 快速检查按钮
                HStack(spacing: 12) {
                    ForEach(RealityCheckType.allCases.prefix(4)) { type in
                        Button(action: {
                            selectedCheckType = type
                            showingNewCheck = true
                        }) {
                            VStack {
                                Image(systemName: getCheckIcon(type))
                                    .font(.title2)
                                Text(type.displayName)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // 历史记录
                Text("历史记录")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                
                ForEach(service.realityChecks.prefix(20)) { check in
                    RealityCheckRow(entry: check)
                }
            }
            .padding()
        }
    }
    
    func getCheckIcon(_ type: RealityCheckType) -> String {
        switch type {
        case .nosePinch: return "nose"
        case .handLook: return "hand.raised"
        case .textRead: return "text.alignleft"
        case .lightSwitch: return "lightbulb"
        case .mirrorCheck: return "reflection"
        case .fingerPush: return "hand.point.up.left"
        }
    }
}

struct RealityCheckRow: View {
    let entry: RealityCheckEntry
    
    var body: some View {
        HStack {
            Image(systemName: getIcon(entry.type))
                .foregroundColor(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(entry.type.displayName)
                    .font(.subheadline)
                Text(formatDate(entry.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: entry.result == .anomalous ? "exclamationmark.triangle" : "checkmark.circle")
                    .foregroundColor(entry.result == .anomalous ? .orange : .green)
                if !entry.note.isEmpty {
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    func getIcon(_ type: RealityCheckType) -> String {
        switch type {
        case .nosePinch: return "nose.fill"
        case .handLook: return "hand.raised.fill"
        case .textRead: return "doc.text.fill"
        case .lightSwitch: return "lightbulb.fill"
        case .mirrorCheck: return "square.split.diagonal"
        case .fingerPush: return "hand.point.left.fill"
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 新建现实检查表单

struct NewRealityCheckSheet: View {
    let type: RealityCheckType
    let onSave: (RealityCheckEntry.CheckResult, String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var result: RealityCheckEntry.CheckResult = .normal
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 说明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("检查方法")
                            .font(.headline)
                        Text(type.instructions)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 结果选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("检查结果")
                            .font(.headline)
                        
                        Button(action: { result = .normal }) {
                            HStack {
                                Image(systemName: result == .normal ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(result == .normal ? .green : .gray)
                                Text("正常 - 现实符合预期")
                                Spacer()
                            }
                            .padding()
                            .background(result == .normal ? Color.green.opacity(0.1) : Color.clear)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { result = .anomalous }) {
                            HStack {
                                Image(systemName: result == .anomalous ? "exclamationmark.circle.fill" : "circle")
                                    .foregroundColor(result == .anomalous ? .orange : .gray)
                                Text("异常 - 可能在做梦中！")
                                Spacer()
                            }
                            .padding()
                            .background(result == .anomalous ? Color.orange.opacity(0.1) : Color.clear)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 备注
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注（可选）")
                            .font(.headline)
                        TextEditor(text: $note)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        onSave(result, note)
                        dismiss()
                    }) {
                        Text("保存记录")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("记录现实检查")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 训练计划视图

struct TrainingPlansView: View {
    @ObservedObject var service: LucidTrainingService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(service.availablePlans) { plan in
                    PlanCard(plan: plan, service: service)
                }
            }
            .padding()
        }
    }
}

struct PlanCard: View {
    let plan: TrainingPlan
    @ObservedObject var service: LucidTrainingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: plan.isActive ? "target" : "target")
                    .foregroundColor(plan.isActive ? .green : .purple)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(plan.name)
                        .font(.headline)
                    Text("\(plan.durationDays) 天训练计划")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if plan.isActive {
                    Text("进行中")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
            
            // 包含的技巧
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(plan.techniques, id: \.self) { technique in
                        Text(technique.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                }
            }
            
            // 提醒时间
            HStack {
                Image(systemName: "alarm")
                    .foregroundColor(.secondary)
                Text("每日提醒：\(plan.dailyReminders.map { $0.displayString }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if plan.isActive {
                ProgressView(value: plan.progressPercentage)
                    .progressViewStyle(.linear)
                
                HStack {
                    Text("第 \(plan.completedDays + 1)/\(plan.durationDays) 天")
                        .font(.caption)
                    Spacer()
                    Button(action: { service.stopPlan() }) {
                        Text("停止训练")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            } else {
                Button(action: { service.startPlan(plan) }) {
                    Text("开始训练")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(plan.isActive ? Color.gray : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(plan.isActive)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - 训练统计视图

struct TrainingStatsView: View {
    @ObservedObject var service: LucidTrainingService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 概览统计
                HStack(spacing: 16) {
                    StatCard(title: "总练习次数", value: "\(service.techniques.reduce(0) { $0 + $1.totalPracticeDays })", icon: "repeat", color: .purple)
                    StatCard(title: "总成功次数", value: "\(service.techniques.reduce(0) { $0 + $1.successCount })", icon: "checkmark.star", color: .green)
                }
                
                HStack(spacing: 16) {
                    let stats = service.getRealityCheckStats()
                    StatCard(title: "现实检查", value: "\(stats.total)", icon: "hand.raised", color: .blue)
                    StatCard(title: "异常发现", value: "\(stats.anomalous)", icon: "exclamationmark.triangle", color: .orange)
                }
                
                // 技巧进度
                VStack(alignment: .leading, spacing: 12) {
                    Text("技巧掌握度")
                        .font(.headline)
                    
                    ForEach(service.techniques) { technique in
                        HStack {
                            Image(systemName: technique.type.iconName)
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text(technique.type.displayName)
                                .font(.subheadline)
                            Spacer()
                            Text("Lv.\(technique.level)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        ProgressView(value: technique.progressPercentage)
                            .progressViewStyle(.linear)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                
                // 最近检查
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近现实检查")
                        .font(.headline)
                    
                    if service.realityChecks.isEmpty {
                        Text("暂无记录")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(service.realityChecks.prefix(10)) { check in
                            HStack {
                                Text(check.type.displayName)
                                    .font(.subheadline)
                                Spacer()
                                Text(formatDate(check.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: check.result == .anomalous ? "exclamationmark.triangle" : "checkmark.circle")
                                    .foregroundColor(check.result == .anomalous ? .orange : .green)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
            }
            .padding()
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - 预览

#Preview {
    LucidTrainingView()
}
