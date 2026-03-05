//
//  DreamLogApp.swift
//  DreamLog
//
//  App 入口
//

import SwiftUI

@main
struct DreamLogApp: App {
    @StateObject private var dreamStore = DreamStore()
    @StateObject private var speechService = SpeechService()
    @StateObject private var aiService = AIService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dreamStore)
                .environmentObject(speechService)
                .environmentObject(aiService)
        }
    }
}
