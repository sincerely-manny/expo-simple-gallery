import ExpoModulesCore
import UIKit

final class ExpoSimpleGalleryView: ExpoView {
  var galleryView: GalleryGridView?
  private var pendingMounts: [(index: Int, view: UIView)] = []
  private var mountedHierarchy = [Int: [Int: UIView]]()
  private var idToIndexMap = [Int: Int]()
  private var indexToIdMap = [Int: Int]()

  let onOverlayPreloadRequested = EventDispatcher()
  let onThumbnailPress = EventDispatcher()
  let onThumbnailLongPress = EventDispatcher()
  let onSelectionChange = EventDispatcher()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    galleryView = GalleryGridView(gestureEventDelegate: self, overlayPreloadingDelegate: self)
    clipsToBounds = true
    guard let galleryView else { return }
    addSubview(galleryView)
    galleryView.frame = bounds
    galleryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

//  deinit {
//    cleanup()
//  }
//
//  private func cleanup() {
//    pendingMounts.removeAll()
//
//    for (_, children) in mountedHierarchy {
//      for (_, view) in children {
//        if view.superview as? ExpoView != nil {
//          view.removeFromSuperview()
//        }
//      }
//    }
//    mountedHierarchy.removeAll()
//
//    galleryView?.setHierarchy([:])
//  }

  private func processPendingMounts() {
    guard !pendingMounts.isEmpty else { return }

    let sortedMounts = pendingMounts.sorted { $0.index < $1.index }
    pendingMounts.removeAll()

    for mount in sortedMounts {
      if let label = mount.view.accessibilityLabel,
        label.starts(with: "GalleryViewOverlay___"),
        let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
      {
        // Store both mappings
        idToIndexMap[id] = mount.index
        indexToIdMap[mount.index] = id
        mountedHierarchy[id] = [id: mount.view]
      }
    }

    galleryView?.setHierarchy(mountedHierarchy)
  }

  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
    guard let label = childComponentView.accessibilityLabel,
      label.starts(with: "GalleryViewOverlay_"),
      let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
    else {
      super.mountChildComponentView(childComponentView, index: index)
      return
    }

    // Clean up existing view for this ID or index
//    if let existingIndex = idToIndexMap[id] {
//      if let existingView = mountedHierarchy[id]?[id] {
//        existingView.removeFromSuperview()
//      }
//      mountedHierarchy.removeValue(forKey: id)
//      indexToIdMap.removeValue(forKey: existingIndex)
//    }
//
//    pendingMounts.append((index: index, view: childComponentView))
//
//    DispatchQueue.main.async { [weak self] in
//      self?.processPendingMounts()
//    }
  }

  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    guard let label = childComponentView.accessibilityLabel,
      label.starts(with: "GalleryViewOverlay_"),
      let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
    else {
      super.unmountChildComponentView(childComponentView, index: index)
      return
    }
    // Handle unmounting by index
//    if let id = indexToIdMap[index] {
//      mountedHierarchy.removeValue(forKey: id)
//      idToIndexMap.removeValue(forKey: id)
//      indexToIdMap.removeValue(forKey: index)
//      childComponentView.removeFromSuperview()
//    }
//
//    galleryView?.setHierarchy(mountedHierarchy)
  }

  // Add method to get overlay by ID
  func getOverlay(forId id: Int) -> UIView? {
    return mountedHierarchy[id]?[id]
  }

}

extension ExpoSimpleGalleryView: GestureEventDelegate {
  func galleryGrid(_ gallery: GalleryGridView, didPressCell cell: PressedCell) {
    onThumbnailPress(cell.dict())
  }

  func galleryGrid(_ gallery: GalleryGridView, didLongPressCell cell: PressedCell) {
    onThumbnailLongPress(cell.dict())
  }

  func galleryGrid(_ gallery: GalleryGridView, didSelectCells assets: Set<String>) {
    onSelectionChange(["selected": Array(assets)])
  }
}

extension ExpoSimpleGalleryView: OverlayPreloadingDelegate {
  func galleryGrid(_ gallery: GalleryGridView, prefetchOverlaysFor range: (Int, Int)) {
    onOverlayPreloadRequested(["range": [range.0, range.1]])
  }
}
