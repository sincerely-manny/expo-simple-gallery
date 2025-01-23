import ExpoModulesCore

final class GalleryCell: UICollectionViewCell {
  static let identifier = "GalleryCell"
  private let imageView = UIImageView()
  private let overlayContainer: ExpoView
  private var imageLoadTask: Cancellable?
  private var imageLoader: ImageLoaderProtocol
  private var mountedViews = [Int: UIView]()
  private var currentOverlayView: UIView?
  private var currentOverlayIndex: Int?
  private var currentOverlayKey: Int?

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

    // Debug: Print frame after layout
    DispatchQueue.main.async {
      print("OverlayContainer frame: \(self.overlayContainer.frame)")
      print("OverlayContainer bounds: \(self.overlayContainer.bounds)")
    }
  }

  func setBorderRadius(_ radius: CGFloat) {
    contentView.layer.cornerRadius = radius
    contentView.layer.masksToBounds = true
  }

  func configure(with uri: String) {
    imageLoadTask?.cancel()

    guard let url = URL(string: uri) else { return }
    let targetSize = CGSize(
      width: bounds.width * UIScreen.main.scale,
      height: bounds.height * UIScreen.main.scale
    )

    imageLoadTask = imageLoader.loadImage(url: url, targetSize: targetSize) { [weak self] image in
      self?.imageView.image = image
    }
  }

  func configureOverlay(with viewHierarchy: [Int: UIView]) {
    // If we have the same overlay, do nothing
    if let currentKey = currentOverlayKey,
      viewHierarchy[currentKey] != nil
    {
      return
    }

    // Clear any existing overlay
    if let currentKey = currentOverlayKey {
      // Only unmount if the view is still in our hierarchy
      if let existingView = mountedViews[currentKey],
        existingView.superview === overlayContainer
      {
        overlayContainer.unmountChildComponentView(existingView, index: 0)
      }
      mountedViews.removeValue(forKey: currentKey)
      currentOverlayKey = nil
    }

    // Mount new overlay if available
    if let (key, view) = viewHierarchy.first {
      // Only mount if the view isn't already mounted somewhere
      if view.superview == nil {
        overlayContainer.mountChildComponentView(view, index: 0)
        mountedViews[key] = view
        currentOverlayKey = key
      }
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
    imageLoadTask?.cancel()

    // Clear overlay
    if let currentKey = currentOverlayKey,
      let view = mountedViews[currentKey],
      view.superview === overlayContainer
    {
      overlayContainer.unmountChildComponentView(view, index: 0)
    }
    mountedViews.removeAll()
    currentOverlayKey = nil
  }

  deinit {
    // Ensure cleanup
    if let currentKey = currentOverlayKey,
      let view = mountedViews[currentKey],
      view.superview === overlayContainer
    {
      overlayContainer.unmountChildComponentView(view, index: 0)
    }
  }
}
