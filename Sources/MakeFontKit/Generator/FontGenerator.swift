import Foundation
import SystemKit
import AssetCatalogKit
import AppKit

public enum FontGeneratorError: LocalizedError {
    case noFontFilesFound
    case outputDirectoryDoesNotExist(URL)
    
    public var errorDescription: String? {
        switch self {
        case .noFontFilesFound:
            return "No font files were found."
        case .outputDirectoryDoesNotExist(let url):
            return "Output directory does not exist: \(url.path())"
        }
    }
}

public class FontGenerator {
    
    public init() {
        //
    }
    
    public func generate(_ urls: [URL], outputURL: URL? = nil) async throws -> URL {
        
        let fontPaths = extractFontPaths(from: urls)
        guard !fontPaths.isEmpty else {
            throw FontGeneratorError.noFontFilesFound
        }
        
        var families: [String: FontFamily] = [:]
        
        for path in fontPaths {
            let parts = path.deletingExtension.lastComponent.split(separator: "-")
            let name = String(parts[0])
            let style = String(parts[1])
            let fonts = (families[name]?.fonts ?? []) + [
                FontFamily.Font(style: style, path: path)
            ]
            families[name] = FontFamily(name: name, fonts: fonts)
        }
        
        let basePath: Path
        if let outputURL {
            basePath = Path(outputURL.path())
            guard basePath.exists else {
                throw FontGeneratorError.outputDirectoryDoesNotExist(outputURL)
            }
        } else {
            basePath = Path.temporaryDirectory
        }
        
        let outputPath = basePath.appendingComponent("mkfont")
        
        if outputPath.exists {
            try outputPath.remove()
        }
        
        for family in families.values {
            print("Generating asset catalog for \(family.name)...")
            
            let packagePath = outputPath.appendingComponent("\(family.name)Font")
            try packagePath.createDirectory()
            
            let sourcesPath = packagePath
                .appendingComponent("Sources")
                .appendingComponent("\(family.name)Font")
            try sourcesPath.createDirectory(withIntermediateDirectories: true)
            
            let manifest = generatePackageManifest(for: family)
            let manifestPath = packagePath.appendingComponent("Package.swift")
            try manifest.write(to: manifestPath.url, atomically: true, encoding: .utf8)
            
            let assetCatalog = generateAssetCatalog(for: family)
            try assetCatalog.write(to: sourcesPath.string)
            
            let boilerplate = generateBoilerplate()
            for (filename, content) in boilerplate {
                let path = sourcesPath.appendingComponent(filename)
                try content.write(to: path.url, atomically: true, encoding: .utf8)
            }
            
            let fontStruct = generateFontStruct(for: family)
            let fontStructPath = sourcesPath.appendingComponent("\(family.name)Font.swift")
            try fontStruct.write(to: fontStructPath.url, atomically: true, encoding: .utf8)
            
            let fontExtension = generateFontExtension(for: family)
            let fontExtensionPath = sourcesPath.appendingComponent("Font+\(family.name).swift")
            try fontExtension.write(to: fontExtensionPath.url, atomically: true, encoding: .utf8)

            let uiFontExtension = generateUIFontExtension(for: family)
            let uiFontExtensionPath = sourcesPath.appendingComponent("UIFont+\(family.name).swift")
            try uiFontExtension.write(to: uiFontExtensionPath.url, atomically: true, encoding: .utf8)
        }
        
        return outputPath.url
    }
    
    public func extractFontPaths(from urls: [URL]) -> [Path] {
        let paths: [Path] = urls
            .filter { url in url.isFileURL }
            .map { url in Path(url.path()) }
            .flatMap { path in
                if path.isDirectory {
                    return (try? path.recursiveContentsOfDirectory(fullPaths: true)) ?? []
                } else {
                    return [path]
                }
            }
            .filter { path in ["ttf", "otf"].contains(path.extension.lowercased()) }
            .filter { path in
                path.deletingExtension.lastComponent.split(separator: "-").count == 2
            }
        return paths
    }
    
    public func generatePackageManifest(for fontFamily: FontFamily) -> String {
        let swiftToolsVersion = "5.8"
        let iOSVersion = ".v14"
        let macOSVersion = ".v12"
        let packageName = "\(fontFamily.name)Font"
        let libraryName = "\(fontFamily.name)Font"
        let targetName = "\(fontFamily.name)Font"
        
        return """
            // swift-tools-version: \(swiftToolsVersion)
            
            import PackageDescription
            
            let package = Package(
               name: "\(packageName)",
               platforms: [.iOS(\(iOSVersion)), .macOS(\(macOSVersion))],
               products: [
                  .library(name: "\(libraryName)", targets: ["\(targetName)"])
               ],
               targets: [
                  .target(name: "\(targetName)")
               ]
            )
            """
    }
    
    public func generateAssetCatalog(for fontFamily: FontFamily) -> AssetCatalog {
        let dataSets = fontFamily.fonts.map { font in
            DataSet(name: font.dataSetName,
                    properties: DataProperties(),
                    data: [
                        DataItem(filename: font.path.lastComponent,
                                 universalTypeIdentifier: "public.font",
                                 data: .url(font.path.url))
                    ])
        }
        
        return AssetCatalog(name: "\(fontFamily.name)Font", children: [
            Group(name: "Fonts",
                  properties: GroupProperties(providesNamespace: true),
                  children: dataSets)
        ])
    }
    
    public func generateBoilerplate() -> [String: String] {
        var files: [String: String] = [:]
        
        files["FontRegistration.swift"] = #"""
            #if canImport(UIKit)
            import UIKit
            #elseif canImport(AppKit)
            import AppKit
            #endif
            import CoreGraphics
            import CoreText
            
            public enum FontError: Swift.Error {
               case failedToRegisterFont
            }
            
            func registerFont(named name: String) throws {
               guard let asset = NSDataAsset(name: "Fonts/\(name)", bundle: Bundle.module),
                  let provider = CGDataProvider(data: asset.data as NSData),
                  let font = CGFont(provider),
                  CTFontManagerRegisterGraphicsFont(font, nil) else {
                throw FontError.failedToRegisterFont
               }
            }
            """#
        
        return files
    }
    
    public func generateFontStruct(for fontFamily: FontFamily) -> String {
        
        var staticFonts: String = ""
        for font in fontFamily.fonts {
            let style = font.style.lowercased()
            let name = font.path.deletingExtension.lastComponent
            staticFonts += "    public static let \(style) = \(fontFamily.name)Font(named: \"\(name)\")\n"
        }
        
        return """
            import SwiftUI

            public struct \(fontFamily.name)Font {
                public let name: String

                private init(named name: String) {
                    self.name = name
                    do {
                        try registerFont(named: name)
                    } catch {
                        let reason = error.localizedDescription
                        fatalError("Failed to register font: \\(reason)")
                    }
                }

            \(staticFonts)
            }
            """
    }
    
    public func generateFontExtension(for fontFamily: FontFamily) -> String {
        return """
            import SwiftUI

            extension Font {

                public struct \(fontFamily.name) {

                    /// Returns a fixed-size font of the specified style.
                    public static func fixed(_ style: \(fontFamily.name)Font, size: CGFloat) -> Font {
                        return Font.custom(style.name, fixedSize: size)
                    }

                    /// Returns a relative-size font of the specified style.
                    public static func relative(_ style: \(fontFamily.name)Font, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
                        return Font.custom(style.name, size: size, relativeTo: textStyle)
                    }
                }
            }
            """
    }
    
    public func generateUIFontExtension(for fontFamily: FontFamily) -> String {
        return """
            #if canImport(UIKit)
            import UIKit

            extension UIFont {
                
                public struct \(fontFamily.name) {
                
                    /// Returns a fixed-size font of the specified style.
                    static func fixed(_ style: \(fontFamily.name)Font, size: CGFloat) -> UIFont {
                        guard let customFont = UIFont(name: style.name, size: size) else {
                            // Fall back to system font.
                            return UIFont.systemFont(ofSize: size)
                        }
                        return customFont
                    }
                    
                    /// Returns a relative-size font of the specified style.
                    static func relative(_ style: \(fontFamily.name)Font, size: CGFloat, relativeTo textStyle: UIFont.TextStyle) -> UIFont {
                        let customFont = UIFont(name: style.name, size: size)
                        if let font = customFont {
                            // Scale the custom font according to the text style.
                            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
                        } else {
                            // Fall back to system font.
                            return UIFont.preferredFont(forTextStyle: textStyle)
                        }
                    }
                }
            }
            #endif
            """
    }
}
