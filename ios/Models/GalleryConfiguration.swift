struct GalleryConfiguration2 {
  var columns: Int = 3
  var imageAspectRatio: CGFloat = 1
  var spacing: CGFloat = 0
  var borderRadius: CGFloat = 0

  static var `default`: GalleryConfiguration {
    GalleryConfiguration()
  }
}
