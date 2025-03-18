import AVFoundation
import ExpoModulesCore
import Photos

final class GalleryCell: UICollectionViewCell, OverlayContainer {
  static let identifier = "GalleryCell"
  var cellIndex: Int?
  var cellUri: String?
  var containerIdentifier: Int? { return cellIndex }

  weak var overlayMountingDelegate: OverlayMountingDelegate?
  let overlayContainer: ExpoView
  private let imageView = UIImageView()
  private let mediaTypeIndicatorView = UIImageView()
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

    // Setup media type indicator view
    contentView.addSubview(mediaTypeIndicatorView)
    mediaTypeIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    mediaTypeIndicatorView.contentMode = .scaleAspectFit
    mediaTypeIndicatorView.tintColor = .white

    mediaTypeIndicatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
    mediaTypeIndicatorView.layer.cornerRadius = 12
    mediaTypeIndicatorView.clipsToBounds = true

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

      // Position indicator in bottom right with padding
      mediaTypeIndicatorView.widthAnchor.constraint(equalToConstant: 24),
      mediaTypeIndicatorView.heightAnchor.constraint(equalToConstant: 24),
      mediaTypeIndicatorView.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor, constant: -8),
      mediaTypeIndicatorView.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor, constant: -8),
    ])

    imageView.alpha = 0
    mediaTypeIndicatorView.isHidden = true
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

    // Detect media type and update indicator
    detectAndUpdateMediaType(for: url)
  }

  private func detectAndUpdateMediaType(for url: URL) {
    // Reset indicator first
    mediaTypeIndicatorView.isHidden = true

    switch url.scheme {
    case "file":
      detectFileMediaType(url: url)
    case "ph":
      detectPhotoLibraryMediaType(url: url)
    default:
      mediaTypeIndicatorView.isHidden = true
    }
  }

  private func detectFileMediaType(url: URL) {
    let pathExtension = url.pathExtension.lowercased()
    let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv"]

    if videoExtensions.contains(pathExtension) {
      // It's a video file
      setVideoIndicator()
    } else {
      mediaTypeIndicatorView.isHidden = true
    }
  }

  private func detectPhotoLibraryMediaType(url: URL) {
    let assetID = url.absoluteString.replacingOccurrences(of: "ph://", with: "")
    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil).firstObject
    else {
      mediaTypeIndicatorView.isHidden = true
      return
    }

    switch asset.mediaType {
    case .video:
      setVideoIndicator()
    case .image:
      if #available(iOS 9.1, *) {
        if asset.mediaSubtypes.contains(.photoLive) {
          setLivePhotoIndicator()
        } else {
          mediaTypeIndicatorView.isHidden = true
        }
      } else {
        mediaTypeIndicatorView.isHidden = true
      }
    default:
      mediaTypeIndicatorView.isHidden = true
    }
  }

  private func setVideoIndicator() {
    mediaTypeIndicatorView.image = UIImage(systemName: "video.circle")
    mediaTypeIndicatorView.isHidden = false
  }

  private func setLivePhotoIndicator() {
    mediaTypeIndicatorView.image = UIImage(systemName: "livephoto")
    mediaTypeIndicatorView.isHidden = false
  }

  override func prepareForReuse() {
    overlayMountingDelegate?.unmount(from: self)
    super.prepareForReuse()
    currentImageURL = nil
    imageLoadTask?.cancel()
    imageLoadTask = nil
    cellIndex = nil
    imageView.alpha = 0
    mediaTypeIndicatorView.isHidden = true
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
    if !configuration.showMediaTypeIcon {
      mediaTypeIndicatorView.isHidden = true
    }
  }
}
