import ExpoModulesCore

final class GalleryCell: UICollectionViewCell {
  static let identifier = "GalleryCell"
  private let imageView = UIImageView()
  private let overlayContainer: ExpoView
  private var imageLoadTask: Cancellable?
  private var imageLoader: ImageLoaderProtocol
  private var mountedViews = [Int: UIView]()
  private var currentOverlayKey: Int?
  private var isConfiguring = false
  var cellIndex: Int?

  override init(frame: CGRect) {
    imageLoader = ImageLoader()
    overlayContainer = ExpoView(appContext: nil)
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    // Setup imageView
    contentView.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true

    // Setup overlayContainer
    contentView.addSubview(overlayContainer)
    overlayContainer.translatesAutoresizingMaskIntoConstraints = false
    overlayContainer.isUserInteractionEnabled = true
    overlayContainer.isOpaque = true

    // Force a specific size if needed
    //    overlayContainer.layer.zPosition = 999  // Ensure it's above other views

    // Debug: Add border to see bounds
    //    overlayContainer.layer.borderWidth = 2
    //    overlayContainer.layer.borderColor = UIColor.yellow.cgColor
    //    overlayContainer.layer.backgroundColor = UIColor.red.withAlphaComponent(0.5).cgColor

    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      overlayContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
      overlayContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      overlayContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      overlayContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  func setBorderRadius(_ radius: CGFloat) {
    contentView.layer.cornerRadius = radius
    contentView.layer.masksToBounds = true
  }

  func configure(with uri: String, index: Int, overlayHierarchy: [Int: UIView]?) {
    print("### Cell \(index): Starting configuration")
    cellIndex = index

    // Configure image
    imageLoadTask?.cancel()
    guard let url = URL(string: uri) else { return }
    let targetSize = CGSize(
      width: bounds.width * UIScreen.main.scale,
      height: bounds.height * UIScreen.main.scale
    )
    imageLoadTask = imageLoader.loadImage(url: url, targetSize: targetSize) { [weak self] image in
      print("### Cell \(index): Image loaded")
      self?.imageView.image = image
    }

    // Configure overlay with safety check
    if let hierarchy = overlayHierarchy {
      print("### Cell \(index): Overlay hierarchy available with keys:", hierarchy.keys)
      safeConfigureOverlay(with: hierarchy)
    } else {
      print("### Cell \(index): No overlay hierarchy provided")
    }
  }

  private func safeConfigureOverlay(with viewHierarchy: [Int: UIView]) {
    guard let cellIdx = cellIndex else {
      print("### Cell: Unknown index during safe configure")
      return
    }

    // Check if we already have this view mounted
    if let (key, view) = viewHierarchy.first {
      print("### Cell \(cellIdx): Checking view with key \(key)")

      if currentOverlayKey == key && mountedViews[key] === view {
        print("### Cell \(cellIdx): View already correctly mounted in this cell")
        return
      }

      // Only skip if the view is mounted in ANOTHER cell's overlay container
      if let currentSuperview = view.superview as? ExpoView,
        currentSuperview !== overlayContainer
      {
        print("### Cell \(cellIdx): View is mounted in another cell, force unmounting")
        // Force unmount from previous container
        if let previousContainer = view.superview as? ExpoView {
          previousContainer.unmountChildComponentView(view, index: 0)
        }
      }

      print("### Cell \(cellIdx): Proceeding with mount")
    }

    configureOverlay(with: viewHierarchy)
  }

  func configureOverlay(with viewHierarchy: [Int: UIView]) {
    guard let cellIdx = cellIndex else {
      print("### Cell: Unknown index during configure")
      return
    }

    print("### Cell \(cellIdx): Starting overlay configuration")
    print("### Cell \(cellIdx): Current overlay key:", currentOverlayKey ?? "none")

    // Clear existing overlay first
    clearCurrentOverlay()

    // Mount new overlay
    if let (key, view) = viewHierarchy.first {
      print("### Cell \(cellIdx): Attempting to mount view with key \(key)")

      // Remove from previous superview if needed
      if let previousSuperview = view.superview as? ExpoView {
        print("### Cell \(cellIdx): Removing view from previous container")
        previousSuperview.unmountChildComponentView(view, index: 0)
      }

      print("### Cell \(cellIdx): Mounting view")
      overlayContainer.mountChildComponentView(view, index: 0)
      mountedViews[key] = view
      currentOverlayKey = key

      view.frame = overlayContainer.bounds
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

      overlayContainer.setNeedsLayout()
      overlayContainer.layoutIfNeeded()
      print("### Cell \(cellIdx): Overlay mounted and positioned")
    }
  }

  private func clearCurrentOverlay() {
    guard let cellIdx = cellIndex else {
      print("### Cell: Unknown index during clear")
      return
    }

    print("### Cell \(cellIdx): Clearing current overlay")
    if let currentKey = currentOverlayKey {
      print("### Cell \(cellIdx): Found current key:", currentKey)
      if let view = mountedViews[currentKey] {
        if view.superview === overlayContainer {
          print("### Cell \(cellIdx): Unmounting view")
          overlayContainer.unmountChildComponentView(view, index: 0)
        } else {
          print("### Cell \(cellIdx): View not in overlay container")
        }
      } else {
        print("### Cell \(cellIdx): No view found for key")
      }
    } else {
      print("### Cell \(cellIdx): No current key to clear")
    }
    mountedViews.removeAll()
    currentOverlayKey = nil
  }

  override func prepareForReuse() {
    print("### Cell \(cellIndex ?? -1): Preparing for reuse")
    super.prepareForReuse()
    imageView.image = nil
    imageLoadTask?.cancel()
    clearCurrentOverlay()
    cellIndex = nil
  }
}
