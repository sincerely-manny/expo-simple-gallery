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

  func configure(with uri: String, index: Int, overlayHierarchy: [Int: UIView]?) {
    cellIndex = index

    // Configure image
    imageLoadTask?.cancel()
    guard let url = URL(string: uri) else { return }
    let targetSize = CGSize(
      width: bounds.width * UIScreen.main.scale,
      height: bounds.height * UIScreen.main.scale
    )
    imageLoadTask = imageLoader.loadImage(url: url, targetSize: targetSize) { [weak self] image in
      self?.imageView.image = image
    }

    // Configure overlay with safety check
    if let hierarchy = overlayHierarchy {
      safeConfigureOverlay(with: hierarchy)
    }
  }

  private func safeConfigureOverlay(with viewHierarchy: [Int: UIView]) {
    // Check if we already have this view mounted
    if let (key, view) = viewHierarchy.first {
      if currentOverlayKey == key && mountedViews[key] === view {
        // View is already mounted correctly
        return
      }

      // Check if view is already mounted somewhere
      if view.superview != nil {
        // View is mounted elsewhere, skip mounting
        return
      }
    }

    // Safe to proceed with mounting
    configureOverlay(with: viewHierarchy)
  }

  func configureOverlay(with viewHierarchy: [Int: UIView]) {
    // Clear existing overlay first
    clearCurrentOverlay()

    // Mount new overlay
    if let (key, view) = viewHierarchy.first {
      guard view.superview == nil else { return }

      overlayContainer.mountChildComponentView(view, index: 0)
      mountedViews[key] = view
      currentOverlayKey = key

      view.frame = overlayContainer.bounds
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

      overlayContainer.setNeedsLayout()
      overlayContainer.layoutIfNeeded()
    }
  }

  private func clearCurrentOverlay() {
    if let currentKey = currentOverlayKey,
      let view = mountedViews[currentKey],
      view.superview === overlayContainer
    {
      overlayContainer.unmountChildComponentView(view, index: 0)
    }
    mountedViews.removeAll()
    currentOverlayKey = nil
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
    imageLoadTask?.cancel()
    clearCurrentOverlay()
    cellIndex = nil
  }
}
