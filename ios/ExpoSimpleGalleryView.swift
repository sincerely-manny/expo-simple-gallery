import ExpoModulesCore
import React
import UIKit

final class ExpoSimpleGalleryView: ExpoView, ContextMenuActionsDelegate {
  var galleryView: GalleryGridView?
  private var thumbnailOverlays: [Int: ReactMountingComponent] = [:]
  private var sectionHeaderOverlays: [Int: ReactMountingComponent] = [:]

  let onOverlayPreloadRequested = EventDispatcher()
  let onThumbnailPress = EventDispatcher()
  let onThumbnailLongPress = EventDispatcher()
  let onSelectionChange = EventDispatcher()
  let onSectionHeadersVisible = EventDispatcher()
  let onPreviewMenuOptionSelected = EventDispatcher()

  @MainActor
  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    galleryView = GalleryGridView(
      gestureEventDelegate: self,
      overlayPreloadingDelegate: self,
      overlayMountingDelegate: self,
      contextMenuActionsDelegate: self
    )
    clipsToBounds = true
    guard let galleryView else { return }
    addSubview(galleryView)
    galleryView.frame = bounds
    galleryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  @MainActor
  func callSuperMountChildComponentView(_ childComponentView: UIView, index: Int) {
    super.mountChildComponentView(childComponentView, index: index)
  }

  @MainActor
  func callSuperUnmountChildComponentView(_ childComponentView: UIView, index: Int) {
    super.unmountChildComponentView(childComponentView, index: index)
  }

  @MainActor
  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
    // DispatchQueue.main.async { [weak self] in
    //   guard let self else { return }
    if childComponentView.superview != nil {
      callSuperMountChildComponentView(childComponentView, index: index)
      return
    }
    guard let label = childComponentView.accessibilityLabel else {
      self.callSuperMountChildComponentView(childComponentView, index: index)
      return
    }

    if label.starts(with: "GalleryViewOverlay_") {
      guard let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: "")) else {
        return
      }
      let component = ReactMountingComponent(view: childComponentView, index: index)
      self.thumbnailOverlays[id] = component

      if let cell = self.galleryView?.cell(withIndex: id) {
        self.mount(to: cell, overlay: component)
      }
    } else if label.starts(with: "SectionHeaderOverlay_") {
      guard let sectionId = Int(label.replacingOccurrences(of: "SectionHeaderOverlay_", with: ""))
      else { return }
      let component = ReactMountingComponent(view: childComponentView, index: index)
      self.sectionHeaderOverlays[sectionId] = component

      if let galleryView = self.galleryView, galleryView.isGroupedLayout {
        let indexPath = IndexPath(item: 0, section: sectionId)
        if let headerView = galleryView.supplementaryView(
          forElementKind: UICollectionView.elementKindSectionHeader,
          at: indexPath) as? GallerySectionHeaderView
        {
          self.mount(to: headerView, overlay: component)
        }
      }
    }
    // }
  }

  @MainActor
  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    let component = ReactMountingComponent(view: childComponentView, index: index)
    self.unmount(overlay: component)
    guard let label = childComponentView.accessibilityLabel else { return }

    if label.starts(with: "GalleryViewOverlay_") {
      guard let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: "")) else {
        return
      }
      thumbnailOverlays[id] = nil
    } else if label.starts(with: "SectionHeaderOverlay_") {
      guard let sectionId = Int(label.replacingOccurrences(of: "SectionHeaderOverlay_", with: ""))
      else { return }
      sectionHeaderOverlays[sectionId] = nil
    }
  }

  @MainActor
  deinit {
    // Clean up all visible containers
    galleryView?.visibleCells().forEach { cell in
      unmount(from: cell)
    }

    if let galleryView = galleryView, galleryView.isGroupedLayout {
      for section in 0..<galleryView.numberOfSections {
        let indexPath = IndexPath(item: 0, section: section)
        if let headerView = galleryView.supplementaryView(
          forElementKind: UICollectionView.elementKindSectionHeader,
          at: indexPath) as? GallerySectionHeaderView
        {
          unmount(from: headerView)
        }
      }
    }
  }
}

@MainActor
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

@MainActor
extension ExpoSimpleGalleryView: OverlayPreloadingDelegate {
  func galleryGrid(_ gallery: GalleryGridView, prefetchOverlaysFor range: (Int, Int)) {
    onOverlayPreloadRequested(["range": [range.0, range.1]])
  }

  func galleryGrid(_ gallery: GalleryGridView, sectionsVisible sections: [Int]) {
    if !sections.isEmpty {
      onSectionHeadersVisible(["sections": sections])
    }
  }
}

// MARK: - Overlay Mounting Implementation
@MainActor
extension ExpoSimpleGalleryView: OverlayMountingDelegate {
  func mount<T: OverlayContainer>(to container: T) {
    guard let containerId = container.containerIdentifier else { return }
    var component: ReactMountingComponent?
    if container is GalleryCell {
      component = thumbnailOverlays[containerId]
    } else if container is GallerySectionHeaderView {
      component = sectionHeaderOverlays[containerId]
    }

    if let component = component {
      mount(to: container, overlay: component)
    }
  }

  func mount<T: OverlayContainer>(to container: T, overlay: ReactMountingComponent) {
    // DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
    // guard let self else { return }

    // if overlay.view.superview == container.overlayContainer {
    //   // Already mounted, no need to remount
    //   return
    // } else

    if overlay.view.superview != nil {
      // If the overlay is already mounted somewhere else, unmount it first
      self.unmount(overlay: overlay)
    }

    // guard overlay.view.superview == nil else { return }
    if self.getMountedOverlayComponent(for: container) != nil {
      self.unmount(from: container)
    }
    // guard self.getMountedOverlayComponent(for: container)?.view != overlay.view else { return }
    // TODO: fix remounting after props (uris list) update
    // container.overlayContainer.mountChildComponentView(overlay.view, index: overlay.index)
    container.overlayContainer.addSubview(overlay.view)
    overlay.view.didMoveToSuperview()
    // }
  }

  func unmount<T: OverlayContainer>(from container: T) {
    let components = container.overlayContainer.subviews
    for (index, component) in components.enumerated() {
      unmount(overlay: ReactMountingComponent(view: component, index: index))
    }
  }

  func unmount(overlay: ReactMountingComponent) {
    guard overlay.view.superview != nil else { return }
    // print("Unmounting overlay: \(overlay.view.accessibilityLabel ?? "unknown")")
    // print("Overlay index: \(overlay.index)")
    // print("Overlay parent: \(String(describing: overlay.view.superview))")
    overlay.view.willMove(toSuperview: nil)
    overlay.view.removeFromSuperview()
  }

  func getMountedOverlayComponent<T: OverlayContainer>(for container: T) -> ReactMountingComponent?
  {
    let (index, view) =
      container.overlayContainer.subviews.enumerated().first(where: { $0.element is ExpoView }) ?? (
        0, nil
      )
    if let view {
      return ReactMountingComponent(view: view, index: index)
    }
    return nil
  }
}
