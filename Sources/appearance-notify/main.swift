import Foundation
import AppKit
import os

private let logger = Logger(subsystem: "io.github.odysseus0.appearance-notify", category: "hooks")

@main
struct AppearanceNotify {
    static let hooksDirectory = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/appearance-notify/hooks.d")
    
    static func main() {
        signal(SIGTERM) { _ in exit(0) }
        
        logger.info("appearance-notify starting")
        
        createHooksDirectory()
        executeHooks()
        
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: nil
        ) { _ in
            logger.info("Theme change detected")
            executeHooks()
        }
        
        RunLoop.main.run()
    }
    
    static func createHooksDirectory() {
        try? FileManager.default.createDirectory(
            at: hooksDirectory,
            withIntermediateDirectories: true
        )
    }
    
    static func executeHooks() {
        let isDarkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        var environment = ProcessInfo.processInfo.environment
        environment["DARKMODE"] = isDarkMode ? "1" : "0"
        
        guard let hooks = try? FileManager.default.contentsOfDirectory(
            at: hooksDirectory,
            includingPropertiesForKeys: [.isExecutableKey]
        ) else { return }
        
        var processes: [Process] = []
        
        for hook in hooks {
            guard (try? hook.resourceValues(forKeys: [.isExecutableKey]))?.isExecutable == true else {
                continue
            }
            
            let process = Process()
            process.executableURL = hook
            process.environment = environment
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            
            do {
                try process.run()
                processes.append(process)
                logger.info("Executing hook: \(hook.lastPathComponent)")
            } catch {
                logger.error("Failed to execute \(hook.lastPathComponent): \(error)")
            }
        }
        
        // Kill any hooks still running after 30 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            for process in processes where process.isRunning {
                logger.warning("Terminating long-running hook: \(process.executableURL?.lastPathComponent ?? "unknown")")
                process.terminate()
            }
        }
    }
}