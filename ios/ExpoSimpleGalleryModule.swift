import ExpoModulesCore

public class ExpoSimpleGalleryModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoSimpleGallery")
    View(ExpoSimpleGalleryView.self) {
      Events("onThumbnailPress", "onThumbnailLongPress", "onSelectionChange", "onOverlayPreloadRequested")

      Prop("assets") { (view: ExpoSimpleGalleryView, assets: [String]) in
        view.galleryView?.setAssets(assets)
      }
      Prop("columnsCount") { (view: ExpoSimpleGalleryView, columns: Int) in
        view.galleryView?.setColumns(columns)
      }
      Prop("thumbnailsSpacing") { (view: ExpoSimpleGalleryView, spacing: Double) in
        let spacing = CGFloat(spacing)
        view.galleryView?.setSpacing(spacing)
      }
      Prop("thumbnailStyle") { (view: ExpoSimpleGalleryView, style: [String: Any]) in
        view.galleryView?.setThumbnailStyle(style)
      }
      Prop("contentContainerStyle") { (view: ExpoSimpleGalleryView, style: [String: Any]) in
        view.galleryView?.setContentContainerStyle(style)
      }
      Prop("onThumbnailPress") { (view: ExpoSimpleGalleryView, action: String) in
        view.galleryView?.setThumbnailPressAction(action)
      }
      Prop("onThumbnailLongPress") { (view: ExpoSimpleGalleryView, action: String) in
        view.galleryView?.setThumbnailLongPressAction(action)
      }

    }
  }
}
