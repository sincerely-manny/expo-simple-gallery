import ExpoModulesCore
import UIKit

final class ExpoSimpleGalleryView: ExpoView {
  var galleryView: GalleryGridView?
  private var overlays: [Int: ReactMountingComponent] = [:]

  let onOverlayPreloadRequested = EventDispatcher()
  let onThumbnailPress = EventDispatcher()
  let onThumbnailLongPress = EventDispatcher()
  let onSelectionChange = EventDispatcher()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    galleryView = GalleryGridView(
      gestureEventDelegate: self,
      overlayPreloadingDelegate: self,
      overlayMountingDelegate: self
    )
    clipsToBounds = true
    guard let galleryView else { return }
    addSubview(galleryView)
    galleryView.frame = bounds
    galleryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
    guard childComponentView.superview == nil else { return }
    guard let label = childComponentView.accessibilityLabel,
      label.starts(with: "GalleryViewOverlay_"),
      let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
    else {
      super.mountChildComponentView(childComponentView, index: index)
      return
    }

    let component = ReactMountingComponent(view: childComponentView, index: index)
    let cell = galleryView?.cell(withIndex: id)
    overlays[id] = component

    if let cell {
      mount(to: cell, overlay: component)
    }
  }

  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    guard let label = childComponentView.accessibilityLabel,
      label.starts(with: "GalleryViewOverlay_"),
      let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
    else {
      super.unmountChildComponentView(childComponentView, index: index)
      return
    }
    let component = ReactMountingComponent(view: childComponentView, index: index)
    let cell = galleryView?.cell(withIndex: id)
    overlays.removeValue(forKey: id)

    if let cell {
      unmount(from: cell, overlay: component)
    }

  }

  deinit {
    galleryView?.visibleCells().forEach { cell in
      unmount(from: cell)
    }
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

extension ExpoSimpleGalleryView: OverlayMountingDelegate {
  func mount(to cell: GalleryCell) {
    guard let cellIndex = cell.cellIndex else { return }
    guard let component = overlays[cellIndex] else { return }
    mount(to: cell, overlay: component)
  }

  func mount(to cell: GalleryCell, overlay: ReactMountingComponent) {
    guard overlay.view.superview == nil else { return }
    guard getMountedOverlayComponent(for: cell)?.view != overlay.view else { return }
    cell.overlayContainer.mountChildComponentView(overlay.view, index: overlay.index)
  }

  func unmount(from cell: GalleryCell) {
    guard let cellIndex = cell.cellIndex else { return }
    guard let component = overlays[cellIndex] else { return }
    unmount(from: cell, overlay: component)
  }

  func unmount(from cell: GalleryCell, overlay: ReactMountingComponent) {
    if let superview = overlay.view.superview {
      let index = superview.subviews.firstIndex(where: { $0 == overlay.view }) ?? 0

      if let expoSuperView = superview as? ExpoView {
        expoSuperView.unmountChildComponentView(overlay.view, index: index)
      } else {
        overlay.view.removeFromSuperview()
      }
    }
  }

  func getMountedOverlayComponent(for cell: GalleryCell) -> ReactMountingComponent? {
    let (index, view) =
      cell.overlayContainer.subviews.enumerated().first(where: { $0.element is ExpoView }) ?? (
        0, nil
      )
    if let view {
      return ReactMountingComponent(view: view, index: index)
    }
    return nil
  }
}
