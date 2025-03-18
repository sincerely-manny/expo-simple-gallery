import UIKit

extension UIImage {
  static func errorPlaceholder(size: CGSize, message: String) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    defer { UIGraphicsEndImageContext() }

    guard let context = UIGraphicsGetCurrentContext() else { return nil }

    // Draw background
    context.setFillColor(UIColor.darkGray.cgColor)
    context.fill(CGRect(origin: .zero, size: size))

    // Draw border
    context.setStrokeColor(UIColor.lightGray.cgColor)
    context.setLineWidth(2)
    context.stroke(CGRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2))

    // Add image icon
    let iconRect = CGRect(x: size.width / 2 - 40, y: size.height / 2 - 60, width: 80, height: 80)
    context.setStrokeColor(UIColor.white.cgColor)
    context.setLineWidth(3)

    // Draw simple image icon
    context.stroke(iconRect)
    context.move(to: CGPoint(x: iconRect.minX + 20, y: iconRect.minY + 20))
    context.addLine(to: CGPoint(x: iconRect.maxX - 20, y: iconRect.maxY - 20))
    context.move(to: CGPoint(x: iconRect.maxX - 20, y: iconRect.minY + 20))
    context.addLine(to: CGPoint(x: iconRect.minX + 20, y: iconRect.maxY - 20))
    context.strokePath()

    // Add error text
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineBreakMode = .byWordWrapping

    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 14),
      .foregroundColor: UIColor.white,
      .paragraphStyle: paragraphStyle,
    ]

    let textRect = CGRect(
      x: 10,
      y: size.height / 2 + 40,
      width: size.width - 20,
      height: size.height / 2 - 50
    )

    message.draw(in: textRect, withAttributes: attributes)

    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
