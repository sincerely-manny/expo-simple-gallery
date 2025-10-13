import AVFoundation
import ExpoModulesCore
import Photos
import PhotosUI
import UIKit

class GalleryImageViewerView: ExpoView {
  private let imageCache = NSCache<NSString, UIImage>()
  private var highQualityLoadedURIs = Set<String>()
  var pageViewController: UIPageViewController
  var uris: [String] = []
  var currentIndex: Int = 0

  var onPageChange = EventDispatcher()
  var onImageLoaded = EventDispatcher()
  var onDismissAttempt = EventDispatcher()

  private var mediaTypeCache = [String: MediaType]()  // Cache the media type for each URI
  private var loadedLivePhotos = [String: PHLivePhoto]()  // Cache for loaded live photos
  private var loadedPlayerItems = [String: AVPlayerItem]()  // Cache for loaded video player items

  private var activeMediaViewController: UIViewController?

  required init(appContext: AppContext? = nil) {
    self.pageViewController = UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal,
      options: nil
    )

    super.init(appContext: appContext)
    clipsToBounds = true
    pageViewController.dataSource = self
    pageViewController.delegate = self
    pageViewController.view.frame = bounds

    addSubview(pageViewController.view)
    pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    imageCache.countLimit = 50

    setupPageViewControllerGestures()
  }

  func loadImages(uris: [String], startIndex: Int) {
    // Reset caches when loading new images
    mediaTypeCache.removeAll()
    loadedLivePhotos.removeAll()
    loadedPlayerItems.removeAll()

    self.uris = uris
    self.currentIndex = min(max(startIndex, 0), uris.count - 1)

    let uri = uris[currentIndex]
    let viewController = createAppropriateViewController(for: uri, at: currentIndex)

    pageViewController.setViewControllers(
      [viewController],
      direction: .forward,
      animated: false
    )

    onPageChange(["index": currentIndex, "uri": uri])
  }

  override func removeFromSuperview() {
    stopActiveMediaPlayback()
    // Clean up all resources
    imageCache.removeAllObjects()
    highQualityLoadedURIs.removeAll()
    mediaTypeCache.removeAll()

    // For live photos
    loadedLivePhotos.removeAll()

    // For videos, properly clean up player items
    for (_, playerItem) in loadedPlayerItems {
      NotificationCenter.default.removeObserver(
        self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    loadedPlayerItems.removeAll()

    super.removeFromSuperview()
  }

  func loadMediaViewController(at index: Int, completion: @escaping (UIViewController?) -> Void) {
    guard index >= 0 && index < uris.count else {
      completion(nil)
      return
    }

    let uri = uris[index]

    // For backward compatibility, create an image view controller directly if high quality is already loaded
    let hasHighQuality = highQualityLoadedURIs.contains(uri)
    if hasHighQuality {
      let viewController = ImagePageViewController()
      viewController.delegate = self
      viewController.configure(
        with: uri, index: index, imageCache: imageCache, hasHighQuality: true)
      completion(viewController)
      return
    }

    // Otherwise, use our media loader to determine the correct type
    let imageLoader = ImageLoaderService(imageCache: imageCache)
    imageLoader.loadMedia(from: uri) { [weak self] mediaResult, error in
      guard let self = self else { return }

      DispatchQueue.main.async {
        if let error = error {
          print("Error loading media: \(error)")
          // Fall back to image view controller for errors
          let viewController = ImagePageViewController()
          viewController.delegate = self
          viewController.configure(
            with: uri, index: index, imageCache: self.imageCache, hasHighQuality: false)
          completion(viewController)
          return
        }

        if let mediaResult = mediaResult {
          let viewController = MediaViewControllerFactory.createViewController(
            for: mediaResult,
            uri: uri,
            index: index,
            imageCache: self.imageCache,
            delegate: self
          )
          completion(viewController)
        } else {
          // Fall back to image view controller if we couldn't determine media type
          let viewController = ImagePageViewController()
          viewController.delegate = self
          viewController.configure(
            with: uri, index: index, imageCache: self.imageCache, hasHighQuality: false)
          completion(viewController)
        }
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    pageViewController.view.frame = bounds
  }

  func goToPageWithIndex(_ index: Int) {
    guard index >= 0 && index < uris.count else { return }

    // Stop any active media before programmatically changing pages
    stopActiveMediaPlayback()

    let uri = uris[index]
    let direction: UIPageViewController.NavigationDirection =
      index > currentIndex ? .forward : .reverse

    let viewController = createAppropriateViewController(for: uri, at: index)

    pageViewController.setViewControllers(
      [viewController],
      direction: direction,
      animated: true
    )

    currentIndex = index
    onPageChange(["index": currentIndex, "uri": uri])
  }

  private func getIndex(from viewController: UIViewController) -> Int? {
    if let imageVC = viewController as? ImagePageViewController {
      return imageVC.index
    } else if let livePhotoVC = viewController as? LivePhotoViewController {
      return livePhotoVC.index
    } else if let videoVC = viewController as? VideoViewController {
      return videoVC.index
    }
    return nil
  }

  private func stopActiveMediaPlayback() {
    if let videoVC = activeMediaViewController as? VideoViewController {
      // Stop video playback
      videoVC.pauseAndPrepareForReuse()
    } else if let livePhotoVC = activeMediaViewController as? LivePhotoViewController {
      // Stop live photo playback
      livePhotoVC.stopPlaybackAndPrepareForReuse()
    }

    // Clear the reference
    activeMediaViewController = nil
  }
}

// MARK: - UIPageViewControllerDataSource
extension GalleryImageViewerView: UIPageViewControllerDataSource {
  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    guard let index = getIndex(from: viewController) else { return nil }
    let previousIndex = index - 1

    // Check bounds
    guard previousIndex >= 0 else { return nil }

    // For immediate response, create the appropriate view controller
    let uri = uris[previousIndex]
    let previousViewController = createAppropriateViewController(for: uri, at: previousIndex)

    // Pre-load the media type for the page before this one if not already determined
    if previousIndex > 0 {
      let prevPrevUri = uris[previousIndex - 1]
      if mediaTypeCache[prevPrevUri] == nil {
        preloadMediaType(for: prevPrevUri)
      }
    }

    return previousViewController
  }

  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerAfter viewController: UIViewController
  ) -> UIViewController? {
    guard let index = getIndex(from: viewController) else { return nil }
    let nextIndex = index + 1

    // Check bounds
    guard nextIndex < uris.count else { return nil }

    // For immediate response, create the appropriate view controller
    let uri = uris[nextIndex]
    let nextViewController = createAppropriateViewController(for: uri, at: nextIndex)

    // Pre-load the media type for the page after this one if not already determined
    if nextIndex < uris.count - 1 {
      let nextNextUri = uris[nextIndex + 1]
      if mediaTypeCache[nextNextUri] == nil {
        preloadMediaType(for: nextNextUri)
      }
    }

    return nextViewController
  }

  private func preloadMediaType(for uri: String) {
    DispatchQueue.global(qos: .userInitiated).async {
      let imageLoader = ImageLoaderService(imageCache: self.imageCache)
      imageLoader.determineMediaType(from: uri) { [weak self] mediaType, _ in
        if let mediaType = mediaType, let self = self {
          DispatchQueue.main.async {
            self.mediaTypeCache[uri] = mediaType
          }
        }
      }
    }
  }

  private func createAppropriateViewController(for uri: String, at index: Int) -> UIViewController {
    // Stop any active media before creating a new one
    stopActiveMediaPlayback()

    // Special case for file:// videos - handle them directly
    if uri.hasPrefix("file://") {
      let fileExtension = URL(string: uri)?.pathExtension.lowercased() ?? ""
      if ["mov", "mp4", "m4v", "avi", "mkv"].contains(fileExtension) {
        // Create a video view controller directly
        let videoVC = VideoViewController()
        videoVC.delegate = self

        // Create a URL and player item
        if let url = URL(string: uri) {
          let playerItem = AVPlayerItem(url: url)
          videoVC.configure(with: playerItem, uri: uri, index: index)

          // Store this as the active media controller
          self.activeMediaViewController = videoVC

          // Also add an activity indicator to show while the video loads
          let activityIndicator = UIActivityIndicatorView(style: .large)
          activityIndicator.color = .white
          activityIndicator.center = videoVC.view.center
          activityIndicator.autoresizingMask = [
            .flexibleLeftMargin, .flexibleRightMargin,
            .flexibleTopMargin, .flexibleBottomMargin,
          ]
          videoVC.view.addSubview(activityIndicator)
          activityIndicator.startAnimating()

          // Hide the indicator after a short delay to give video time to load
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
          }

          // Cache this in our loaded items dictionary
          self.loadedPlayerItems[uri] = playerItem
          self.mediaTypeCache[uri] = .video
        }

        return videoVC
      }
    }

    // First check if we already have the specialized media loaded and cached
    if let mediaType = mediaTypeCache[uri] {
      if mediaType == .livePhoto, let livePhoto = loadedLivePhotos[uri] {
        let viewController = LivePhotoViewController()
        viewController.configure(with: livePhoto, uri: uri, index: index)
        viewController.delegate = self
        activeMediaViewController = viewController  // Track the new active controller
        return viewController
      } else if mediaType == .video,
        let playerItem = loadedPlayerItems[uri]?.copy() as? AVPlayerItem
      {
        let viewController = VideoViewController()
        viewController.configure(with: playerItem, uri: uri, index: index)
        viewController.delegate = self
        activeMediaViewController = viewController  // Track the new active controller
        return viewController
      }
    }

    // If we reach here, we either don't know the media type yet or don't have the media loaded
    // Start with an image view controller while we determine the type and load content
    let hasHighQuality = highQualityLoadedURIs.contains(uri)
    let viewController = ImagePageViewController()
    viewController.delegate = self
    viewController.configure(
      with: uri, index: index, imageCache: imageCache, hasHighQuality: hasHighQuality)

    // Immediately start the media detection and loading process
    loadMediaForPageAndReplace(uri: uri, index: index, currentViewController: viewController)

    return viewController
  }

  private func loadMediaForPageAndReplace(
    uri: String, index: Int, currentViewController: UIViewController
  ) {
    // Skip if we already know this is a regular image
    if let mediaType = mediaTypeCache[uri], mediaType == .image {
      return
    }

    // Create a loader for this media
    let imageLoader = ImageLoaderService(imageCache: imageCache)

    // First determine the media type
    DispatchQueue.global(qos: .userInitiated).async { [weak self, weak currentViewController] in
      guard let self = self else { return }

      imageLoader.determineMediaType(from: uri) { [weak self] mediaType, _ in
        guard let self = self, let mediaType = mediaType else { return }

        DispatchQueue.main.async {
          // Cache the media type regardless of what it is
          self.mediaTypeCache[uri] = mediaType

          // For regular images, we're done - the ImagePageViewController handles them well
          if mediaType == .image {
            return
          }

          // For live photos and videos, we need to load the actual content
          DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            imageLoader.loadMedia(from: uri) {
              [weak self, weak currentViewController] mediaResult, error in
              guard
                let self = self,
                let mediaResult = mediaResult,
                let currentViewController = currentViewController
              else { return }

              DispatchQueue.main.async {
                // Cache the results based on type
                if let livePhoto = mediaResult.livePhoto {
                  self.loadedLivePhotos[uri] = livePhoto
                }

                if let playerItem = mediaResult.playerItem {
                  self.loadedPlayerItems[uri] = playerItem
                }

                // Only replace if this is still the current view controller for this URI
                guard
                  let currentShownVC = self.pageViewController.viewControllers?.first,
                  currentShownVC === currentViewController,
                  let currentIndex = self.getIndex(from: currentShownVC),
                  currentIndex == index,
                  uri == self.uris[currentIndex]
                else { return }

                // Create and set the appropriate controller
                let newViewController = MediaViewControllerFactory.createViewController(
                  for: mediaResult,
                  uri: uri,
                  index: index,
                  imageCache: self.imageCache,
                  delegate: self
                )

                // Replace with animation if it's a different type of controller
                if type(of: currentViewController) != type(of: newViewController) {
                  UIView.transition(
                    with: self.pageViewController.view,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: {
                      self.pageViewController.setViewControllers(
                        [newViewController],
                        direction: .forward,
                        animated: false
                      )
                    },
                    completion: nil
                  )
                }
              }
            }
          }
        }
      }
    }
  }

  private func preloadMediaForCurrentPage(uri: String, index: Int) {
    // Get the current view controller for this page
    guard let currentVC = pageViewController.viewControllers?.first,
      let currentIndex = getIndex(from: currentVC),
      currentIndex == index
    else { return }

    // Use our central method to load and replace
    loadMediaForPageAndReplace(uri: uri, index: index, currentViewController: currentVC)
  }
  private func updateCurrentViewControllerWithMedia(uri: String, mediaResult: MediaLoadResult) {
    // Only replace if this is still the current page
    guard let currentVC = pageViewController.viewControllers?.first,
      let index = getIndex(from: currentVC),
      index == currentIndex,
      uri == uris[currentIndex]
    else {
      return
    }

    // Only replace if the current view controller is an ImagePageViewController
    guard currentVC is ImagePageViewController else { return }

    // Create the appropriate view controller
    let newVC: UIViewController?

    switch mediaResult.mediaType {
    case .livePhoto:
      if let livePhoto = mediaResult.livePhoto {
        let viewController = LivePhotoViewController()
        viewController.configure(with: livePhoto, uri: uri, index: index)
        viewController.delegate = self
        newVC = viewController
      } else {
        return
      }

    case .video:
      if let playerItem = mediaResult.playerItem {
        let viewController = VideoViewController()
        viewController.configure(with: playerItem, uri: uri, index: index)
        viewController.delegate = self
        newVC = viewController
      } else {
        return
      }

    default:
      return
    }

    // Replace the view controller
    if let newVC = newVC {
      pageViewController.setViewControllers([newVC], direction: .forward, animated: false)
    }
  }

  // Load the media type and content in the background if needed
  private func loadMediaTypeIfNeeded(
    for uri: String, at index: Int, currentViewController: UIViewController
  ) {
    // Skip if we already know the media type
    if mediaTypeCache[uri] != nil {
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let imageLoader = ImageLoaderService(imageCache: self.imageCache)

      // First, just determine the media type
      imageLoader.determineMediaType(from: uri) { [weak self] mediaType, error in
        guard let self = self, let mediaType = mediaType else { return }

        // Cache the media type
        DispatchQueue.main.async {
          self.mediaTypeCache[uri] = mediaType

          // For images, no further action needed as ImagePageViewController handles them
          if mediaType == .image { return }

          // For other media types, continue loading the full content
          imageLoader.loadMedia(from: uri) {
            [weak self, weak currentViewController] mediaResult, error in
            guard let self = self,
              let currentViewController = currentViewController,
              currentViewController.isViewLoaded
            else { return }

            DispatchQueue.main.async {
              if let mediaResult = mediaResult {
                // Cache the loaded media
                if let livePhoto = mediaResult.livePhoto {
                  self.loadedLivePhotos[uri] = livePhoto
                }
                if let playerItem = mediaResult.playerItem {
                  self.loadedPlayerItems[uri] = playerItem
                }

                // Replace the view controller if it's still showing
                self.replaceViewControllerIfNeeded(
                  currentViewController: currentViewController,
                  with: mediaResult,
                  uri: uri,
                  index: index
                )
              }
            }
          }
        }
      }
    }
  }

  // Replace the current view controller if it's still the one being displayed for this index
  private func replaceViewControllerIfNeeded(
    currentViewController: UIViewController,
    with mediaResult: MediaLoadResult,
    uri: String,
    index: Int
  ) {
    // Only replace if the current view controller is still showing this index
    guard let currentShownVC = pageViewController.viewControllers?.first,
      currentShownVC === currentViewController,
      let currentIndex = getIndex(from: currentShownVC),
      currentIndex == index
    else {
      return
    }

    let newViewController = MediaViewControllerFactory.createViewController(
      for: mediaResult,
      uri: uri,
      index: index,
      imageCache: self.imageCache,
      delegate: self
    )

    // Replace the current view controller with the proper one for this media type
    pageViewController.setViewControllers(
      [newViewController],
      direction: .forward,
      animated: false
    )
  }
}

// MARK: - UIPageViewControllerDelegate
extension GalleryImageViewerView: UIPageViewControllerDelegate {
  func pageViewController(
    _ pageViewController: UIPageViewController,
    didFinishAnimating finished: Bool,
    previousViewControllers: [UIViewController],
    transitionCompleted completed: Bool
  ) {
    if completed,
      let currentViewController = pageViewController.viewControllers?.first,
      let index = getIndex(from: currentViewController)
    {
      // First stop any active media from previous page
      if previousViewControllers.first !== currentViewController {
        stopActiveMediaPlayback()
      }

      // Update the active media controller reference
      if currentViewController is VideoViewController
        || currentViewController is LivePhotoViewController
      {
        activeMediaViewController = currentViewController
      }

      currentIndex = index
      let uri = uris[currentIndex]

      onPageChange(["index": currentIndex, "uri": uri])

      // Now use our improved method to load the media if needed
      loadMediaForPageAndReplace(
        uri: uri, index: index, currentViewController: currentViewController)
    }
  }

  func pageViewController(
    _ pageViewController: UIPageViewController,
    willTransitionTo pendingViewControllers: [UIViewController]
  ) {
    // Stop any playing media before transitioning
    stopActiveMediaPlayback()
  }
}

// MARK: - MediaViewControllerDelegate
extension GalleryImageViewerView: MediaViewControllerDelegate {
  func mediaViewControllerDidRequestDismiss(_ controller: UIViewController) {
    onDismissAttempt(["index": currentIndex, "uri": uris[currentIndex]])

    // Prepare for dismissal based on controller type
    if let imageVC = controller as? ImagePageViewController {
      imageVC.prepareForDismissal()
    }
    // Add specific dismissal animations for other controller types if needed
  }
}

// MARK: - ImagePageViewControllerDelegate
extension GalleryImageViewerView: ImagePageViewControllerDelegate {
  func imagePageViewController(
    _ controller: ImagePageViewController, didLoadHighQualityImage uri: String
  ) {
    highQualityLoadedURIs.insert(uri)
    onImageLoaded(["uri": uri, "index": controller.index])
  }
}

extension GalleryImageViewerView: UIScrollViewDelegate {
  // Add method to initialize page view controller
  private func setupPageViewControllerGestures() {
    if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView })
      as? UIScrollView
    {
      scrollView.delegate = self
    }
  }

  // Detect when the page view controller's scroll view begins dragging
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    // Notify all live photo view controllers that page swiping has begun
    NotificationCenter.default.post(
      name: Notification.Name("PageControllerWillScroll"), object: nil)
  }
}

extension GalleryImageViewerView: ViewerProtocol {
  func setImageData(uris: [String], startIndex: Int) {
    loadImages(uris: uris, startIndex: startIndex)
  }

  func goToPage(_ index: Int) {
    goToPageWithIndex(index)
  }
}
