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
  var sectionInsets: UIEdgeInsets = .zero
  var sectionHeaderHeight: CGFloat = 40
  var showMediaTypeIcon: Bool = true
}

struct SectionInfo: Codable {
  let sectionIndex: Int
  let itemIndex: Int
}

enum ThumbnailPressAction { case select, open, preview, none }

class HorizontalPanGestureRecognizer: UIPanGestureRecognizer {}
