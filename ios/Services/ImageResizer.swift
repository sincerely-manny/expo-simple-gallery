enum ImageResizer {
  static func resize(image: UIImage, to targetSize: CGSize) -> UIImage {
    let size = image.size
    let widthRatio = targetSize.width / size.width
    let heightRatio = targetSize.height / size.height
    let scaleFactor = min(widthRatio, heightRatio)
    let scaledSize = CGSize(
      width: size.width * scaleFactor,
      height: size.height * scaleFactor
    )

    let renderer = UIGraphicsImageRenderer(size: scaledSize)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: scaledSize))
    }
  }
}
