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
  private var currentImageURL: URL?
  private var placeholderView: UIView?

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
    cellIndex = index

    // Clear current image and show placeholder
    imageView.image = nil
    showPlaceholder()

    // Cancel any pending image load
    imageLoadTask?.cancel()
    imageLoadTask = nil

    // Configure new image load
    guard let url = URL(string: uri) else { return }

    // Only load if URL changed
    if currentImageURL != url {
      currentImageURL = url
      let targetSize = CGSize(
        width: bounds.width * UIScreen.main.scale,
        height: bounds.height * UIScreen.main.scale
      )

      imageLoadTask = imageLoader.loadImage(url: url, targetSize: targetSize) { [weak self] image in
        guard let self = self,
          self.currentImageURL == url
        else { return }

        self.imageView.image = image
        self.hidePlaceholder()
      }
    }

    // Configure overlay
    if let hierarchy = overlayHierarchy {
      safeConfigureOverlay(with: hierarchy)
    }
  }

  private func showPlaceholder() {
    if placeholderView == nil {
      let placeholder = UIView()
      placeholder.backgroundColor = .systemGray6
      placeholder.translatesAutoresizingMaskIntoConstraints = false
      contentView.insertSubview(placeholder, belowSubview: overlayContainer)

      NSLayoutConstraint.activate([
        placeholder.topAnchor.constraint(equalTo: contentView.topAnchor),
        placeholder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        placeholder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        placeholder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])

      placeholderView = placeholder
    }
    placeholderView?.isHidden = false
  }

  private func hidePlaceholder() {
    placeholderView?.isHidden = true
  }

  private func safeConfigureOverlay(with viewHierarchy: [Int: UIView]) {
    guard cellIndex != nil else { return }

    // Check if we already have this view mounted
    if let (key, view) = viewHierarchy.first {
      if currentOverlayKey == key && mountedViews[key] === view { return }

      // Only skip if the view is mounted in ANOTHER cell's overlay container
      if let currentSuperview = view.superview as? ExpoView,
        currentSuperview !== overlayContainer
      {
        // Force unmount from previous container
        if let previousContainer = view.superview as? ExpoView {
          previousContainer.unmountChildComponentView(view, index: 0)
        }
      }
    }

    configureOverlay(with: viewHierarchy)
  }

  func configureOverlay(with viewHierarchy: [Int: UIView]) {
    guard cellIndex != nil else { return }

    // Clear existing overlay first
    clearCurrentOverlay()

    // Mount new overlay
    if let (key, view) = viewHierarchy.first {
      // Remove from previous superview if needed
      if let previousSuperview = view.superview as? ExpoView {
        previousSuperview.unmountChildComponentView(view, index: 0)
      }

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
    guard cellIndex != nil else { return }

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
    currentImageURL = nil
    imageLoadTask?.cancel()
    imageLoadTask = nil
    showPlaceholder()
    clearCurrentOverlay()
    cellIndex = nil
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Ensure proper z-index ordering
    if let placeholder = placeholderView {
      contentView.sendSubviewToBack(placeholder)
    }
    contentView.sendSubviewToBack(imageView)
  }
}
