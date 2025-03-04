import ExpoModulesCore
import Photos
import UIKit

class ImagePageViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let imageView = UIImageView()
  private let activityIndicator = UIActivityIndicatorView(style: .large)
  private var panGesture: UIPanGestureRecognizer!
  private var initialScrollViewContentOffset = CGPoint.zero
  weak var delegate: ImagePageViewControllerDelegate?
  private var imageCache: NSCache<NSString, UIImage>?

  private(set) var index: Int = 0
  private var currentUri: String = ""
  private var hasLoadedHighQuality = false
  private var isDraggingDown = false
  private var initialTouchPoint = CGPoint.zero
  private var highQualityRequestID: PHImageRequestID?
  private var lowQualityRequestID: PHImageRequestID?
  private var isViewVisible = false

  override func viewDidLoad() {
    super.viewDidLoad()
    setupScrollView()
    setupActivityIndicator()
    setupGestures()
  }

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

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.frame = view.bounds
    updateImageViewFrame()
    activityIndicator.center = view.center
  }

  // Reset zoom when reused and track visibility
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    scrollView.zoomScale = 1.0
    isViewVisible = true

    // If we have a thumbnail but not high quality, resume loading high quality
    if !hasLoadedHighQuality && imageView.image != nil && currentUri.hasPrefix("ph://") {
      let assetID = currentUri.replacingOccurrences(of: "ph://", with: "")
      let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

      if let asset = assetResults.firstObject {
        fetchHighQualityImage(for: asset)
      }
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    isViewVisible = false
  }

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

    if uri.hasPrefix("file://"), let url = URL(string: uri) {
      let cacheKey = (uri as NSString)
      if let cachedImage = imageCache.object(forKey: cacheKey) {
        imageView.image = cachedImage
        hasLoadedHighQuality = true  // File images are always "high quality"
      } else {
        if let image = UIImage(contentsOfFile: url.path) {
          imageView.image = image
          imageCache.setObject(image, forKey: cacheKey)
          hasLoadedHighQuality = true  // File images are always "high quality"
        }
      }
      updateImageViewFrame()
    } else if uri.hasPrefix("ph://") {
      let thumbnailCacheKey = (uri + "_thumbnail" as NSString)
      let highQualityCacheKey = (uri as NSString)

      if let highQualityImage = imageCache.object(forKey: highQualityCacheKey) {
        imageView.image = highQualityImage
        updateImageViewFrame()
        hasLoadedHighQuality = true
      } else if let thumbnailImage = imageCache.object(forKey: thumbnailCacheKey) {
        imageView.image = thumbnailImage
        updateImageViewFrame()
        if !hasHighQuality {
          let assetID = uri.replacingOccurrences(of: "ph://", with: "")
          let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

          if let asset = assetResults.firstObject, isViewVisible {
            fetchHighQualityImage(for: asset)
          }
        } else {
          hasLoadedHighQuality = true
        }
      } else {
        fetchPHAsset(uri: uri, loadThumbnailFirst: true)
      }
    }
  }

  private func fetchPHAsset(uri: String, loadThumbnailFirst: Bool) {
    let assetID = uri.replacingOccurrences(of: "ph://", with: "")
    let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

    guard let asset = assetResults.firstObject else {
      showErrorPlaceholder(message: "Asset not found")
      return
    }

    activityIndicator.startAnimating()

    // Add a safety timeout - especially important for simulators
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
      guard let self = self, self.imageView.image == nil else { return }
      self.activityIndicator.stopAnimating()
      let assetDimensions = "\(asset.pixelWidth) × \(asset.pixelHeight)"
      self.showErrorPlaceholder(
        message: "Simulator cannot load this image\n\nAsset ID: \(assetID)\nDimensions: \(assetDimensions)")
    }

    let thumbnailOptions = PHImageRequestOptions()
    thumbnailOptions.isNetworkAccessAllowed = true
    thumbnailOptions.resizeMode = .fast
    thumbnailOptions.isSynchronous = false
    thumbnailOptions.version = .current
    thumbnailOptions.isNetworkAccessAllowed = true
    thumbnailOptions.deliveryMode = .opportunistic

    // Cancel any pending thumbnail request
    if let previousRequestID = lowQualityRequestID {
      PHImageManager.default().cancelImageRequest(previousRequestID)
    }

    lowQualityRequestID = PHImageManager.default().requestImage(
      for: asset,
      targetSize: CGSize(width: 300, height: 300),
      contentMode: .aspectFit,
      options: thumbnailOptions
    ) { [weak self] image, info in
      guard let self = self else { return }

      if let error = info?[PHImageErrorKey] {
        DispatchQueue.main.async {
          self.activityIndicator.stopAnimating()
          self.showErrorPlaceholder(message: "Cannot load image\nError: \(error)")
        }
        return
      }

      guard let image = image else {
        return
      }

      DispatchQueue.main.async {
        if let cache = self.imageCache {
          let thumbnailCacheKey = (self.currentUri + "_thumbnail" as NSString)
          cache.setObject(image, forKey: thumbnailCacheKey)
        }
        self.imageView.image = image
        self.updateImageViewFrame()

        if self.isViewVisible {
          self.fetchHighQualityImage(for: asset)
        }
      }
    }
  }

  private func showErrorPlaceholder(message: String) {
    DispatchQueue.main.async {
      self.activityIndicator.stopAnimating()

      // Create a placeholder image
      let size = CGSize(width: 300, height: 300)
      UIGraphicsBeginImageContextWithOptions(size, false, 0)
      let context = UIGraphicsGetCurrentContext()!

      // Draw background
      context.setFillColor(UIColor.darkGray.cgColor)
      context.fill(CGRect(origin: .zero, size: size))

      // Draw border
      context.setStrokeColor(UIColor.lightGray.cgColor)
      context.setLineWidth(2)
      context.stroke(CGRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2))

      // Add image icon
      let iconRect = CGRect(x: size.width / 2 - 40, y: size.height / 2 - 60, width: 80, height: 80)
      context.setStrokeColor(UIColor.white.cgColor)
      context.setLineWidth(3)

      // Draw simple image icon
      context.stroke(iconRect)
      context.move(to: CGPoint(x: iconRect.minX + 20, y: iconRect.minY + 20))
      context.addLine(to: CGPoint(x: iconRect.maxX - 20, y: iconRect.maxY - 20))
      context.move(to: CGPoint(x: iconRect.maxX - 20, y: iconRect.minY + 20))
      context.addLine(to: CGPoint(x: iconRect.minX + 20, y: iconRect.maxY - 20))
      context.strokePath()

      // Add error text
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center
      paragraphStyle.lineBreakMode = .byWordWrapping

      let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14),
        .foregroundColor: UIColor.white,
        .paragraphStyle: paragraphStyle,
      ]

      let textRect = CGRect(
        x: 10,
        y: size.height / 2 + 40,
        width: size.width - 20,
        height: size.height / 2 - 50
      )

      message.draw(in: textRect, withAttributes: attributes)

      let placeholderImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      // Display the placeholder
      self.imageView.image = placeholderImage
      self.updateImageViewFrame()

      // Add a label with more detailed error info
      let label = UILabel(frame: self.view.bounds)
      label.numberOfLines = 0
      label.textAlignment = .center
      label.textColor = .white
      label.font = UIFont.systemFont(ofSize: 14)
      label.text = "This is a simulator limitation.\nReal devices should work properly."
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

  private func fetchHighQualityImage(for asset: PHAsset) {
    if hasLoadedHighQuality {
      activityIndicator.stopAnimating()
      return
    }

    activityIndicator.startAnimating()

    let options = PHImageRequestOptions()

    #if targetEnvironment(simulator)
      options.deliveryMode = .opportunistic
    #else
      options.deliveryMode = .highQualityFormat
    #endif

    options.isNetworkAccessAllowed = true
    options.isSynchronous = false

    options.progressHandler = { [weak self] (progress, _, _, _) in
      DispatchQueue.main.async {
        if progress >= 1.0 {
          self?.activityIndicator.stopAnimating()
        }
      }
    }

    // Cancel any previous high-quality request
    if let previousRequestID = highQualityRequestID {
      PHImageManager.default().cancelImageRequest(previousRequestID)
    }

    highQualityRequestID = PHImageManager.default().requestImage(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .aspectFit,
      options: options
    ) { [weak self] image, info in
      guard let self = self, let image = image else {
        return
      }

      // Only proceed if this is the final image (not a placeholder)
      if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
        return
      }

      DispatchQueue.main.async {
        // Cache the high quality image
        if let cache = self.imageCache {
          let highQualityCacheKey = (self.currentUri as NSString)
          cache.setObject(image, forKey: highQualityCacheKey)
        }

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
          })
      }
    }
  }

  private func updateImageViewFrame() {
    guard let image = imageView.image else {
      return
    }

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
    centerScrollViewContents()

  }

  @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
    // Toggle UI visibility if needed
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
        delegate?.imagePageViewControllerDidRequestDismiss(self)
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

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // Cancel any pending image requests
    if let requestID = highQualityRequestID {
      PHImageManager.default().cancelImageRequest(requestID)
    }
  }
}

// MARK: - UIScrollViewDelegate
extension ImagePageViewController: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    // Center the image in the scroll view when zooming
    centerScrollViewContents()
  }

  private func centerScrollViewContents() {
    let boundsSize = scrollView.bounds.size
    var contentFrame = imageView.frame

    // Center horizontally
    if contentFrame.size.width < boundsSize.width {
      contentFrame.origin.x = (boundsSize.width - contentFrame.size.width) / 2.0
    } else {
      contentFrame.origin.x = 0
    }

    // Center vertically
    if contentFrame.size.height < boundsSize.height {
      contentFrame.origin.y = (boundsSize.height - contentFrame.size.height) / 2.0
    } else {
      contentFrame.origin.y = 0
    }

    imageView.frame = contentFrame
  }
}

// MARK: - UIGestureRecognizerDelegate
extension ImagePageViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer === panGesture {
      if scrollView.zoomScale > scrollView.minimumZoomScale {
        return false
      }

      let velocity = panGesture.velocity(in: view)
      let isScrolledToTop = scrollView.contentOffset.y <= 0
      let isMainlyVertical = abs(velocity.y) > abs(velocity.x) * 1.5

      return isScrolledToTop && velocity.y > 0 && isMainlyVertical
    }
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    // Allow simultaneous recognition with scrollView's pan gesture
    if gestureRecognizer === panGesture && otherGestureRecognizer === scrollView.panGestureRecognizer {
      return true
    }

    if otherGestureRecognizer.view?.next is UIPageViewController {
      let velocity = panGesture.velocity(in: view)

      // If the gesture has a significant horizontal component, let the page view controller handle it
      if abs(velocity.x) > abs(velocity.y) * 0.8 {
        return false  // Don't recognize our gesture, let page controller take it
      }
    }

    return false
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    // Let page view controller's gesture recognizer take priority for horizontal swipes
    if gestureRecognizer === panGesture && otherGestureRecognizer.view?.next is UIPageViewController {
      let velocity = panGesture.velocity(in: view)
      return abs(velocity.x) > abs(velocity.y) * 0.8
    }
    return false
  }
}

protocol ImagePageViewControllerDelegate: AnyObject {
  func imagePageViewControllerDidRequestDismiss(_ controller: ImagePageViewController)
  func imagePageViewController(_ controller: ImagePageViewController, didLoadHighQualityImage uri: String)
}
