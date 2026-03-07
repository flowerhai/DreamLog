//
//  NotificationView.swift
//  DreamLog WatchKit Extension
//
//  通知界面
//

import SwiftUI
import WatchKit
import UserNotifications

struct NotificationView: View {
    var body: some View {
        VStack {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(.purple)
            
            Text("梦境提醒")
                .font(.headline)
                .padding(.top, 12)
            
            Text("该记录今天的梦境了")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
    }
}

struct NotificationController: WKUserNotificationHostingController<NotificationView> {
    override var body: NotificationView {
        NotificationView()
    }
}
