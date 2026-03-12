//
//  DreamEmptyStates.swift
//  DreamLog
//
//  空状态视图 - Phase 30 用户体验优化
//  友好的空状态提示和引导
//

import SwiftUI

// MARK: - 梦境列表空状态

struct DreamsEmptyStateView: View {
    let hasSearched: Bool
    let searchTerm: String?
    let onRecordTap: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 插图
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                if hasSearched {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                } else {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                }
            }
            
            // 标题
            VStack(spacing: 8) {
                Text(hasSearched ? "未找到匹配的梦境" : "开始记录你的第一个梦境")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(hasSearched 
                     ? "试试其他关键词或清除筛选条件"
                     : "捕捉潜意识的秘密，探索内心深处的世界")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // 搜索提示
            if hasSearched, let term = searchTerm {
                Text("搜索词：\"\(term)\"")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            // 操作按钮
            if !hasSearched {
                Button(action: onRecordTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                        Text("开始记录")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 提示卡片
            if !hasSearched {
                VStack(alignment: .leading, spacing: 12) {
                    Text("💡 小提示")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        TipRow(icon: "hand.raised.fill", text: "醒来后立即记录，记忆更清晰")
                        TipRow(icon: "eye.fill", text: "描述细节：场景、人物、情绪")
                        TipRow(icon: "star.fill", text: "标记清醒梦，追踪特殊体验")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
        .padding()
    }
}

// MARK: - 洞察空状态

struct InsightsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            // 插图
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            // 标题
            VStack(spacing: 8) {
                Text("记录更多梦境以获取洞察")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("当你记录 3 个以上的梦境后，\nAI 将为你生成个性化的分析报告")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // 进度指示
            VStack(spacing: 8) {
                HStack {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < 1 ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(index < 1 ? .green : .white.opacity(0.3))
                    }
                }
                
                Text("已记录 1/3 个梦境")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // 功能预览
            VStack(spacing: 16) {
                InsightPreviewRow(
                    icon: "brain.head.profile",
                    title: "梦境解析",
                    description: "荣格心理学 + 跨文化解梦",
                    color: .purple
                )
                InsightPreviewRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "趋势分析",
                    description: "情绪和主题变化趋势",
                    color: .green
                )
                InsightPreviewRow(
                    icon: "lightbulb.fill",
                    title: "智能建议",
                    description: "个性化心理健康建议",
                    color: .orange
                )
            }
            .padding(.horizontal, 20)
        }
        .padding()
    }
}

// MARK: - 时间胶囊空状态

struct TimeCapsuleEmptyStateView: View {
    let onCreateTap: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 插图
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }
            
            // 标题
            VStack(spacing: 8) {
                Text("创建第一个时间胶囊")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("给未来的自己发送一个梦境，\n在指定的日期解锁这份惊喜")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // 操作按钮
            Button(action: onCreateTap) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("创建时间胶囊")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 功能说明
            VStack(alignment: .leading, spacing: 12) {
                CapsuleFeatureRow(
                    icon: "lock.fill",
                    title: "加密保存",
                    description: "AES-256 加密保护，只有你能查看"
                )
                CapsuleFeatureRow(
                    icon: "bell.fill",
                    title: "到期提醒",
                    description: "解锁日期到达时，会收到通知提醒"
                )
                CapsuleFeatureRow(
                    icon: "sparkles",
                    title: "惊喜体验",
                    description: "未来的你，会看到现在的梦境"
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 20)
        }
        .padding()
    }
}

// MARK: - 备份空状态

struct BackupEmptyStateView: View {
    let onCreateTap: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 插图
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.3), Color.green.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.teal)
            }
            
            // 标题
            VStack(spacing: 8) {
                Text("创建第一个备份")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("定期备份你的梦境数据，\n防止意外丢失，支持加密保护")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // 操作按钮
            Button(action: onCreateTap) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.doc.fill")
                    Text("立即备份")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.teal, Color.green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .teal.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 备份选项
            VStack(alignment: .leading, spacing: 10) {
                BackupOptionRow(
                    icon: "iphone",
                    title: "本地备份",
                    description: "存储在当前设备上"
                )
                BackupOptionRow(
                    icon: "icloud.fill",
                    title: "iCloud 备份",
                    description: "同步到 iCloud Drive"
                )
                BackupOptionRow(
                    icon: "lock.shield.fill",
                    title: "加密保护",
                    description: "可选密码或 Face ID 加密"
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 20)
        }
        .padding()
    }
}

// MARK: - 辅助组件

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.yellow)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct InsightPreviewRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CapsuleFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.orange)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

struct BackupOptionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.teal)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - 预览

#Preview("Dreams Empty") {
    DreamsEmptyStateView(hasSearched: false, searchTerm: nil) {
        print("Record tapped")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Insights Empty") {
    InsightsEmptyStateView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}

#Preview("Time Capsule Empty") {
    TimeCapsuleEmptyStateView {
        print("Create tapped")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Backup Empty") {
    BackupEmptyStateView {
        print("Backup tapped")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
