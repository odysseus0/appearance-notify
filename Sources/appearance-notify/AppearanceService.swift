import Foundation
import os

struct AppearanceService {
    private let logger = Logger(subsystem: "com.appearance.notify", category: "service")
    private let hooksDirectory = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/appearance-notify/hooks.d")
    private let hookTimeoutSeconds: TimeInterval = 30
    
    static let appearanceChangeNotificationName = NSNotification.Name("AppleInterfaceThemeChangedNotification")
    
    func createHooksDirectory() throws {
        try FileManager.default.createDirectory(
            at: hooksDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o755]
        )
    }
    
    var isDarkModeEnabled: Bool {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }
    
    func runAppearanceHooks(for darkMode: Bool) {
        logger.info("Running appearance hooks (dark mode: \(darkMode))")
        
        let hooks: [URL]
        do {
            hooks = try FileManager.default.contentsOfDirectory(
                at: hooksDirectory,
                includingPropertiesForKeys: [.isExecutableKey, .isRegularFileKey]
            )
        } catch {
            logger.error("Failed to read hooks directory: \(error.localizedDescription)")
            return
        }
        
        var processes: [Process] = []
        
        for hook in hooks {
            do {
                let resourceValues = try hook.resourceValues(forKeys: [.isExecutableKey, .isRegularFileKey])
                guard resourceValues.isRegularFile == true,
                      resourceValues.isExecutable == true else {
                    logger.debug("Skipping non-executable file: \(hook.lastPathComponent)")
                    continue
                }
            } catch {
                logger.warning("Failed to check file attributes for \(hook.lastPathComponent): \(error.localizedDescription)")
                continue
            }
            
            let process = Process()
            process.executableURL = hook
            
            // Only pass essential environment variables for security
            var environment = [String: String]()
            environment["DARKMODE"] = darkMode ? "1" : "0"
            environment["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
            // Build a robust PATH for hooks. launchd provides a minimal PATH; include common user locations.
            let homePath = FileManager.default.homeDirectoryForCurrentUser.path
            let baselinePath = "\(homePath)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            let inheritedPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
            let combinedPath = [baselinePath, inheritedPath].filter { !$0.isEmpty }.joined(separator: ":")
            environment["PATH"] = combinedPath
            process.environment = environment
            
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            
            do {
                try process.run()
                processes.append(process)
                logger.info("Executing hook: \(hook.lastPathComponent)")
            } catch {
                logger.error("Failed to execute \(hook.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        // Ensure long-running hooks are terminated
        if !processes.isEmpty {
            Task {
                try? await Task.sleep(for: .seconds(hookTimeoutSeconds))
                for process in processes where process.isRunning {
                    logger.warning("Terminating long-running hook: \(process.executableURL?.lastPathComponent ?? "unknown")")
                    process.terminate()
                }
            }
        }
    }
}