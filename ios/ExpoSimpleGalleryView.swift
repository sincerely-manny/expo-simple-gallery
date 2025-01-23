import ExpoModulesCore
import UIKit

final class ExpoSimpleGalleryView: ExpoView {
  let galleryView = GalleryGridView()
  private var pendingMounts: [(index: Int, view: UIView)] = []
  private var mountedHierarchy = [Int: [Int: UIView]]()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    addSubview(galleryView)
    galleryView.frame = bounds
    galleryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    // Register for reload notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleReload),
      name: UIApplication.willTerminateNotification,
      object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    cleanup()
  }

  @objc private func handleReload() {
    cleanup()
  }

  private func cleanup() {
    // Clean up pending mounts
    pendingMounts.removeAll()

    // Clean up mounted views
    for (_, children) in mountedHierarchy {
      for (_, view) in children {
        if let _ = view.superview as? ExpoView {
          // Remove from parent without unmounting
          view.removeFromSuperview()
        }
      }
    }
    mountedHierarchy.removeAll()

    // Reset gallery view
    galleryView.setHierarchy([:])
  }

  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
    // First ensure any existing view at this index is properly cleaned up
    if let existingChildren = mountedHierarchy[index] {
      for (_, existingView) in existingChildren {
        existingView.removeFromSuperview()
      }
    }

    pendingMounts.append((index: index, view: childComponentView))

    DispatchQueue.main.async { [weak self] in
      self?.processPendingMounts()
    }
  }

  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    // Remove from mounted hierarchy
    if mountedHierarchy[index] != nil {
      mountedHierarchy.removeValue(forKey: index)
      childComponentView.removeFromSuperview()
    }

    // Update gallery view
    galleryView.setHierarchy(mountedHierarchy)
  }

  private func processPendingMounts() {
    guard !pendingMounts.isEmpty else { return }

    // Sort by index to maintain order
    let sortedMounts = pendingMounts.sorted { $0.index < $1.index }
    pendingMounts.removeAll()

    // Process mounts
    for mount in sortedMounts {
      // Add to hierarchy
      mountedHierarchy[mount.index] = [mount.index: mount.view]
    }

    // Update gallery view
    galleryView.setHierarchy(mountedHierarchy)
  }
}
