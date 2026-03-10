//
//  ContentView.swift
//  DreamLog
//
//  主容器视图
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @StateObject private var challengeService = DreamChallengeService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("梦境")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日历")
                }
                .tag(1)
            
            InsightsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("洞察")
                }
                .tag(2)
            
            FriendsView(dreamStore: dreamStore)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("好友")
                }
                .tag(3)
            
            CommunityView(dreamStore: dreamStore)
                .tabItem {
                    Image(systemName: "globe")
                    Text("社区")
                }
                .tag(4)
            
            SleepDataView()
                .tabItem {
                    Image(systemName: "moon.stars.fill")
                    Text("睡眠")
                }
                .tag(5)
            
            MeditationView()
                .tabItem {
                    Image(systemName: "music.note.house")
                    Text("冥想")
                }
                .tag(6)
            
            DreamDictionaryView()
                .tabItem {
                    Image(systemName: "text.book.closed.fill")
                    Text("词典")
                }
                .tag(7)
            
            DreamsGoalView()
                .tabItem {
                    Image(systemName: "target")
                    Text("目标")
                }
                .tag(8)
            
            LucidTrainingView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("训练")
                }
                .tag(9)
            
            GalleryView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("画廊")
                }
                .tag(10)
            
            DreamVideoView()
                .tabItem {
                    Image(systemName: "film")
                    Text("视频")
                }
                .tag(11)
            
            DreamGraphView()
                .tabItem {
                    Image(systemName: "network")
                    Text("图谱")
                }
                .tag(11)
            
            DreamMusicView()
                .tabItem {
                    Image(systemName: "music.note.house.fill")
                    Text("音乐")
                }
                .tag(12)
            
            DreamWrappedView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("回顾")
                }
                .tag(13)
            
            DreamAssistantView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("助手")
                }
                .tag(14)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(15)
            
            DreamStoryView()
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text("故事")
                }
                .tag(16)
            
            DreamChallengeView()
                .environmentObject(challengeService)
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("挑战")
                }
                .tag(17)
            
            DreamBackupView()
                .tabItem {
                    Image(systemName: "externaldrive.fill")
                    Text("备份")
                }
                .tag(18)
        }
        .tint(Color(hex: "9B7EBD"))
        .background(
            LinearGradient(
                colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(DreamStore())
        .environmentObject(SpeechService())
        .environmentObject(AIService())
        .environmentObject(DreamChallengeService.shared)
}
