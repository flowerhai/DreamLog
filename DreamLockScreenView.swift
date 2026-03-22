//
//  DreamLockScreenView.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import LocalAuthentication

// MARK: - Dream Lock Screen View

/// 生物识别锁定屏幕
struct DreamLockScreenView: View {
    @StateObject private var lockService = DreamBiometricLockService.shared
    @State private var isAuthenticating = false
    @State private var showPasscode = false
    @State private var passcode = ""
    @State private var errorMessage = ""
    @State private var shakeAnimation = false
    
    var onUnlock: () -> Void
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.9), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 应用图标
                VStack(spacing: 16) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .purple.opacity(0.5), radius: 20)
                    
                    Text("DreamLog")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // 生物识别图标
                VStack(spacing: 16) {
                    if isAuthenticating {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    } else {
                        Button(action: authenticate) {
                            Image(systemName: biometricIconName)
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .padding(30)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Text(biometricInstruction)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isAuthenticating)
                
                // 使用密码选项
                if lockService.biometricType != .none {
                    Button(action: { showPasscode = true }) {
                        Text("使用密码")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 20)
                    }
                }
                
                Spacer()
                    .frame(height: 50)
            }
            .padding()
        }
        .sheet(isPresented: $showPasscode) {
            PasscodeInputView(passcode: $passcode, onUnlock: onUnlock)
        }
    }
    
    private var biometricIconName: String {
        switch lockService.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.shield"
        @unknown default: return "lock.shield"
        }
    }
    
    private var biometricInstruction: String {
        switch lockService.biometricType {
        case .faceID: return "注视屏幕以解锁"
        case .touchID: return "轻触以解锁"
        case .none: return "生物识别不可用"
        @unknown default: return "验证身份以解锁"
        }
    }
    
    private func authenticate() {
        Task {
            isAuthenticating = true
            errorMessage = ""
            
            do {
                let success = try await lockService.authenticateWithBiometrics()
                
                await MainActor.run {
                    isAuthenticating = false
                    
                    if success {
                        onUnlock()
                    } else {
                        errorMessage = "验证失败，请重试"
                        shakeAnimation = true
                    }
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    errorMessage = error.localizedDescription
                    shakeAnimation = true
                }
            }
        }
    }
}

// MARK: - Passcode Input View

/// 密码输入界面
struct PasscodeInputView: View {
    @Binding var passcode: String
    @Environment(\.dismiss) var dismiss
    @State private var enteredPasscode = ""
    @State private var shakeAnimation = false
    @State private var errorMessage = ""
    
    var onUnlock: () -> Void
    
    let maxLength = 6
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            Text("输入密码")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 密码点
            HStack(spacing: 16) {
                ForEach(0..<maxLength, id: \.self) { index in
                    Circle()
                        .fill(index < enteredPasscode.count ? Color.white : Color.clear)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                }
            }
            .padding(.vertical, 20)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // 数字键盘
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 40) {
                        ForEach(0..<3) { col in
                            let number = row * 3 + col + 1
                            NumberButton(number: "\(number)") {
                                enterNumber("\(number)")
                            }
                        }
                    }
                }
                
                // 最后一行
                HStack(spacing: 40) {
                    Spacer()
                    
                    NumberButton(number: "0") {
                        enterNumber("0")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        deleteNumber()
                    }) {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    
                    Spacer()
                }
            }
            
            // 取消按钮
            Button(action: { dismiss() }) {
                Text("取消")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 20)
        }
        .padding()
        .background(Color.black.opacity(0.95))
        .onChange(of: enteredPasscode) { _, newValue in
            if newValue.count == maxLength {
                verifyPasscode()
            }
        }
    }
    
    private func enterNumber(_ number: String) {
        guard enteredPasscode.count < maxLength else { return }
        enteredPasscode.append(number)
    }
    
    private func deleteNumber() {
        guard !enteredPasscode.isEmpty else { return }
        enteredPasscode.removeLast()
        errorMessage = ""
    }
    
    private func verifyPasscode() {
        // 这里应该验证存储的密码哈希
        // 简化实现：假设密码是 "123456"
        if enteredPasscode == "123456" {
            passcode = enteredPasscode
            onUnlock()
            dismiss()
        } else {
            errorMessage = "密码错误"
            shakeAnimation = true
            enteredPasscode = ""
        }
    }
}

// MARK: - Number Button

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - App Lock Overlay

/// 应用锁覆盖层
struct AppLockOverlay: View {
    @StateObject private var lockService = DreamBiometricLockService.shared
    @State private var isShowingLockScreen = false
    @State private var isUnlocked = false
    
    var content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        ZStack {
            content
            
            if isShowingLockScreen && !isUnlocked {
                DreamLockScreenView {
                    isUnlocked = true
                    isShowingLockScreen = false
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            checkLockStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkLockStatus()
        }
    }
    
    private func checkLockStatus() {
        if !lockService.isAppUnlocked {
            isShowingLockScreen = true
            isUnlocked = false
        }
    }
}

// MARK: - Preview

#Preview {
    DreamLockScreenView {
        print("Unlocked!")
    }
}
