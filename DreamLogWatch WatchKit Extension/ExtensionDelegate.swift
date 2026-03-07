//
//  ExtensionDelegate.swift
//  DreamLog WatchKit Extension
//
//  WatchKit 扩展代理
//

import WatchKit
import UserNotifications

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        // 配置通知
        configureNotifications()
    }
    
    func applicationDidBecomeActive() {
        // 应用变为活跃状态
    }
    
    func applicationWillResignActive() {
        // 应用即将进入非活跃状态
    }
    
    func didRegisterUserNotificationSettings(_ notificationSettings: WKUserNotificationSettings) {
        // 通知设置已注册
    }
    
    func didReceiveUserInfo(_ userInfo: [String : Any] = [:]) {
        // 收到来自 iPhone 的用户信息
    }
    
    private func configureNotifications() {
        let center = UNUserNotificationCenter.current()
        
        // 请求通知权限
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知权限已授予")
            } else if let error = error {
                print("❌ 通知权限请求失败：\(error.localizedDescription)")
            }
        }
        
        // 注册通知类别
        let recordCategory = UNNotificationCategory(
            identifier: "DREAM_RECORD_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([recordCategory])
    }
}
