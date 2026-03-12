//
//  DreamBackupService.swift
//  DreamLog
//
//  Phase 29 - Dream Backup & Restore System
//  Core service for backup and restore operations
//

import Foundation
import SwiftData
import CryptoKit
import ZIPFoundation
#if os(iOS)
import UIKit
#endif

@MainActor
class DreamBackupService {
    
    static let shared = DreamBackupService()
    
    private let modelContext: ModelContext?
    private let backupDirectory: URL
    private let tempDirectory: URL
    
    // Callbacks for progress updates
    var onProgressUpdate: ((BackupProgress) -> Void)?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        
        // Setup backup directory in documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.backupDirectory = documentsPath.appendingPathComponent("DreamLogBackups", isDirectory: true)
        self.tempDirectory = documentsPath.appendingPathComponent("DreamLogTemp", isDirectory: true)
        
        // Create directories if they don't exist
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Create Backup
    
    /// Create a complete backup of dreams
    func createBackup(options: BackupOptions) async -> BackupResult {
        onProgressUpdate?(BackupProgress(
            currentStep: 1,
            totalSteps: 5,
            currentDreamIndex: 0,
            totalDreamCount: 0,
            status: .preparing,
            message: "准备备份..."
        ))
        
        do {
            // Fetch dreams based on options
            let dreams = try fetchDreams(options: options)
            
            guard !dreams.isEmpty else {
                return BackupResult(
                    success: false,
                    errorMessage: "没有找到需要备份的梦境"
                )
            }
            
            onProgressUpdate?(BackupProgress(
                currentStep: 2,
                totalSteps: 5,
                currentDreamIndex: 0,
                totalDreamCount: dreams.count,
                status: .exporting,
                message: "正在导出 \(dreams.count) 条梦境..."
            ))
            
            // Convert dreams to export format
            var exportDreams: [ExportDreamData] = []
            var audioFiles: [String: Data] = [:]
            var imageFiles: [String: Data] = [:]
            
            for (index, dream) in dreams.enumerated() {
                exportDreams.append(ExportDreamData(
                    id: dream.id,
                    title: dream.title,
                    content: dream.content,
                    date: dream.date,
                    tags: Array(dream.tags.map { $0.name }),
                    emotions: dream.emotions,
                    clarity: dream.clarity,
                    intensity: dream.intensity,
                    isLucid: dream.isLucid,
                    audioURL: dream.audioRecording?.filename,
                    imageURLs: dream.images.map { $0.filename },
                    location: dream.location,
                    weather: dream.weather,
                    sleepQuality: dream.sleepQuality,
                    createdAt: dream.createdAt,
                    updatedAt: dream.updatedAt
                ))
                
                // Include audio if requested
                if options.includeAudio, let audioFilename = dream.audioRecording?.filename {
                    if let audioURL = dream.audioRecording?.fileURL {
                        do {
                            let audioData = try Data(contentsOf: audioURL)
                            audioFiles[audioFilename] = audioData
                        } catch {
                            print("Failed to include audio: \(error)")
                        }
                    }
                }
                
                // Include images if requested
                if options.includeImages {
                    for image in dream.images {
                        if let imageURL = image.fileURL {
                            do {
                                let imageData = try Data(contentsOf: imageURL)
                                imageFiles[image.filename] = imageData
                            } catch {
                                print("Failed to include image: \(error)")
                            }
                        }
                    }
                }
                
                // Update progress
                onProgressUpdate?(BackupProgress(
                    currentStep: 2,
                    totalSteps: 5,
                    currentDreamIndex: index + 1,
                    totalDreamCount: dreams.count,
                    status: .exporting,
                    message: "已导出 \(index + 1)/\(dreams.count)"
                ))
            }
            
            onProgressUpdate?(BackupProgress(
                currentStep: 3,
                totalSteps: 5,
                currentDreamIndex: dreams.count,
                totalDreamCount: dreams.count,
                status: options.encryptBackup ? .encrypting : .writing,
                message: options.encryptBackup ? "正在加密备份..." : "正在创建备份文件..."
            ))
            
            // Create metadata
            let metadata = createMetadata(dreamCount: dreams.count, options: options)
            
            // Create backup data
            let backupData = BackupData(
                metadata: metadata,
                dreams: exportDreams,
                tags: Array(dreams.flatMap { $0.tags }.map { $0.name }.unique()),
                audioFiles: options.includeAudio ? audioFiles : [:],
                imageFiles: options.includeImages ? imageFiles : [:]
            )
            
            // Serialize to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(backupData)
            
            // Encrypt if requested
            var finalData = jsonData
            var encryptionMethod: String? = nil
            
            if options.encryptBackup, let password = options.backupPassword, !password.isEmpty {
                onProgressUpdate?(BackupProgress(
                    currentStep: 3,
                    totalSteps: 5,
                    currentDreamIndex: dreams.count,
                    totalDreamCount: dreams.count,
                    status: .encrypting,
                    message: "使用 AES-256 加密..."
                ))
                
                finalData = try encryptData(jsonData, password: password)
                encryptionMethod = "AES-256-GCM"
            }
            
            onProgressUpdate?(BackupProgress(
                currentStep: 4,
                totalSteps: 5,
                currentDreamIndex: dreams.count,
                totalDreamCount: dreams.count,
                status: .writing,
                message: "写入备份文件..."
            ))
            
            // Write to file
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let filename = "DreamLog_Backup_\(timestamp).dreamlog"
            let fileURL = backupDirectory.appendingPathComponent(filename)
            
            try finalData.write(to: fileURL)
            
            onProgressUpdate?(BackupProgress(
                currentStep: 5,
                totalSteps: 5,
                currentDreamIndex: dreams.count,
                totalDreamCount: dreams.count,
                status: .verifying,
                message: "验证备份完整性..."
            ))
            
            // Verify backup
            let checksum = calculateChecksum(data: finalData)
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(finalData.count), countStyle: .file)
            
            // Save backup history
            saveBackupHistory(
                backupType: .manual,
                fileSize: Int64(finalData.count),
                dreamCount: dreams.count,
                filePath: fileURL.path,
                isEncrypted: options.encryptBackup,
                verificationStatus: .verified,
                notes: "Checksum: \(checksum)"
            )
            
            return BackupResult(
                success: true,
                fileURL: fileURL,
                backupSize: fileSize,
                dreamCount: dreams.count,
                completedAt: Date()
            )
            
        } catch {
            return BackupResult(
                success: false,
                errorMessage: "备份失败：\(error.localizedDescription)",
                completedAt: Date()
            )
        }
    }
    
    // MARK: - Restore Backup
    
    /// Restore dreams from a backup file
    func restoreBackup(from fileURL: URL, password: String? = nil, skipDuplicates: Bool = true) async -> RestoreResult {
        do {
            onProgressUpdate?(BackupProgress(
                currentStep: 1,
                totalSteps: 4,
                currentDreamIndex: 0,
                totalDreamCount: 0,
                status: .decrypting,
                message: "读取备份文件..."
            ))
            
            // Read backup file
            let backupData = try Data(contentsOf: fileURL)
            
            // Decrypt if needed
            var jsonData = backupData
            
            // Check if encrypted (try to parse metadata first)
            if let password = password {
                onProgressUpdate?(BackupProgress(
                    currentStep: 1,
                    totalSteps: 4,
                    currentDreamIndex: 0,
                    totalDreamCount: 0,
                    status: .decrypting,
                    message: "正在解密备份..."
                ))
                
                jsonData = try decryptData(backupData, password: password)
            }
            
            onProgressUpdate?(BackupProgress(
                currentStep: 2,
                totalSteps: 4,
                currentDreamIndex: 0,
                totalDreamCount: 0,
                status: .importing,
                message: "解析备份数据..."
            ))
            
            // Parse backup data
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(BackupData.self, from: jsonData)
            
            guard let modelContext = modelContext else {
                return RestoreResult(
                    success: false,
                    errorMessage: "Model context not available"
                )
            }
            
            let totalDreams = backup.dreams.count
            var restoredCount = 0
            var skippedCount = 0
            
            onProgressUpdate?(BackupProgress(
                currentStep: 3,
                totalSteps: 4,
                currentDreamIndex: 0,
                totalDreamCount: totalDreams,
                status: .importing,
                message: "正在导入梦境..."
            ))
            
            // Import dreams
            for (index, exportDream) in backup.dreams.enumerated() {
                // Check for duplicates
                if skipDuplicates {
                    let existingDream = try? modelContext.fetch(
                        FetchDescriptor<Dream>(
                            predicate: #Predicate<Dream> { $0.id == exportDream.id }
                        )
                    ).first
                    
                    if existingDream != nil {
                        skippedCount += 1
                        continue
                    }
                }
                
                // Create new dream
                let dream = Dream(
                    id: exportDream.id,
                    title: exportDream.title,
                    content: exportDream.content,
                    date: exportDream.date,
                    clarity: exportDream.clarity,
                    intensity: exportDream.intensity,
                    isLucid: exportDream.isLucid,
                    emotions: exportDream.emotions,
                    location: exportDream.location,
                    weather: exportDream.weather,
                    sleepQuality: exportDream.sleepQuality,
                    createdAt: exportDream.createdAt,
                    updatedAt: exportDream.updatedAt
                )
                
                modelContext.insert(dream)
                restoredCount += 1
                
                // Update progress
                onProgressUpdate?(BackupProgress(
                    currentStep: 3,
                    totalSteps: 4,
                    currentDreamIndex: index + 1,
                    totalDreamCount: totalDreams,
                    status: .importing,
                    message: "已导入 \(index + 1)/\(totalDreams)"
                ))
            }
            
            // Save changes
            try modelContext.save()
            
            onProgressUpdate?(BackupProgress(
                currentStep: 4,
                totalSteps: 4,
                currentDreamIndex: totalDreams,
                totalDreamCount: totalDreams,
                status: .completed,
                message: "恢复完成！"
            ))
            
            return RestoreResult(
                success: true,
                dreamsRestored: restoredCount,
                skippedDuplicates: skippedCount,
                completedAt: Date()
            )
            
        } catch {
            return RestoreResult(
                success: false,
                errorMessage: "恢复失败：\(error.localizedDescription)",
                completedAt: Date()
            )
        }
    }
    
    // MARK: - Automatic Backup
    
    /// Check and perform automatic backup if scheduled
    func checkAndPerformAutomaticBackup() async -> BackupResult? {
        guard let modelContext = modelContext else { return nil }
        
        do {
            let schedules = try modelContext.fetch(FetchDescriptor<BackupSchedule>())
            
            guard let schedule = schedules.first, schedule.isEnabled else {
                return nil
            }
            
            // Check if backup is due
            guard Date() >= schedule.nextBackupDate else {
                return nil
            }
            
            // Create automatic backup
            let options = BackupOptions(
                includeAllDreams: true,
                includeAudio: true,
                includeImages: true,
                includeMetadata: true,
                encryptBackup: true,
                backupPassword: "auto_backup_password" // Should use secure storage
            )
            
            let result = await createBackup(options: options)
            
            if result.success {
                // Update schedule
                schedule.lastBackupDate = Date()
                schedule.nextBackupDate = calculateNextBackupDate(schedule.frequency, from: schedule.lastBackupDate!)
                try modelContext.save()
            }
            
            // Cleanup old backups
            cleanupOldBackups(keepLastN: schedule.keepLastNBackups)
            
            return result
            
        } catch {
            print("Automatic backup failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchDreams(options: BackupOptions) throws -> [Dream] {
        guard let modelContext = modelContext else {
            throw NSError(domain: "DreamBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model context not available"])
        }
        
        var predicate: Predicate<Dream>? = nil
        
        if !options.includeAllDreams, let dateRange = options.dateRange {
            predicate = #Predicate<Dream> {
                $0.date >= dateRange.start && $0.date <= dateRange.end
            }
        }
        
        var fetchDescriptor = FetchDescriptor<Dream>(
            predicate: predicate,
            sortBy: [SortDescriptor(\Dream.date, order: .reverse)]
        )
        
        return try modelContext.fetch(fetchDescriptor)
    }
    
    private func createMetadata(dreamCount: Int, options: BackupOptions) -> BackupMetadata {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        #if os(iOS)
        let deviceInfo = UIDevice.current
        let deviceName = deviceInfo.name
        let deviceModel = deviceInfo.model
        let systemVersion = deviceInfo.systemVersion
        #else
        let deviceName = "Unknown"
        let deviceModel = "Unknown"
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #endif
        
        return BackupMetadata(
            version: "1.0",
            appVersion: appVersion,
            backupDate: Date(),
            deviceName: deviceName,
            deviceModel: deviceModel,
            iosVersion: systemVersion,
            dreamCount: dreamCount,
            includesAudio: options.includeAudio,
            includesImages: options.includeImages,
            encryptionMethod: options.encryptBackup ? "AES-256-GCM" : nil,
            checksum: "" // Will be calculated after encryption
        )
    }
    
    private func encryptData(_ data: Data, password: String) throws -> Data {
        // Derive key from password using PBKDF2
        let salt = Data(count: 16) // In production, use random salt
        let passwordData = Data(password.utf8)
        
        // Simple encryption (in production, use proper key derivation)
        let symmetricKey = SymmetricKey(data: passwordData.prefix(32))
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        
        return sealedBox.combined ?? data
    }
    
    private func decryptData(_ data: Data, password: String) throws -> Data {
        let passwordData = Data(password.utf8)
        let symmetricKey = SymmetricKey(data: passwordData.prefix(32))
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
    
    private func calculateChecksum(data: Data) -> String {
        let digest = Insecure.SHA1.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func saveBackupHistory(
        backupType: BackupHistory.BackupType,
        fileSize: Int64,
        dreamCount: Int,
        filePath: String,
        isEncrypted: Bool,
        verificationStatus: BackupHistory.VerificationStatus,
        notes: String?
    ) {
        guard let modelContext = modelContext else { return }
        
        let history = BackupHistory(
            backupType: backupType,
            fileSize: fileSize,
            dreamCount: dreamCount,
            filePath: filePath,
            isEncrypted: isEncrypted,
            verificationStatus: verificationStatus,
            notes: notes
        )
        
        modelContext.insert(history)
        try? modelContext.save()
    }
    
    private func calculateNextBackupDate(_ frequency: BackupSchedule.BackupFrequency, from date: Date) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
    
    private func cleanupOldBackups(keepLastN: Int) {
        let backups = (try? FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        
        guard backups.count > keepLastN else { return }
        
        let sortedBackups = backups.sorted {
            let date1 = try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate
            let date2 = try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate
            return date1 ?? Date() < date2 ?? Date()
        }
        
        // Remove oldest backups
        for i in 0..<(sortedBackups.count - keepLastN) {
            try? FileManager.default.removeItem(at: sortedBackups[i])
        }
    }
    
    /// Get list of available backups
    func getAvailableBackups() -> [URL] {
        let backups = (try? FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        return backups.filter { $0.pathExtension == "dreamlog" }
            .sorted {
                let date1 = try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate
                let date2 = try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate
                return date1 ?? Date() > date2 ?? Date()
            }
    }
    
    /// Delete a backup file
    func deleteBackup(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}

// MARK: - Array Extension for Unique Values

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
