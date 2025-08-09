import ArgumentParser

@main
struct AppearanceNotify: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "appearance-notify",
        abstract: "Monitor macOS appearance changes and run hooks.",
        discussion: """
            This tool monitors macOS appearance (light/dark mode) changes and executes
            scripts in ~/.config/appearance-notify/hooks.d/ when the appearance changes.
            
            Scripts receive the DARKMODE environment variable (1 for dark, 0 for light).
            """,
        version: BuildInfo.version,
        subcommands: [
            DaemonCommand.self,
            RunCommand.self,
            StatusCommand.self
        ],
        defaultSubcommand: nil
    )
}