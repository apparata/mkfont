import Foundation
import ArgumentParser

struct UICommand: AsyncParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "ui",
        abstract: "Run mkfont with a UI.",
        discussion: "Run mkfont with a UI for creating font Swift packages.")
    
    mutating func run() async throws {
        print("This is a dummy command. If you see this, something failed.")
    }
}
