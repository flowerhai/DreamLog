//
//  SharedModelContainer.swift
//  DreamLog
//
//  共享 SwiftData 模型容器
//  为各个服务提供统一的模型访问点
//

import SwiftData

/// 共享模型容器单例
enum SharedModelContainer {
    /// 主模型容器实例
    /// 注意：需要在 DreamLogApp 初始化后设置
    static var main: ModelContainer?
    
    /// 初始化共享容器
    /// - Parameter container: 应用的主模型容器
    static func initialize(_ container: ModelContainer) {
        self.main = container
    }
    
    /// 获取模型容器，如果未初始化则抛出错误
    static func requireContainer() throws -> ModelContainer {
        guard let container = main else {
            throw SharedModelContainerError.notInitialized
        }
        return container
    }
}

enum SharedModelContainerError: LocalizedError {
    case notInitialized
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "SharedModelContainer 未初始化，请确保在 DreamLogApp 中调用 initialize()"
        }
    }
}
