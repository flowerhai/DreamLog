//
//  DreamComparisonView.swift
//  DreamLog
//
//  Dream Comparison Feature - UI Interface
//  Phase 77: Dream Comparison Tool
//

import SwiftUI
import SwiftData

// MARK: - Main Comparison View

struct DreamComparisonView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDreams: [Dream] = []
    @State private var comparisonResult: DreamComparisonResult?
    @State private var isComparing = false
    @State private var showingDreamPicker = false
    @State private var comparisonType: ComparisonType = .twoDreams
    @State private var showingStats = false
    
    var body: some View {
        NavigationStack {
            Group {
                if selectedDreams.isEmpty {
                    emptyStateView
                } else if comparisonResult == nil {
                    selectionView
                } else {
                    resultView
                }
            }
            .navigationTitle("梦境对比")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !selectedDreams.isEmpty && comparisonResult == nil {
                        Button(action: performComparison) {
                            if isComparing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Label("对比", systemImage: "arrow.left.arrow.right")
                            }
                        }
                        .disabled(selectedDreams.count < 2 || isComparing)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingStats = true }) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .sheet(isPresented: $showingDreamPicker) {
                DreamPickerView(
                    selectedDreams: $selectedDreams,
                    maxSelection: comparisonType == .twoDreams ? 2 : 5,
                    minSelection: 2
                )
            }
            .sheet(isPresented: $showingStats) {
                ComparisonStatsView()
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("开始梦境对比")
                .font(.title2.bold())
            
            Text("选择两个或多个梦境，发现它们之间的\n相似性和差异，获得深度洞察")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingDreamPicker = true }) {
                Label("选择梦境", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            
            // 对比类型选择
            comparisonTypePicker
        }
        .padding()
    }
    
    private var comparisonTypePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("对比类型")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ComparisonType.allCases, id: \.self) { type in
                    Button(action: { comparisonType = type }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundStyle(comparisonType == type ? .purple : .secondary)
                            
                            Text(type.rawValue)
                                .font(.subheadline.bold())
                                .foregroundStyle(comparisonType == type ? .primary : .secondary)
                            
                            Text(type.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    comparisonType == type ? Color.purple : Color.gray.opacity(0.3),
                                    lineWidth: comparisonType == type ? 2 : 1
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Selection View
    
    private var selectionView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 已选梦境预览
                selectedDreamsPreview
                
                // 添加更多按钮
                if selectedDreams.count < (comparisonType == .twoDreams ? 2 : 5) {
                    Button(action: { showingDreamPicker = true }) {
                        Label("添加梦境", systemImage: "plus.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .foregroundStyle(.purple)
                            .cornerRadius(12)
                    }
                }
                
                // 对比说明
                comparisonGuide
            }
            .padding()
        }
    }
    
    private var selectedDreamsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("已选梦境 (\(selectedDreams.count)/\(comparisonType == .twoDreams ? 2 : 5))")
                .font(.headline)
            
            ForEach(selectedDreams) { dream in
                DreamComparisonCard(dream: dream, onRemove: {
                    selectedDreams.removeAll { $0.id == dream.id }
                })
            }
        }
    }
    
    private var comparisonGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("对比将分析")
                .font(.headline)
            
            ForEach([
                ("共同标签和情绪", "tag.fill"),
                ("清晰度和强度", "eye.fill"),
                ("主题和符号", "lightbulb.fill"),
                ("时间模式", "clock.fill")
            ], id: \.0) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.1)
                        .foregroundStyle(.purple)
                        .frame(width: 24)
                    
                    Text(item.0)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Result View
    
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let result = comparisonResult {
                    // 相似度评分
                    similarityScoreCard(result: result)
                    
                    // 相似性
                    if !result.similarities.isEmpty {
                        similaritiesSection(similarities: result.similarities)
                    }
                    
                    // 差异
                    if !result.differences.isEmpty {
                        differencesSection(differences: result.differences)
                    }
                    
                    // 洞察
                    if !result.insights.isEmpty {
                        insightsSection(insights: result.insights)
                    }
                    
                    // 操作按钮
                    actionButtons
                }
            }
            .padding()
        }
    }
    
    private func similarityScoreCard(result: DreamComparisonResult) -> some View {
        VStack(spacing: 12) {
            Text("相似度")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: result.similarityScore)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: result.similarityScore)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", result.similarityScore * 100))
                        .font(.title.bold())
                    
                    Text(similarityDescription(score: result.similarityScore))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func similarityDescription(score: Double) -> String {
        switch score {
        case 0.8...: return "高度相似"
        case 0.6..<0.8: return "中度相似"
        case 0.4..<0.6: return "部分相似"
        default: return "差异较大"
        }
    }
    
    private func similaritiesSection(similarities: [SimilarityCategory]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("相似性", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)
            
            ForEach(similarities) { similarity in
                SimilarityCard(similarity: similarity)
            }
        }
    }
    
    private func differencesSection(differences: [DifferenceCategory]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("差异", systemImage: "minus.circle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            ForEach(differences) { difference in
                DifferenceCard(difference: difference)
            }
        }
    }
    
    private func insightsSection(insights: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("洞察", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.purple)
            
            ForEach(insights, id: \.self) { insight in
                Text(insight)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                comparisonResult = nil
                selectedDreams = []
            }) {
                Label("重新对比", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: saveComparison) {
                Label("保存", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Actions
    
    private func performComparison() {
        isComparing = true
        
        Task {
            do {
                let service = DreamComparisonService(modelContainer: modelContainer)
                let dreamIds = selectedDreams.map { $0.id }
                
                let result: DreamComparisonResult
                if dreamIds.count == 2 {
                    result = try await service.compareTwoDreams(dreamAId: dreamIds[0], dreamBId: dreamIds[1])
                } else {
                    result = try await service.compareMultipleDreams(dreamIds: dreamIds)
                }
                
                await MainActor.run {
                    comparisonResult = result
                    isComparing = false
                }
            } catch {
                await MainActor.run {
                    isComparing = false
                    // 显示错误
                }
            }
        }
    }
    
    private func saveComparison() {
        // 保存逻辑
    }
}

// MARK: - Dream Comparison Card

struct DreamComparisonCard: View {
    let dream: Dream
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dream.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(dream.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Label("\(dream.clarity)", systemImage: "eye.fill")
                        .font(.caption)
                    
                    Label("\(dream.intensity)", systemImage: "flame.fill")
                        .font(.caption)
                    
                    if dream.isLucid {
                        Label("清醒", systemImage: "brain.head.profile")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Similarity Card

struct SimilarityCard: View {
    let similarity: SimilarityCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: similarity.category.icon)
                    .foregroundStyle(.green)
                
                Text(similarity.category.rawValue)
                    .font(.subheadline.bold())
                
                Spacer()
                
                Text(String(format: "%.0f%%", similarity.confidence * 100))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .cornerRadius(8)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(similarity.items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Difference Card

struct DifferenceCard: View {
    let difference: DifferenceCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: difference.category.icon)
                    .foregroundStyle(.orange)
                
                Text(difference.category.rawValue)
                    .font(.subheadline.bold())
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("梦境 A")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(difference.dreamAValue)
                        .font(.subheadline)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("梦境 B")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(difference.dreamBValue)
                        .font(.subheadline)
                }
            }
            
            Text(difference.significance)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Dream Picker View

struct DreamPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDreams: [Dream]
    let maxSelection: Int
    let minSelection: Int
    @State private var searchText = ""
    @State private var selectedIds: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredDreams) { dream in
                    DreamSelectionRow(
                        dream: dream,
                        isSelected: selectedIds.contains(dream.id),
                        canSelectMore: selectedIds.count < maxSelection
                    ) {
                        if selectedIds.contains(dream.id) {
                            selectedIds.remove(dream.id)
                        } else if selectedIds.count < maxSelection {
                            selectedIds.insert(dream.id)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("选择梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成 (\(selectedIds.count))") {
                        selectedDreams = filteredDreams.filter { selectedIds.contains($0.id) }
                        dismiss()
                    }
                    .disabled(selectedIds.count < minSelection)
                }
            }
        }
    }
    
    private var filteredDreams: [Dream] {
        // 简化实现，实际应从 modelContext 获取
        return []
    }
}

// MARK: - Dream Selection Row

struct DreamSelectionRow: View {
    let dream: Dream
    let isSelected: Bool
    let canSelectMore: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .purple : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dream.title)
                    .font(.headline)
                
                Text(dream.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if dream.isLucid {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// MARK: - Comparison Stats View

struct ComparisonStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var statistics: ComparisonStatistics?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let stats = statistics {
                        ComparisonStatCard(
                            title: "总对比次数",
                            value: "\(stats.totalComparisons)",
                            icon: "doc.text.fill",
                            color: .purple
                        )
                        
                        ComparisonStatCard(
                            title: "平均相似度",
                            value: String(format: "%.0f%%", stats.averageSimilarity * 100),
                            icon: "chart.bar.fill",
                            color: .blue
                        )
                        
                        if let mostCommon = stats.mostCommonSimilarity {
                            ComparisonStatCard(
                                title: "最常见相似性",
                                value: mostCommon.rawValue,
                                icon: mostCommon.icon,
                                color: .green
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("对比统计")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                let service = DreamComparisonService(modelContainer: modelContainer)
                statistics = await service.getComparisonStatistics()
            }
        }
    }
}

// MARK: - Stat Card

struct ComparisonStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.title2.bold())
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    DreamComparisonView()
        .modelContainer(for: Dream.self)
}
