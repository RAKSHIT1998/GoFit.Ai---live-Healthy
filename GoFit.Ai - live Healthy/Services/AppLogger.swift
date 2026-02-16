import Foundation

/// Application logging service for tracking events, errors, and user actions
/// Stores logs locally for debugging and monitoring app performance
final class AppLogger {
    static let shared = AppLogger()
    
    private init() {
        setupLogDirectory()
        rotateLogsIfNeeded()
    }
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let logLock = DispatchQueue(label: "app.logger.queue")
    private let maxLogFileSize: UInt64 = 10 * 1024 * 1024 // 10 MB
    private let maxLogFiles = 5
    
    private var logsURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("GoFitLogs", isDirectory: true)
    }
    
    private var currentLogFile: URL {
        logsURL.appendingPathComponent("app_\(getDateString()).log")
    }
    
    // MARK: - Log Levels
    enum LogLevel: String {
        case debug = "🔵 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case success = "✅ SUCCESS"
    }
    
    // MARK: - Initialization
    private func setupLogDirectory() {
        logLock.async {
            try? self.fileManager.createDirectory(at: self.logsURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Logging Methods
    func log(_ message: String, level: LogLevel = .info, category: String = "General") {
        logLock.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let logEntry = "[\(timestamp)] [\(level.rawValue)] [\(category)] \(message)\n"
            
            // Print to console
            print(logEntry, terminator: "")
            
            // Write to file
            self.writeToFile(logEntry)
        }
    }
    
    func logAction(user: String? = nil, action: String, details: [String: Any]? = nil) {
        var message = action
        if let user = user {
            message = "[\(user)] \(message)"
        }
        if let details = details {
            let jsonString = (try? String(data: JSONSerialization.data(withJSONObject: details), encoding: .utf8)) ?? ""
            message += " - Details: \(jsonString)"
        }
        log(message, level: .info, category: "UserAction")
    }
    
    func logNetworkRequest(url: String, method: String, statusCode: Int? = nil, duration: TimeInterval? = nil) {
        var message = "\(method) \(url)"
        if let statusCode = statusCode {
            message += " - Status: \(statusCode)"
        }
        if let duration = duration {
            message += " - Duration: \(String(format: "%.2f", duration))s"
        }
        log(message, level: .debug, category: "Network")
    }
    
    func logError(_ error: Error, category: String = "Error", context: String? = nil) {
        var message = error.localizedDescription
        if let context = context {
            message = "\(context) - \(message)"
        }
        log(message, level: .error, category: category)
    }
    
    func logSuccess(_ message: String, category: String = "Success") {
        log(message, level: .success, category: category)
    }
    
    func logWarning(_ message: String, category: String = "Warning") {
        log(message, level: .warning, category: category)
    }
    
    func logDebug(_ message: String, category: String = "Debug") {
        log(message, level: .debug, category: category)
    }
    
    func logPerformance(operation: String, duration: TimeInterval) {
        let message = "\(operation) completed in \(String(format: "%.3f", duration))ms"
        log(message, level: .debug, category: "Performance")
    }
    
    func logMemoryUsage() {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return }
        let usedMemory = Double(taskInfo.resident_size) / (1024 * 1024)
        log("Memory usage: \(String(format: "%.2f", usedMemory)) MB", level: .debug, category: "Performance")
    }
    
    // MARK: - File Operations
    private func writeToFile(_ content: String) {
        do {
            let fileURL = currentLogFile
            
            if fileManager.fileExists(atPath: fileURL.path) {
                if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(content.data(using: .utf8) ?? Data())
                    fileHandle.closeFile()
                }
            } else {
                try content.write(toFile: fileURL.path, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to write log: \(error)")
        }
    }
    
    // MARK: - Log Rotation
    private func rotateLogsIfNeeded() {
        logLock.async {
            do {
                let attributes = try self.fileManager.attributesOfItem(atPath: self.currentLogFile.path)
                let fileSize = (attributes[.size] as? NSNumber)?.unsignedLongLongValue ?? 0
                
                if fileSize > self.maxLogFileSize {
                    self.rotateLogs()
                }
            } catch {
                // File doesn't exist yet, which is fine
            }
        }
    }
    
    private func rotateLogs() {
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsURL, includingPropertiesForKeys: [.contentModificationDateKey])
                .sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                    return date1 > date2
                }
            
            if logFiles.count > maxLogFiles {
                for fileToRemove in logFiles.dropFirst(maxLogFiles) {
                    try fileManager.removeItem(at: fileToRemove)
                }
            }
        } catch {
            print("Failed to rotate logs: \(error)")
        }
    }
    
    // MARK: - Log Retrieval
    func getAllLogs() -> [String] {
        return logLock.sync {
            do {
                let logFiles = try fileManager.contentsOfDirectory(at: logsURL, includingPropertiesForKeys: nil)
                return logFiles
                    .filter { $0.lastPathComponent.hasSuffix(".log") }
                    .compactMap { fileURL in
                        try? String(contentsOf: fileURL, encoding: .utf8)
                    }
                    .reversed()
            } catch {
                print("Failed to retrieve logs: \(error)")
                return []
            }
        }
    }
    
    func getLogsAsString() -> String {
        return getAllLogs().joined(separator: "\n---\n")
    }
    
    func exportLogs() -> URL? {
        let allLogs = getLogsAsString()
        let exportURL = fileManager.temporaryDirectory.appendingPathComponent("GoFit_Logs_\(getDateTimeString()).txt")
        
        do {
            try allLogs.write(to: exportURL, atomically: true, encoding: .utf8)
            log("Logs exported to: \(exportURL.path)", level: .success, category: "LogExport")
            return exportURL
        } catch {
            log("Failed to export logs: \(error.localizedDescription)", level: .error, category: "LogExport")
            return nil
        }
    }
    
    func clearOldLogs(olderThanDays: Int = 7) {
        logLock.async {
            do {
                let cutoffDate = Date().addingTimeInterval(-TimeInterval(olderThanDays * 24 * 60 * 60))
                let logFiles = try self.fileManager.contentsOfDirectory(at: self.logsURL, includingPropertiesForKeys: [.contentModificationDateKey])
                
                for fileURL in logFiles {
                    if let attributes = try? self.fileManager.attributesOfItem(atPath: fileURL.path),
                       let modDate = attributes[.modificationDate] as? Date,
                       modDate < cutoffDate {
                        try self.fileManager.removeItem(at: fileURL)
                        print("🗑️ Removed old log: \(fileURL.lastPathComponent)")
                    }
                }
            } catch {
                print("Failed to clear old logs: \(error)")
            }
        }
    }
    
    // MARK: - Utility
    private func getDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func getDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Swift Extensions for Easy Logging
extension AppLogger {
    /// Log activity with automatic category detection
    func activity(_ message: String) {
        log(message, level: .info, category: "Activity")
    }
    
    /// Log data persistence operation
    func storage(_ message: String) {
        log(message, level: .debug, category: "Storage")
    }
    
    /// Log health kit operations
    func healthKit(_ message: String) {
        log(message, level: .debug, category: "HealthKit")
    }
    
    /// Log workout related events
    func workout(_ message: String) {
        log(message, level: .info, category: "Workout")
    }
    
    /// Log meal related events
    func meal(_ message: String) {
        log(message, level: .info, category: "Meal")
    }
    
    /// Log authentication events
    func auth(_ message: String) {
        log(message, level: .info, category: "Auth")
    }
}
