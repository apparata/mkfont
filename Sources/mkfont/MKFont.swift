import Foundation

@main
struct MKFont {
    static func main() async throws {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.count > 1, arguments[1] == "ui" {
            MakeFontApp.main()
        } else {
            await MKFontCommand.main()
        }
    }
}
