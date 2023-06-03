import Foundation
import SystemKit

public struct FontFamily {
    
    public struct Font: Comparable {
        
        public let style: String
        public let weight: Int?
        public let path: Path
        public let dataSetName: String
        public let isItalic: Bool
        
        internal let sortWeight: Int
        
        init(style: String, path: Path) {
            self.style = style
            self.path = path
            dataSetName = path.deletingExtension.lastComponent
            let styleWeight = style
                .lowercased()
                .replacingOccurrences(of: "italic", with: "")
                .replacingOccurrences(of: "italics", with: "")
            switch styleWeight {
            case "thin": weight = 100
            case "extralight", "ultralight": weight = 200
            case "light": weight = 300
            case "normal", "regular", "": weight = 400
            case "medium": weight = 500
            case "semibold", "demibold": weight = 600
            case "bold": weight = 700
            case "extrabold", "ultrabold": weight = 800
            case "black", "heavy": weight = 900
            default: weight = nil
            }
            isItalic = style.lowercased().contains("italic")
            sortWeight = (weight ?? 1000) + (isItalic ? 1 : 0)
        }

        public static func < (lhs: FontFamily.Font, rhs: FontFamily.Font) -> Bool {
            lhs.sortWeight < rhs.sortWeight
        }

    }
    
    public let name: String
    public let fonts: [Font]
    
    init(name: String, fonts: [Font]) {
        self.name = name
        self.fonts = fonts.sorted { fontA, fontB in
            return fontA.sortWeight < fontB.sortWeight
        }
    }
}
