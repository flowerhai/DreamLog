//
//  ContentView.swift
//  DreamLog
//
//  主容器视图
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dreamStore: DreamStore
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
            
            CommunityView(dreamStore: dreamStore)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("社区")
                }
                .tag(3)
            
            SleepDataView()
                .tabItem {
                    Image(systemName: "moon.stars.fill")
                    Text("睡眠")
                }
                .tag(4)
            
            DreamDictionaryView()
                .tabItem {
                    Image(systemName: "text.book.closed.fill")
                    Text("词典")
                }
                .tag(5)
            
            DreamsGoalView()
                .tabItem {
                    Image(systemName: "target")
                    Text("目标")
                }
                .tag(6)
            
            LucidTrainingView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("训练")
                }
                .tag(7)
            
            GalleryView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("画廊")
                }
                .tag(8)
            
            DreamGraphView()
                .tabItem {
                    Image(systemName: "network")
                    Text("图谱")
                }
                .tag(9)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(10)
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
}
