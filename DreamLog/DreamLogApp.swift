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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dreamStore)
        }
    }
}
