import ExpoModulesCore

protocol PhotoCellViewDelegate: AnyObject {
  func photoCell(_ cell: PhotoCellView, didUpdateOverlay overlay: UIView?)
}

final class PhotoCellView: UIView {
  private let imageView = UIImageView()
  public let overlayContainer: ExpoView
  private weak var overlayView: UIView?
  private var imageLoadTask: Cancellable?

  weak var delegate: PhotoCellViewDelegate?

  override init(frame: CGRect) {
    overlayContainer = ExpoView(appContext: nil)
    super.init(frame: frame)
    //    overlayContainer = ExpoView(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    setupImageView()
    setupOverlayContainer()
    setupConstraints()
  }

  private func setupImageView() {
    addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.minificationFilter = .trilinear
    imageView.layer.shouldRasterize = true
    imageView.layer.rasterizationScale = UIScreen.main.scale
  }

  private func setupOverlayContainer() {
    //    guard let overlayContainer else { return }
    addSubview(overlayContainer)
    overlayContainer.translatesAutoresizingMaskIntoConstraints = false
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: topAnchor),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

      //      overlayContainer.topAnchor.constraint(equalTo: topAnchor),
      //      overlayContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
      //      overlayContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
      //      overlayContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  func configure(with uri: String, imageLoader: ImageLoaderProtocol) {
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

  func setOverlay(_ overlay: UIView?) {
    // First unmount any existing overlay
    if let existingOverlay = overlayView {
      overlayContainer.unmountChildComponentView(existingOverlay, index: 0)
    }

    // Mount new overlay if provided
    if let overlay = overlay {
      overlayContainer.mountChildComponentView(overlay, index: 0)
      overlayView = overlay
    }
  }

  func clearOverlay() {
    if let existingOverlay = overlayView {
      overlayContainer.unmountChildComponentView(existingOverlay, index: 0)
    }
  }

  func prepareForReuse() {
    clearOverlay()
    imageView.image = nil
  }
}
