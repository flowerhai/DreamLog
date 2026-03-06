//
//  SiriShortcutViews.swift
//  DreamLog
//
//  Siri 快捷指令 UI 组件 - 引导用户添加快捷指令
//

import SwiftUI
import IntentsUI

// MARK: - Siri 快捷指令设置页面
struct SiriShortcutSettingsView: View {
    @State private var showingShortcutLibrary = false
    
    var body: some View {
        Form {
            Section(header: Label("快捷指令", systemImage: "wand.and.stars")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("使用 Siri 快速记录梦境")
                        .font(.headline)
                    
                    Text("说\"嘿 Siri，记录我的梦境\"即可快速开始")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingShortcutLibrary = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.purple)
                            Text("添加快捷指令")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: "可用语音命令") {
                VoiceCommandRow(
                    icon: "mic.fill",
                    command: "记录我的梦境",
                    description: "快速开始记录新梦境"
                )
                
                VoiceCommandRow(
                    icon: "chart.bar.fill",
                    command: "我的梦境统计",
                    description: "查看梦境记录数据"
                )
                
                VoiceCommandRow(
                    icon: "clock.fill",
                    command: "我最近做了什么梦",
                    description: "查看最近记录的梦境"
                )
                
                VoiceCommandRow(
                    icon: "magnifyingglass",
                    command: "搜索关于...的梦境",
                    description: "根据关键词查找梦境"
                )
            }
            
            Section(header: "使用技巧") {
                VStack(alignment: .leading, spacing: 8) {
                    TipRow(
                        icon: "lightbulb.fill",
                        title: "床头快捷指令",
                        description: "在床头说\"记录我的梦境\"，无需打开 App"
                    )
                    
                    TipRow(
                        icon: "waveform.path.ecg",
                        title: "语音输入",
                        description: "Siri 会自动将语音转换为文字"
                    )
                    
                    TipRow(
                        icon: "star.fill",
                        title: "个性化短语",
                        description: "在快捷指令 App 中自定义触发短语"
                    )
                }
            }
            
            Section {
                Link(destination: URL(string: "shortcuts://")!) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("打开快捷指令 App")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Siri 与快捷指令")
        .sheet(isPresented: $showingShortcutLibrary) {
            ShortcutLibrarySheet()
        }
    }
}

// MARK: - 语音命令行
struct VoiceCommandRow: View {
    let icon: String
    let command: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(command)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 提示行
struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 快捷指令库 Sheet
struct ShortcutLibrarySheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("快捷指令库")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("在快捷指令 App 中搜索\"DreamLog\"，\n添加喜欢的快捷指令到 Siri")
                    .textStyle(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // 打开快捷指令 App
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                    dismiss()
                }) {
                    Text("打开快捷指令 App")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("添加快捷指令")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 首页 Siri 快捷提示卡片
struct SiriShortcutTipCard: View {
    let onDismiss: () -> Void
    @State private var isDismissed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("试试用 Siri 记录梦境")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isDismissed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text("说\"嘿 Siri，记录我的梦境\"，无需打开 App")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                if let url = URL(string: "shortcuts://") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("设置快捷指令 →")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.purple)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .opacity(isDismissed ? 0 : 1)
        .animation(.easeOut(duration: 0.3), value: isDismissed)
    }
}

// MARK: - 录音页面 Siri 提示
struct SiriRecordHintView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.caption)
                .foregroundColor(.purple)
            
            Text("也可以用 Siri 说\"记录我的梦境\"")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

#if DEBUG
struct SiriShortcutSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SiriShortcutSettingsView()
    }
}
#endif
