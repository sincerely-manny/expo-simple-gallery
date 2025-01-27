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

  func callSuperMountChildComponentView(_ childComponentView: UIView, index: Int) {
    super.mountChildComponentView(childComponentView, index: index)
  }

  func callSuperUnmountChildComponentView(_ childComponentView: UIView, index: Int) {
    super.unmountChildComponentView(childComponentView, index: index)
  }

  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      guard childComponentView.superview == nil else { return }
      guard let label = childComponentView.accessibilityLabel,
        label.starts(with: "GalleryViewOverlay_"),
        let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
      else {
        self.callSuperMountChildComponentView(childComponentView, index: index)
        return
      }

      let component = ReactMountingComponent(view: childComponentView, index: index)
      let cell = self.galleryView?.cell(withIndex: id)
      self.overlays[id] = component

      if let cell {
        self.mount(to: cell, overlay: component)
      }
    }
  }

  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    self.unmount(overlay: ReactMountingComponent(view: childComponentView, index: index))
    guard let label = childComponentView.accessibilityLabel,
            label.starts(with: "GalleryViewOverlay_"),
            let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: ""))
    else { return }
    overlays.removeValue(forKey: id)
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
    DispatchQueue.main.async { [weak self] in
      guard overlay.view.superview == nil else { return }
      guard self?.getMountedOverlayComponent(for: cell)?.view != overlay.view else { return }
      cell.overlayContainer.mountChildComponentView(overlay.view, index: overlay.index)
      overlay.view.didMoveToSuperview()
    }
  }

  func unmount(from cell: GalleryCell) {
    let components = cell.overlayContainer.subviews
    for (index, component) in components.enumerated() {
      unmount(overlay: ReactMountingComponent(view: component, index: index))
    }
  }

  func unmount(overlay: ReactMountingComponent) {
    overlay.view.removeFromSuperview()
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
