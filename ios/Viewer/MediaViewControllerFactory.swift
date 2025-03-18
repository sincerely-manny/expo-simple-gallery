import AVFoundation
import PhotosUI
import UIKit

class MediaViewControllerFactory {
  static func createViewController(
    for mediaResult: MediaLoadResult,
    uri: String,
    index: Int,
    imageCache: NSCache<NSString, UIImage>,
    delegate: MediaViewControllerDelegate
  ) -> UIViewController {
    switch mediaResult.mediaType {
    case .image:
      if let image = mediaResult.image {
        let viewController = ImagePageViewController()
        viewController.configure(
          with: uri,
          index: index,
          imageCache: imageCache,
          hasHighQuality: true
        )
        viewController.delegate = delegate as? ImagePageViewControllerDelegate
        return viewController
      }

    case .livePhoto:
      if let livePhoto = mediaResult.livePhoto {
        let viewController = LivePhotoViewController()
        viewController.configure(with: livePhoto, uri: uri, index: index)
        viewController.delegate = delegate
        return viewController
      } else if let image = mediaResult.image {
        // Fall back to image if live photo object isn't available
        let viewController = ImagePageViewController()
        viewController.configure(
          with: uri,
          index: index,
          imageCache: imageCache,
          hasHighQuality: true
        )
        viewController.delegate = delegate as? ImagePageViewControllerDelegate
        return viewController
      }

    case .video:
      if let playerItem = mediaResult.playerItem {
        let viewController = VideoViewController()
        viewController.configure(with: playerItem, uri: uri, index: index)
        viewController.delegate = delegate
        return viewController
      } else if let image = mediaResult.image {
        // Fall back to image if video cannot be loaded
        let viewController = ImagePageViewController()
        viewController.configure(
          with: uri,
          index: index,
          imageCache: imageCache,
          hasHighQuality: true
        )
        viewController.delegate = delegate as? ImagePageViewControllerDelegate
        return viewController
      }

    case .unknown:
      break
    }

    // Default to error placeholder if we can't create a proper view controller
    let errorViewController = ImagePageViewController()
    errorViewController.configure(with: uri, index: index, imageCache: imageCache, hasHighQuality: false)
    errorViewController.delegate = delegate as? ImagePageViewControllerDelegate
    return errorViewController
  }
}
