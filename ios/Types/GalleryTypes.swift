struct ReactMountingComponent {
  let view: UIView
  let index: Int
}

struct GalleryConfiguration {
  var columns: Int = 3
  var spacing: CGFloat = 0
  var imageAspectRatio: CGFloat = 1
  var borderRadius: CGFloat = 0
  var borderWidth: CGFloat = 0
  var borderColor: UIColor?
  var padding: UIEdgeInsets = .zero
}

enum ThumbnailPressAction { case select, open, preview, none }
