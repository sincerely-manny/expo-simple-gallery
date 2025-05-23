import ExpoModulesCore
import React
import UIKit

final class ExpoSimpleGalleryView: ExpoView, ContextMenuActionsDelegate {
  var galleryView: GalleryGridView?
  private var overlays: [String: [Int: ReactMountingComponent]] = [
    "thumbnail": [:],
    "sectionHeader": [:],
  ]

  let onOverlayPreloadRequested = EventDispatcher()
  let onThumbnailPress = EventDispatcher()
  let onThumbnailLongPress = EventDispatcher()
  let onSelectionChange = EventDispatcher()
  let onSectionHeadersVisible = EventDispatcher()
  let onPreviewMenuOptionSelected = EventDispatcher()

  // public func definition() -> ViewDefinition<ExpoSimpleGalleryView> {
  //   View(ExpoSimpleGalleryView.self) {
  //     Events(
  //       "onThumbnailPress", "onThumbnailLongPress", "onSelectionChange",
  //       "onOverlayPreloadRequested",
  //       "onSectionHeadersVisible", "onPreviewMenuOptionSelected"
  //     )

  //     Prop("assets") { (view: ExpoSimpleGalleryView, assets: [Any]) in
  //       if let uris = assets as? [String] {
  //         view.galleryView?.setAssets(uris: uris)
  //       } else if let groupedArrays = assets as? [[String]] {
  //         var flattenedUris: [String] = []
  //         var sectionData: [[String: Int]] = []
  //         for (sectionIndex, section) in groupedArrays.enumerated() {
  //           for (itemIndex, uri) in section.enumerated() {
  //             flattenedUris.append(uri)
  //             sectionData.append([
  //               "sectionIndex": sectionIndex,
  //               "itemIndex": itemIndex,
  //             ])
  //           }
  //         }
  //         view.galleryView?.setAssets(uris: flattenedUris, sectionData: sectionData)
  //       }
  //     }
  //     Prop("columnsCount") { (view: ExpoSimpleGalleryView, columns: Int) in
  //       view.galleryView?.setColumns(columns)
  //     }
  //     Prop("thumbnailsSpacing") { (view: ExpoSimpleGalleryView, spacing: Double) in
  //       let spacing = CGFloat(spacing)
  //       view.galleryView?.setSpacing(spacing)
  //     }
  //     Prop("thumbnailStyle") { (view: ExpoSimpleGalleryView, style: [String: Any]) in
  //       view.galleryView?.setThumbnailStyle(style)
  //     }
  //     Prop("contentContainerStyle") { (view: ExpoSimpleGalleryView, style: [String: Any]) in
  //       view.galleryView?.setContentContainerStyle(style)
  //     }
  //     Prop("thumbnailPressAction") { (view: ExpoSimpleGalleryView, action: String) in
  //       view.galleryView?.setThumbnailPressAction(action)
  //     }
  //     Prop("thumbnailLongPressAction") { (view: ExpoSimpleGalleryView, action: String) in
  //       view.galleryView?.setThumbnailLongPressAction(action)
  //     }
  //     Prop("thumbnailPanAction") { (view: ExpoSimpleGalleryView, action: String) in
  //       view.galleryView?.setThumbnailPanAction(action)
  //     }
  //     Prop("sectionHeaderStyle") { (view: ExpoSimpleGalleryView, style: [String: Any]) in
  //       view.galleryView?.setSectionHeaderStyle(style)
  //     }
  //     Prop("contextMenuOptions") { (view: ExpoSimpleGalleryView, options: [Any]) in
  //       view.galleryView?.setContextmenuOptions(options)
  //     }
  //     Prop("showMediaTypeIcon") { (view: ExpoSimpleGalleryView, isVisible: Bool) in
  //       view.galleryView?.setMediaTypeIconIsVisible(isVisible)
  //     }

  //     AsyncFunction("centerOnIndex") { (view: ExpoSimpleGalleryView, index: Int) in
  //       view.galleryView?.centerOnIndex(index)
  //     }.runOnQueue(.main)

  //     AsyncFunction("setSelected") { (view: ExpoSimpleGalleryView, uris: [String]) in
  //       let set = Set(uris)
  //       view.onSelectionChange(["selected": Array(set)])
  //       view.galleryView?.selectedAssets = set
  //     }

  //     AsyncFunction("setThumbnailPressAction") { (view: ExpoSimpleGalleryView, action: String) in
  //       view.galleryView?.setThumbnailPressAction(action)
  //     }
  //     AsyncFunction("setThumbnailLongPressAction") {
  //       (view: ExpoSimpleGalleryView, action: String) in
  //       view.galleryView?.setThumbnailLongPressAction(action)
  //     }
  //     AsyncFunction("setThumbnailPanAction") { (view: ExpoSimpleGalleryView, action: String) in
  //       view.galleryView?.setThumbnailPanAction(action)
  //     }
  //     AsyncFunction("setContextMenuOptions") { (view: ExpoSimpleGalleryView, options: [Any]) in
  //       view.galleryView?.setContextmenuOptions(options)
  //     }
  //   }
  // }

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
      guard let label = childComponentView.accessibilityLabel else {
        self.callSuperMountChildComponentView(childComponentView, index: index)
        return
      }

      if label.starts(with: "GalleryViewOverlay_") {
        guard let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: "")) else {
          return
        }
        let component = ReactMountingComponent(view: childComponentView, index: index)
        self.overlays["thumbnail"]?[id] = component

        if let cell = self.galleryView?.cell(withIndex: id) {
          self.mount(to: cell, overlay: component)
        }
      } else if label.starts(with: "SectionHeaderOverlay_") {
        guard let sectionId = Int(label.replacingOccurrences(of: "SectionHeaderOverlay_", with: ""))
        else { return }
        let component = ReactMountingComponent(view: childComponentView, index: index)
        self.overlays["sectionHeader"]?[sectionId] = component

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
    }
  }

  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    let component = ReactMountingComponent(view: childComponentView, index: index)
    self.unmount(overlay: component)
    guard let label = childComponentView.accessibilityLabel else { return }

    if label.starts(with: "GalleryViewOverlay_") {
      guard let id = Int(label.replacingOccurrences(of: "GalleryViewOverlay_", with: "")) else {
        return
      }
      overlays["thumbnail"]?[id] = nil
    } else if label.starts(with: "SectionHeaderOverlay_") {
      guard let sectionId = Int(label.replacingOccurrences(of: "SectionHeaderOverlay_", with: ""))
      else { return }
      overlays["sectionHeader"]?[sectionId] = nil
    }
  }

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

  func galleryGrid(_ gallery: GalleryGridView, sectionsVisible sections: [Int]) {
    if !sections.isEmpty {
      onSectionHeadersVisible(["sections": sections])
    }
  }
}

// MARK: - Overlay Mounting Implementation
extension ExpoSimpleGalleryView: OverlayMountingDelegate {
  func mount<T: OverlayContainer>(to container: T) {
    guard let containerId = container.containerIdentifier else { return }
    var component: ReactMountingComponent?
    if container is GalleryCell {
      component = overlays["thumbnail"]?[containerId]
    } else if container is GallerySectionHeaderView {
      component = overlays["sectionHeader"]?[containerId]
    }

    if let component = component {
      mount(to: container, overlay: component)
    }
  }

  func mount<T: OverlayContainer>(to container: T, overlay: ReactMountingComponent) {
    DispatchQueue.main.async { [weak self] in
      guard overlay.view.superview == nil else { return }
      guard self?.getMountedOverlayComponent(for: container)?.view != overlay.view else { return }
      // TODO: fix remounting after props (uris list) update
      container.overlayContainer.mountChildComponentView(overlay.view, index: overlay.index)
      // container.overlayContainer.addSubview(overlay.view)
      overlay.view.didMoveToSuperview()
    }
  }

  func unmount<T: OverlayContainer>(from container: T) {
    let components = container.overlayContainer.subviews
    for (index, component) in components.enumerated() {
      unmount(overlay: ReactMountingComponent(view: component, index: index))
    }
  }

  func unmount(overlay: ReactMountingComponent) {
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
