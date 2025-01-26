import ExpoModulesCore
import UIKit

final class ExpoSimpleGalleryView: ExpoView {
  var galleryView: GalleryGridView?
  private var overlays: [Int: UIView] = [:]

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

  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
    guard let label = childComponentView.accessibilityLabel,
      label.starts(with: "GalleryViewOverlay_"),
      let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
    else {
      super.mountChildComponentView(childComponentView, index: index)
      return
    }
    overlays[id] = childComponentView
    galleryView?.setOverlays(overlays)
  }

  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    guard let label = childComponentView.accessibilityLabel,
      label.starts(with: "GalleryViewOverlay_"),
      let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
    else {
      super.unmountChildComponentView(childComponentView, index: index)
      return
    }
    overlays.removeValue(forKey: id)
    galleryView?.setOverlays(overlays)
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
