import ExpoModulesCore

public class GalleryImageViewerModule: Module {
  private var uris: [String] = []

  public func definition() -> ModuleDefinition {
    Name("GalleryImageViewer")
    View(GalleryImageViewerView.self) {
      Events("onPageChange", "onImageLoaded", "onDismissAttempt")
      Prop("imageData") { (view: GalleryImageViewerView, assets: [String: Any]) in
        if let uris = assets["uris"] as? [String],
          let startIndex = assets["startIndex"] as? Int
        {
          view.loadImages(uris: uris, startIndex: startIndex)
        }
      }
      Prop("goToPage") { (view: GalleryImageViewerView, index: Int?) in
        if let index,
          index >= 0 && index < view.uris.count,
          let viewController = view.imageViewController(at: index)
        {

          let direction: UIPageViewController.NavigationDirection = index > view.currentIndex ? .forward : .reverse
          view.pageViewController.setViewControllers(
            [viewController],
            direction: direction,
            animated: true
          )
          view.currentIndex = index
        }
      }
    }
  }
}
