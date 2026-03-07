//
//  Theme.swift
//  DreamLog
//
//  主题配置
//

import SwiftUI
import UIKit

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
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else if length == 3 {
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
        } else {
            // Default to black
            r = 0
            g = 0
            b = 0
            a = 1
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else if length == 3 {
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
        } else {
            // Default to black
            r = 0
            g = 0
            b = 0
            a = 1
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
