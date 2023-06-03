import Foundation
import ArgumentParser
import MakeFontKit

struct PackageCommand: AsyncParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "package",
        abstract: "Make a font Swift package.",
        discussion: "Make a font Swift package from TTF/OTF font files.")
    
    @Argument(help: "Path to a directory containing the font files.")
    var path: String

    @Argument(help: "Path to directory where the package(s) will be generated.")
    var output: String?
    
    mutating func run() async throws {
        
        let urls = [URL(filePath: path)]
        let outputURL: URL?
        if let output {
            outputURL = URL(filePath: output)
        } else {
            outputURL = nil
        }
        
        do {
            let url = try await FontGenerator().generate(urls, outputURL: outputURL)
            print("Generated package(s) here:")
            print(url.path())
        } catch {
            print(error.localizedDescription)
            Self.exit(withError: error)
        }
    }
}
