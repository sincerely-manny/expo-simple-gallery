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
  private var lastCalculatedSize: CGSize?

  private var thumbnailPressAction: ThumbnailPressAction = .open
  private var thumbnailLongPressAction: ThumbnailPressAction = .select

  override init(frame: CGRect) {
    imageLoader = ImageLoader()
    overlayContainer = ExpoView(frame: frame)
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
    overlayContainer.clipsToBounds = true
    overlayContainer.frame = bounds
    overlayContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  func configure(with uri: String, index: Int, overlayHierarchy: [Int: UIView]?) {
    cellIndex = index

    imageView.image = nil
    showPlaceholder()

    imageLoadTask?.cancel()
    imageLoadTask = nil

    guard let url = URL(string: uri) else { return }
    currentImageURL = url

    let targetSize = CGSize(width: bounds.width, height: bounds.height)

    imageLoadTask = imageLoader.loadImage(url: url, targetSize: targetSize) { [weak self] image in
      guard let self = self,
        self.currentImageURL == url
      else { return }

      DispatchQueue.main.async {
        self.imageView.image = image
        self.hidePlaceholder()
      }
    }

    if let hierarchy = overlayHierarchy {
      safeConfigureOverlay(with: hierarchy)
    }
  }

  private func showPlaceholder() {
//    if placeholderView == nil {
//      let placeholder = UIView()
//      placeholder.backgroundColor = .systemGray6
//      placeholder.translatesAutoresizingMaskIntoConstraints = false
//      contentView.insertSubview(placeholder, belowSubview: overlayContainer)
//
//      NSLayoutConstraint.activate([
//        placeholder.topAnchor.constraint(equalTo: contentView.topAnchor),
//        placeholder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//        placeholder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//        placeholder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//      ])
//
//      placeholderView = placeholder
//    }
//    placeholderView?.isHidden = false
  }

  private func hidePlaceholder() {
//    placeholderView?.isHidden = true
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

    clearCurrentOverlay()

    if let (key, view) = viewHierarchy.first {
      if let previousSuperview = view.superview as? ExpoView {
        previousSuperview.unmountChildComponentView(view, index: 0)
      }

      overlayContainer.mountChildComponentView(view, index: 0)
      mountedViews[key] = view
      currentOverlayKey = key

      view.setNeedsLayout()
      view.layoutIfNeeded()
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
//    imageView.image = nil
    currentImageURL = nil
    imageLoadTask?.cancel()
    imageLoadTask = nil
//    lastCalculatedSize = nil
//    showPlaceholder()
    clearCurrentOverlay()
    cellIndex = nil
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Check if size changed significantly
    if lastCalculatedSize != bounds.size {
      lastCalculatedSize = bounds.size
      // Reload image with new size if needed
      reloadImageIfNeeded()
    }

    // Update overlay frame
    if let currentKey = currentOverlayKey,
      let view = mountedViews[currentKey]
    {
      view.frame = overlayContainer.bounds
    }
  }

  private func reloadImageIfNeeded() {
    guard let currentURL = currentImageURL else { return }

    imageLoadTask?.cancel()
    imageLoadTask = nil

    let targetSize = CGSize(width: bounds.width, height: bounds.height)

    imageLoadTask = imageLoader.loadImage(url: currentURL, targetSize: targetSize) { [weak self] image in
      guard let self = self,
        self.currentImageURL == currentURL
      else { return }

      self.imageView.image = image
      self.hidePlaceholder()
    }
  }
}

extension GalleryCell {
  func applyStyle(configuration: GalleryConfiguration) {
    contentView.layer.cornerRadius = configuration.borderRadius
    contentView.layer.masksToBounds = true
    contentView.layer.borderWidth = configuration.borderWidth
    contentView.layer.borderColor = configuration.borderColor?.cgColor ?? nil
  }
}
