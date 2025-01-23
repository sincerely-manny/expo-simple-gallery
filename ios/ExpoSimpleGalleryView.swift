import ExpoModulesCore
import UIKit

final class ExpoSimpleGalleryView: ExpoView {
  let galleryView = GalleryGridView()
  private var pendingMounts: [(index: Int, view: UIView)] = []
  private var mountedHierarchy = [Int: [Int: UIView]]()

  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
    // First, check if we need to unmount any existing view at this index
    if let existingHierarchy = mountedHierarchy[index] {
      for (_, existingView) in existingHierarchy {
        // Only unmount if it's a different view
        if existingView !== childComponentView {
          unmountChildComponentView(existingView, index: index)
        }
      }
    }

    pendingMounts.append((index: index, view: childComponentView))

    DispatchQueue.main.async { [weak self] in
      self?.processPendingMounts()
    }
  }

  private func processPendingMounts() {
    defer {
      pendingMounts.removeAll()
    }

    var newHierarchy = mountedHierarchy

    // Sort by index to maintain order
    let sortedMounts = pendingMounts.sorted { $0.index < $1.index }

    // Find parent views (first level)
    let parentMounts = sortedMounts.filter { mount in
      !pendingMounts.contains { otherMount in
        otherMount.view !== mount.view && otherMount.view.isDescendant(of: mount.view)
      }
    }

    // Process each parent
    for parentMount in parentMounts {
      var children = [Int: UIView]()

      // Only add if not already in hierarchy
      if mountedHierarchy[parentMount.index]?[parentMount.index] !== parentMount.view {
        children[parentMount.index] = parentMount.view
      }

      // Find and add children
      for childMount in sortedMounts
      where childMount.view !== parentMount.view
        && childMount.view.isDescendant(of: parentMount.view)
      {
        if mountedHierarchy[parentMount.index]?[childMount.index] !== childMount.view {
          children[childMount.index] = childMount.view
        }
      }

      // Update hierarchy only if there are changes
      if !children.isEmpty {
        newHierarchy[parentMount.index] = children
      }
    }

    // Only update if hierarchy has changed
    if newHierarchy != mountedHierarchy {
      mountedHierarchy = newHierarchy
      galleryView.setHierarchy(newHierarchy)
    }
  }

  override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
    // Remove from mounted hierarchy
    if var children = mountedHierarchy[index] {
      // Remove the specific view
      children = children.filter { $0.value !== childComponentView }

      if children.isEmpty {
        mountedHierarchy.removeValue(forKey: index)
      } else {
        mountedHierarchy[index] = children
      }
    }

    // Update gallery view
    galleryView.setHierarchy(mountedHierarchy)
  }

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    addSubview(galleryView)
    galleryView.frame = bounds
    galleryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }
}
