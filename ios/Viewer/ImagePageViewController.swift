import ExpoModulesCore
import Photos
import UIKit

class ImagePageViewController: UIViewController {
  // MARK: - Properties

  let scrollView = UIScrollView()
  let imageView = UIImageView()
  private let activityIndicator = UIActivityIndicatorView(style: .large)

  var panGesture: UIPanGestureRecognizer!
  private var initialScrollViewContentOffset = CGPoint.zero

  weak var delegate: ImagePageViewControllerDelegate?
  private var imageCache: NSCache<NSString, UIImage>?
  private var imageLoader: ImageLoaderService?

  private(set) var index: Int = 0
  private var currentUri: String = ""
  private var hasLoadedHighQuality = false
  private var isDraggingDown = false
  private var initialTouchPoint = CGPoint.zero
  private var isViewVisible = false

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupScrollView()
    setupActivityIndicator()
    setupGestures()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.frame = view.bounds
    updateImageViewFrame()
    activityIndicator.center = view.center
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    scrollView.zoomScale = 1.0
    isViewVisible = true

    // If we have a thumbnail but not high quality, resume loading high quality
    if !hasLoadedHighQuality && imageView.image != nil && currentUri.hasPrefix("ph://") {
      loadHighQualityImage()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    isViewVisible = false
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    imageLoader?.cancelRequests()
  }

  // MARK: - Setup Methods

  private func setupScrollView() {
    view.backgroundColor = .clear
    if view.bounds.isEmpty {
      let screenBounds = UIScreen.main.bounds
      scrollView.frame = screenBounds
    } else {
      scrollView.frame = view.bounds
    }

    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 3.0
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.bounces = true
    scrollView.alwaysBounceVertical = true
    scrollView.alwaysBounceHorizontal = true
    scrollView.isDirectionalLockEnabled = true
    view.addSubview(scrollView)

    imageView.contentMode = .scaleAspectFit
    imageView.frame = scrollView.bounds
    scrollView.addSubview(imageView)
  }

  private func setupActivityIndicator() {
    activityIndicator.color = .white
    activityIndicator.hidesWhenStopped = true
    view.addSubview(activityIndicator)
    activityIndicator.center = view.center
  }

  private func setupGestures() {
    // Double tap to zoom
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    view.addGestureRecognizer(doubleTapGesture)

    // Single tap to toggle UI
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
    singleTapGesture.numberOfTapsRequired = 1
    singleTapGesture.require(toFail: doubleTapGesture)
    view.addGestureRecognizer(singleTapGesture)

    // Pan gesture for dismissing
    panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    panGesture.delegate = self
    view.addGestureRecognizer(panGesture)
  }

  // MARK: - Public Methods

  func prepareForDismissal() {
    scrollView.zoomScale = 1.0
    centerScrollViewContents()
    let scaleTransform = CGAffineTransform(scaleX: 0.1, y: 0.1)
    UIView.animate(withDuration: 0.25) {
      self.imageView.transform = scaleTransform
    }
  }

  func configure(with uri: String, index: Int, imageCache: NSCache<NSString, UIImage>, hasHighQuality: Bool) {
    self.index = index
    self.currentUri = uri
    self.imageCache = imageCache
    self.hasLoadedHighQuality = hasHighQuality
    imageView.transform = .identity
    imageView.alpha = 1.0

    // Initialize the image loader
    self.imageLoader = ImageLoaderService(imageCache: imageCache)

    activityIndicator.startAnimating()

    // Add a safety timeout - especially important for simulators
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
      guard let self = self, self.imageView.image == nil else { return }
      self.activityIndicator.stopAnimating()
      self.showErrorPlaceholder(message: "Failed to load image within timeout")
    }

    // Load the image
    imageLoader?.loadImage(from: uri, loadThumbnailFirst: !hasHighQuality) { [weak self] image, error in
      guard let self = self else { return }

      DispatchQueue.main.async {
        if let error = error {
          self.activityIndicator.stopAnimating()
          self.showErrorPlaceholder(message: "Failed to load image: \(error.localizedDescription)")
          return
        }

        if let image = image {
          self.imageView.image = image
          self.updateImageViewFrame()

          // If this is a photo asset and we haven't loaded high quality yet, do that next
          if uri.hasPrefix("ph://") && !hasHighQuality && self.isViewVisible {
            self.loadHighQualityImage()
          } else {
            self.activityIndicator.stopAnimating()
          }
        }
      }
    }
  }

  // MARK: - Image Loading

  private func loadHighQualityImage() {
    guard let imageLoader = imageLoader, !hasLoadedHighQuality else {
      activityIndicator.stopAnimating()
      return
    }

    activityIndicator.startAnimating()

    imageLoader.loadHighQualityVersion(for: currentUri) { [weak self] image, error in
      guard let self = self, let image = image else {
        if error != nil {
          DispatchQueue.main.async {
            self?.activityIndicator.stopAnimating()
          }
        }
        return
      }

      DispatchQueue.main.async {
        // Mark as loaded so we don't try to load it again
        self.hasLoadedHighQuality = true
        self.delegate?.imagePageViewController(self, didLoadHighQualityImage: self.currentUri)

        // Apply a nice crossfade transition to the new high-quality image
        UIView.transition(
          with: self.imageView,
          duration: 0.3,
          options: .transitionCrossDissolve,
          animations: {
            self.imageView.image = image
          },
          completion: { _ in
            self.activityIndicator.stopAnimating()
            self.updateImageViewFrame()
          }
        )
      }
    }
  }

  private func showErrorPlaceholder(message: String) {
    DispatchQueue.main.async {
      self.activityIndicator.stopAnimating()

      let size = CGSize(width: 300, height: 300)
      if let placeholderImage = UIImage.errorPlaceholder(size: size, message: message) {
        self.imageView.image = placeholderImage
        self.updateImageViewFrame()
      }

      // Add a label with more detailed error info
      let label = UILabel(frame: self.view.bounds)
      label.numberOfLines = 0
      label.textAlignment = .center
      label.textColor = .white
      label.font = UIFont.systemFont(ofSize: 14)
      label.text = "This may be a simulator limitation.\nReal devices should work properly."
      label.backgroundColor = UIColor.black.withAlphaComponent(0.5)

      // Position at the bottom of the screen
      let height: CGFloat = 60
      label.frame = CGRect(
        x: 0,
        y: self.view.bounds.height - height - 20,
        width: self.view.bounds.width,
        height: height
      )

      self.view.addSubview(label)
    }
  }

  // MARK: - Image View Handling

  private func updateImageViewFrame() {
    guard let image = imageView.image else { return }

    let imageWidth = image.size.width
    let imageHeight = image.size.height

    let viewWidth = scrollView.bounds.width
    let viewHeight = scrollView.bounds.height

    let widthRatio = viewWidth / imageWidth
    let heightRatio = viewHeight / imageHeight

    // Use the smaller ratio to ensure the entire image is visible
    let minRatio = min(widthRatio, heightRatio)

    let scaledWidth = imageWidth * minRatio
    let scaledHeight = imageHeight * minRatio

    // Set the image frame
    let imageFrame = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
    imageView.frame = imageFrame
    scrollView.contentSize = imageFrame.size

    // Center the image
    self.centerScrollViewContents()
  }

  // MARK: - Gesture Handlers

  @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
    // Toggle UI visibility if needed
    // This could be used to hide/show navigation bars, etc.
  }

  @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
    if scrollView.zoomScale > scrollView.minimumZoomScale {
      scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
    } else {
      let point = gesture.location(in: imageView)
      let zoomRect = CGRect(
        x: point.x - (scrollView.bounds.width / 4),
        y: point.y - (scrollView.bounds.height / 4),
        width: scrollView.bounds.width / 2,
        height: scrollView.bounds.height / 2
      )
      scrollView.zoom(to: zoomRect, animated: true)
    }
  }

  @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
    guard scrollView.zoomScale == scrollView.minimumZoomScale else { return }

    let translation = gesture.translation(in: view)
    let velocity = gesture.velocity(in: view)

    switch gesture.state {
    case .began:
      initialTouchPoint = view.center
      initialScrollViewContentOffset = scrollView.contentOffset

      // Only enable downward dismiss if we're at the top of the content
      isDraggingDown = scrollView.contentOffset.y <= 50

    case .changed:
      guard isDraggingDown else { return }

      // Calculate vertical drag percentage
      let verticalDrag = translation.y
      let percentage = min(max(verticalDrag / 200.0, 0), 1)

      // Apply scale and translation
      let scale = 1 - percentage * 0.2  // Scale down to 80% at most
      view.transform = CGAffineTransform(scaleX: scale, y: scale)
        .translatedBy(x: 0, y: verticalDrag / 2)

    case .ended, .cancelled:
      guard isDraggingDown else { return }

      let verticalVelocity = velocity.y
      let verticalTranslation = translation.y

      // Determine if we should dismiss based on velocity or distance
      if verticalVelocity > 1000 || verticalTranslation > 100 {
        delegate?.mediaViewControllerDidRequestDismiss(self)
      } else {
        // Reset position and scale with animation
        UIView.animate(withDuration: 0.3) {
          self.view.transform = .identity
        }
      }

      isDraggingDown = false

    default:
      break
    }
  }
}
