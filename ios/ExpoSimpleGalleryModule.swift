import ExpoModulesCore

public class ExpoSimpleGalleryModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoSimpleGallery")
    View(ExpoSimpleGalleryView.self) {
      Prop("assets") { (view: ExpoSimpleGalleryView, assets: [String]) in
        view.galleryView.setAssets(assets)
      }
      Prop("columnsCount") { (view: ExpoSimpleGalleryView, columns: Int) in
        view.galleryView.setColumns(columns)
      }
      Prop("thumbnailsSpacing") { (view: ExpoSimpleGalleryView, spacing: Double) in
        let spacing = CGFloat(spacing)
        view.galleryView.setSpacing(spacing)
      }
      Prop("thumbnailStyle") { (view: ExpoSimpleGalleryView, style: [String: Any]) in
        view.galleryView.setThumbnailStyle(style)
      }
    }
  }
}
