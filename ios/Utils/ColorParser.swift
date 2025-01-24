import React

class ColorParser {
  static func color(from value: Any?) -> UIColor? {
    if let intValue = value as? Int {
      // Handle RCT integer color value
      return RCTConvert.uiColor(intValue)
    } else if let stringValue = value as? String {
      // Handle hex
      if stringValue.hasPrefix("#") {
        return UIColor(hex: stringValue)
      }
      // Handle named colors
      return namedColor(stringValue)
    }
    return nil
  }

  private static func namedColor(_ name: String) -> UIColor? {
    switch name.lowercased() {
    case "red": return .red
    case "blue": return .blue
    case "green": return .green
    case "black": return .black
    case "white": return .white
    case "gray", "grey": return .gray
    case "yellow": return .yellow
    case "purple": return .purple
    case "orange": return .orange
    case "brown": return .brown
    case "transparent": return .clear
    // Add more colors as needed
    default: return nil
    }
  }
}

extension UIColor {
  convenience init?(hex: String) {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat

    var hexColor = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexColor = hexColor.replacingOccurrences(of: "#", with: "")

    var hexNumber: UInt64 = 0
    guard Scanner(string: hexColor).scanHexInt64(&hexNumber) else {
      return nil
    }

    switch hexColor.count {
    case 3:  // RGB (12-bit)
      r = CGFloat((hexNumber & 0xF00) >> 8) / 15.0
      g = CGFloat((hexNumber & 0x0F0) >> 4) / 15.0
      b = CGFloat(hexNumber & 0x00F) / 15.0
      a = 1.0
    case 6:  // RGB (24-bit)
      r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
      g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
      b = CGFloat(hexNumber & 0x0000FF) / 255.0
      a = 1.0
    case 8:  // RGBA (32-bit)
      r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255.0
      g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255.0
      b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255.0
      a = CGFloat(hexNumber & 0x0000_00FF) / 255.0
    default:
      return nil
    }

    self.init(red: r, green: g, blue: b, alpha: a)
  }
}
