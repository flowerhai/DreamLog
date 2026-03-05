//
//  Theme.swift
//  DreamLog
//
//  主题配置
//

import SwiftUI

extension Color {
    // 主色调
    static let midnightPurple = Color(hex: "6B4E9A")
    static let dreamBlue = Color(hex: "4A90D9")
    static let starGold = Color(hex: "FFD700")
    
    // 背景色
    static let deepSpace = Color(hex: "1A1A2E")
    static let nebula = Color(hex: "2D2D44")
    
    // 功能色
    static let dreamPurple = Color(hex: "9B7EBD")
    static let memoryBlue = Color(hex: "6BB6FF")
    static let insightGold = Color(hex: "FFC857")
}

struct Theme {
    // 渐变色
    static let nightSky = LinearGradient(
        colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let dreamGradient = LinearGradient(
        colors: [Color(hex: "6B4E9A"), Color(hex: "9B7EBD"), Color(hex: "C9B1DD")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let starryGradient = RadialGradient(
        colors: [Color(hex: "FFD700"), Color(hex: "FFA500"), Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 100
    )
    
    // 圆角
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    static let xlargeRadius: CGFloat = 24
    
    // 间距
    static let smallPadding: CGFloat = 8
    static let mediumPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
