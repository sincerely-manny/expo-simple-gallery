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
  }

  private func processPendingMounts() {
    guard !pendingMounts.isEmpty else { return }

    let sortedMounts = pendingMounts.sorted { $0.index < $1.index }
    pendingMounts.removeAll()

    for mount in sortedMounts {
      mountedHierarchy[mount.index] = [mount.index: mount.view]
    }

    galleryView.setHierarchy(mountedHierarchy)
  }

  override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
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
    if mountedHierarchy[index] != nil {
      mountedHierarchy.removeValue(forKey: index)
      childComponentView.removeFromSuperview()
    }

    galleryView.setHierarchy(mountedHierarchy)
  }

}
