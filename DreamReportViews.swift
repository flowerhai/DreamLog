//
//  DreamReportViews.swift
//  DreamLog
//
//  Phase 74: 梦境数据分析增强 📊🔍
//  报告生成与预览 UI
//
//  Created: 2026-03-20
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import SwiftData

// MARK: - 报告中心视图

/// 梦境报告中心
public struct DreamReportCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var reports: [ReportType: DreamReport] = [:]
    @State private var loading = false
    @State private var selectedReportType: ReportType?
    @State private var showingTemplatePicker = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // 生成新报告
                Section("生成报告") {
                    ForEach(ReportType.allCases, id: \.self) { reportType in
                        Button(action: {
                            Task {
                                await generateReport(type: reportType)
                            }
                        }) {
                            HStack {
                                Image(systemName: reportType.icon)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(reportType.displayName)
                                        .font(.headline)
                                    Text(reportType.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if reports[reportType] != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                
                // 已生成的报告
                Section("已生成的报告") {
                    if reports.isEmpty {
                        Text("暂无报告")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(reports.keys), id: \.self) { reportType in
                            if let report = reports[reportType] {
                                NavigationLink(destination: ReportDetailView(report: report)) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: reportType.icon)
                                                .foregroundColor(.blue)
                                            Text(report.title)
                                                .font(.headline)
                                        }
                                        Text("生成于 \(formatDate(report.generatedAt))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 批量操作
                Section("批量操作") {
                    Button(action: {
                        Task {
                            await generateAllReports()
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("生成所有报告")
                        }
                    }
                    
                    Button(role: .destructive) {
                        reports.removeAll()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除所有报告")
                        }
                    }
                }
            }
            .navigationTitle("梦境报告")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingTemplatePicker = true }) {
                        Image(systemName: "wand.and.stars")
                    }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                ReportTemplatePicker()
            }
        }
    }
    
    private func generateReport(type: ReportType) async {
        loading = true
        do {
            let calendar = Calendar.current
            let now = Date()
            
            var startDate: Date
            switch type {
            case .weekly:
                startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .monthly:
                startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .yearly:
                startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            case .custom:
                startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            }
            
            let report = try await DreamReportGenerator.shared.generateReport(
                type: type,
                startDate: startDate,
                endDate: now,
                in: modelContext
            )
            
            reports[type] = report
        } catch {
            print("生成报告失败：\(error)")
        }
        loading = false
    }
    
    private func generateAllReports() async {
        loading = true
        do {
            let newReports = try await DreamReportGenerator.shared.generateAllReports(in: modelContext)
            reports.merge(newReports) { _, new in new }
        } catch {
            print("批量生成失败：\(error)")
        }
        loading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 报告详情视图

struct ReportDetailView: View {
    let report: DreamReport
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 报告标题
                Text(report.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                // 报告摘要
                SummaryCard(summary: report.summary)
                
                // 统计数据
                StatisticsSection(statistics: report.statistics)
                
                // 洞察列表
                InsightsSection(insights: report.insights)
                
                // 推荐建议
                RecommendationsSection(recommendations: report.recommendations)
                
                // 导出按钮
                ExportButtons(onExportPDF: {
                    Task {
                        await exportToPDF()
                    }
                })
            }
            .padding()
        }
        .navigationTitle("报告详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfData {
                ActivityViewController(activityItems: [pdfData])
            }
        }
    }
    
    private func exportToPDF() async {
        do {
            pdfData = try await DreamReportGenerator.shared.generatePDF(from: report)
            showingShareSheet = true
        } catch {
            print("导出 PDF 失败：\(error)")
        }
    }
}

// MARK: - 摘要卡片

struct SummaryCard: View {
    let summary: DreamReport.ReportSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("报告摘要")
                .font(.headline)
            
            HStack {
                StatItem(label: "梦境数", value: "\(summary.totalDreams)")
                StatItem(label: "平均清晰度", value: "\(Int(summary.averageClarity * 100))%")
                StatItem(label: "清醒梦", value: "\(summary.lucidDreamCount)")
            }
            
            Text("主导情绪：\(summary.dominantEmotion)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !summary.keyWords.isEmpty {
                Text("关键词：\(summary.keyWords.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(summary.highlight)
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

// MARK: - 统计项

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
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

// MARK: - 统计部分

struct StatisticsSection: View {
    let statistics: DreamReport.ReportStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("统计数据")
                .font(.headline)
            
            // 热门符号
            if !statistics.topSymbols.isEmpty {
                Text("热门符号 TOP 5")
                    .font(.subheadline)
                
                ForEach(Array(statistics.topSymbols.enumerated()), id: \.offset) { index, symbol in
                    HStack {
                        Text("\(index + 1). \(symbol.symbol)")
                        Spacer()
                        Text("\(symbol.count) 次")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // 平均长度
            Text("平均记录长度：\(Int(statistics.averageLength)) 字")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 睡眠质量相关性
            if let correlation = statistics.sleepQualityCorrelation {
                Text("睡眠质量与清晰度相关性：\(String(format: "%.2f", correlation))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

// MARK: - 洞察部分

struct InsightsSection: View {
    let insights: [DreamReport.ReportInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("洞察与建议")
                .font(.headline)
            
            ForEach(insights) { insight in
                InsightCard(insight: insight)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

// MARK: - 洞察卡片

struct InsightCard: View {
    let insight: DreamReport.ReportInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(insight.severityColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: insight.severityIcon)
                .font(.caption)
                .foregroundColor(insight.severityColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(insight.severityColor.opacity(0.1))
        )
    }
}

extension DreamReport.ReportInsight {
    var severityColor: Color {
        switch severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var severityIcon: String {
        switch severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.circle"
        }
    }
}

// MARK: - 推荐部分

struct RecommendationsSection: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐建议")
                .font(.headline)
            
            ForEach(recommendations, id: \.self) { recommendation in
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    
                    Text(recommendation)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

// MARK: - 导出按钮

struct ExportButtons: View {
    let onExportPDF: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onExportPDF) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("导出为 PDF")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("通过邮件发送")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - 报告模板选择器

struct ReportTemplatePicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ReportType = .weekly
    
    var body: some View {
        NavigationStack {
            List {
                Section("选择报告模板") {
                    ForEach(ReportType.allCases, id: \.self) { template in
                        Button(action: {
                            selectedTemplate = template
                        }) {
                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundColor(selectedTemplate == template ? .blue : .gray)
                                VStack(alignment: .leading) {
                                    Text(template.displayName)
                                        .font(.headline)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedTemplate == template {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("报告模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 活动视图控制器

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 预览

#Preview {
    DreamReportCenterView()
        .modelContainer(for: DreamEntry.self, inMemory: true)
}
