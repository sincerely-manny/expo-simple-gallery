import ExpoModulesCore

final class GalleryCell: UICollectionViewCell, OverlayContainer {
  static let identifier = "GalleryCell"
  var cellIndex: Int?
  var cellUri: String?
  var containerIdentifier: Int? { return cellIndex }

  weak var overlayMountingDelegate: OverlayMountingDelegate?
  let overlayContainer: ExpoView
  private let imageView = UIImageView()
  private var imageLoadTask: Cancellable?
  private var imageLoader: ImageLoaderProtocol
  private var currentImageURL: URL?

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
    contentView.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true

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

    imageView.alpha = 0
  }

  func configure(
    with uri: String, index: Int,
    withOverlayMountingDelegate overlayMountingDelegate: OverlayMountingDelegate
  ) {
    cellIndex = index
    cellUri = uri
    self.overlayMountingDelegate = overlayMountingDelegate
    overlayMountingDelegate.unmount(from: self)
    overlayMountingDelegate.mount(to: self)


    guard let url = URL(string: uri) else { return }
    currentImageURL = url
    if imageView.image == nil {
      imageView.alpha = 0
    }
    imageLoadTask?.cancel()
    imageLoadTask = nil
    let targetSize = CGSize(width: bounds.width, height: bounds.height)
    imageLoadTask = imageLoader.loadImage(url: url, targetSize: targetSize) { [weak self] image in
      guard let self = self,
        self.currentImageURL == url
      else { return }
      self.imageView.image = image
      UIView.animate(withDuration: 0.1) {
        self.imageView.alpha = 1
      }
    }
  }

  override func prepareForReuse() {
    overlayMountingDelegate?.unmount(from: self)
    super.prepareForReuse()
    currentImageURL = nil
    imageLoadTask?.cancel()
    imageLoadTask = nil
    cellIndex = nil
    imageView.alpha = 0
  }

  deinit {
    overlayMountingDelegate?.unmount(from: self)
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
