import Foundation
import ArgumentParser
import os

struct DaemonCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "daemon",
        abstract: "Start the appearance watcher daemon."
    )
    
    func run() throws {
        let logger = Logger(subsystem: "com.appearance.notify", category: "daemon")
        
        // Set up signal handling for graceful shutdown
        signal(SIGTERM) { _ in 
            Logger(subsystem: "com.appearance.notify", category: "daemon")
                .info("Received SIGTERM, shutting down")
            Foundation.exit(0) 
        }
        
        let service = AppearanceService()
        
        logger.info("appearance-notify daemon starting (version \(BuildInfo.version))")
        
        do {
            try service.createHooksDirectory()
        } catch {
            logger.error("Failed to create hooks directory: \(error.localizedDescription)")
            throw ExitCode.failure
        }
        
        // Run hooks once at startup
        service.runAppearanceHooks(for: service.isDarkModeEnabled)
        
        // Set up observer for appearance changes
        DistributedNotificationCenter.default().addObserver(
            forName: AppearanceService.appearanceChangeNotificationName,
            object: nil,
            queue: .main
        ) { _ in
            logger.info("Appearance change detected")
            service.runAppearanceHooks(for: service.isDarkModeEnabled)
        }
        
        logger.info("Watching for appearance changes...")
        RunLoop.main.run()
    }
}

struct RunCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run hooks once with the current or specified appearance."
    )
    
    @Flag(help: "Force dark mode for this run")
    var dark = false
    
    @Flag(help: "Force light mode for this run")
    var light = false
    
    mutating func validate() throws {
        if dark && light {
            throw ValidationError("Cannot specify both --dark and --light")
        }
    }
    
    func run() throws {
        let service = AppearanceService()
        
        do {
            try service.createHooksDirectory()
        } catch {
            let logger = Logger(subsystem: "com.appearance.notify", category: "run")
            logger.error("Failed to create hooks directory: \(error.localizedDescription)")
            throw ExitCode.failure
        }
        
        let useDarkMode = if dark {
            true
        } else if light {
            false
        } else {
            service.isDarkModeEnabled
        }
        
        service.runAppearanceHooks(for: useDarkMode)
    }
}

struct StatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Print the current system appearance."
    )
    
    func run() throws {
        let service = AppearanceService()
        let appearance = service.isDarkModeEnabled ? "dark" : "light"
        print(appearance)
    }
}