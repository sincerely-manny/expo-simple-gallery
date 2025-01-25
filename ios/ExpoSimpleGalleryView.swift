import ExpoModulesCore
import UIKit

final class ExpoSimpleGalleryView: ExpoView {
  var galleryView: GalleryGridView?
  private var pendingMounts: [(index: Int, view: UIView)] = []
  private var mountedHierarchy = [Int: [Int: UIView]]()

  let onThumbnailPress = EventDispatcher()
  let onThumbnailLongPress = EventDispatcher()
  let onSelectionChange = EventDispatcher()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    galleryView = GalleryGridView(gestureEventDelegate: self)
    clipsToBounds = true
    guard let galleryView else { return }
    addSubview(galleryView)
    galleryView.frame = bounds
    galleryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  deinit {
    cleanup()
  }

  private func cleanup() {
    pendingMounts.removeAll()

    for (_, children) in mountedHierarchy {
      for (_, view) in children {
        if view.superview as? ExpoView != nil {
          view.removeFromSuperview()
        }
      }
    }
    mountedHierarchy.removeAll()

    galleryView?.setHierarchy([:])
  }

  private func processPendingMounts() {
    guard !pendingMounts.isEmpty else { return }

    let sortedMounts = pendingMounts.sorted { $0.index < $1.index }
    pendingMounts.removeAll()

    for mount in sortedMounts {
      mountedHierarchy[mount.index] = [mount.index: mount.view]
    }

    galleryView?.setHierarchy(mountedHierarchy)
  }

  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
    guard let label = childComponentView.accessibilityLabel else { return }
    if label.starts(with: "GalleryViewOverlay_") {
      guard let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: "")) else {
        return
      }
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
  }

  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    if mountedHierarchy[index] != nil {
      mountedHierarchy.removeValue(forKey: index)
      childComponentView.removeFromSuperview()
    }

    galleryView?.setHierarchy(mountedHierarchy)
  }

}

extension ExpoSimpleGalleryView: GestureEventDelegate {
  func galleryGrid(_ gallery: GalleryGridView, didPressCell cell: PressedCell) {
    onThumbnailPress(cell.dict())
    print(cell)
  }

  func galleryGrid(_ gallery: GalleryGridView, didLongPressCell cell: PressedCell) {
    onThumbnailLongPress(cell.dict())
    print(cell)
  }

  func galleryGrid(_ gallery: GalleryGridView, didSelectCells assets: Set<String>) {
    onSelectionChange(["selected": Array(assets)])
    print(assets)
  }
}
