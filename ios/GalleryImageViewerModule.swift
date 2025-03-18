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
        if let index = index {
          view.goToPageWithIndex(index)
        }
      }
    }
  }
}
