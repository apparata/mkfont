import Foundation
import ArgumentParser

struct MKFontCommand: AsyncParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "mkfont",
        abstract: "Create a font Swift package.",
        subcommands: [
            UICommand.self,
            PackageCommand.self
        ])
        
    mutating func run() async throws {
        print(Self.helpMessage())
    }
}
