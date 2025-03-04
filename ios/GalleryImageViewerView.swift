import ExpoModulesCore
import Photos
import UIKit

class GalleryImageViewerView: ExpoView {
  private let imageCache = NSCache<NSString, UIImage>()
  private var highQualityLoadedURIs = Set<String>()
  var pageViewController: UIPageViewController
  var uris: [String] = []
  var currentIndex: Int = 0

  let onPageChange = EventDispatcher()
  let onImageLoaded = EventDispatcher()
  let onDismissAttempt = EventDispatcher()

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
  }

  func loadImages(uris: [String], startIndex: Int) {
    self.uris = uris
    self.currentIndex = min(max(startIndex, 0), uris.count - 1)
    onPageChange(["index": currentIndex, "uri": uris[currentIndex]])

    if let initialViewController = imageViewController(at: currentIndex) {
      pageViewController.setViewControllers(
        [initialViewController],
        direction: .forward,
        animated: false
      )
    }
  }

  override func removeFromSuperview() {
    imageCache.removeAllObjects()
    highQualityLoadedURIs.removeAll()
    super.removeFromSuperview()
  }

  func imageViewController(at index: Int) -> ImagePageViewController? {
    guard index >= 0 && index < uris.count else { return nil }

    let viewController = ImagePageViewController()
    viewController.delegate = self

    let uri = uris[index]
    let hasHighQuality = highQualityLoadedURIs.contains(uri)
    viewController.configure(with: uri, index: index, imageCache: imageCache, hasHighQuality: hasHighQuality)

    return viewController
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    pageViewController.view.frame = bounds
  }
}

// MARK: - UIPageViewControllerDataSource
extension GalleryImageViewerView: UIPageViewControllerDataSource {
  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    guard let imageVC = viewController as? ImagePageViewController else { return nil }
    let index = imageVC.index - 1
    return imageViewController(at: index)
  }

  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerAfter viewController: UIViewController
  ) -> UIViewController? {
    guard let imageVC = viewController as? ImagePageViewController else { return nil }
    let index = imageVC.index + 1
    return imageViewController(at: index)
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
      let currentViewController = pageViewController.viewControllers?.first as? ImagePageViewController
    {
      currentIndex = currentViewController.index

      onPageChange(["index": currentIndex, "uri": uris[currentIndex]])
    }
  }
}

// MARK: - ImagePageViewControllerDelegate
extension GalleryImageViewerView: ImagePageViewControllerDelegate {
  func imagePageViewControllerDidRequestDismiss(_ controller: ImagePageViewController) {
    onDismissAttempt(["index": currentIndex, "uri": uris[currentIndex]])
    if let currentVC = pageViewController.viewControllers?.first as? ImagePageViewController {
      currentVC.prepareForDismissal()
    }
  }

  func imagePageViewController(_ controller: ImagePageViewController, didLoadHighQualityImage uri: String) {
    highQualityLoadedURIs.insert(uri)
    onImageLoaded(["uri": uri, "index": controller.index])
  }
}
