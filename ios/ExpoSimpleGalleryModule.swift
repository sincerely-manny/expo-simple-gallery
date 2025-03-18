import ExpoModulesCore

public class ExpoSimpleGalleryModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoSimpleGallery")
    View(ExpoSimpleGalleryView.self) {
      Events(
        "onThumbnailPress", "onThumbnailLongPress", "onSelectionChange",
        "onOverlayPreloadRequested",
        "onSectionHeadersVisible", "onPreviewMenuOptionSelected"
      )

      Prop("assets") { (view: ExpoSimpleGalleryView, assets: [Any]) in
        if let uris = assets as? [String] {
          view.galleryView?.setAssets(uris: uris)
        } else if let groupedArrays = assets as? [[String]] {
          var flattenedUris: [String] = []
          var sectionData: [[String: Int]] = []
          for (sectionIndex, section) in groupedArrays.enumerated() {
            for (itemIndex, uri) in section.enumerated() {
              flattenedUris.append(uri)
              sectionData.append([
                "sectionIndex": sectionIndex,
                "itemIndex": itemIndex,
              ])
            }
          }
          view.galleryView?.setAssets(uris: flattenedUris, sectionData: sectionData)
        }
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
      Prop("thumbnailPressAction") { (view: ExpoSimpleGalleryView, action: String) in
        view.galleryView?.setThumbnailPressAction(action)
      }
      Prop("thumbnailLongPressAction") { (view: ExpoSimpleGalleryView, action: String) in
        view.galleryView?.setThumbnailLongPressAction(action)
      }
      Prop("thumbnailPanAction") { (view: ExpoSimpleGalleryView, action: String) in
        view.galleryView?.setThumbnailPanAction(action)
      }
      Prop("sectionHeaderStyle") { (view: ExpoSimpleGalleryView, style: [String: Any]) in
        view.galleryView?.setSectionHeaderStyle(style)
      }
      Prop("contextMenuOptions") { (view: ExpoSimpleGalleryView, options: [Any]) in
        view.galleryView?.setContextmenuOptions(options)
      }

      AsyncFunction("centerOnIndex") { (view: ExpoSimpleGalleryView, index: Int) in
        print("AsyncFunction(centerOnIndex)")
        view.galleryView?.centerOnIndex(index)
      }.runOnQueue(.main)

      AsyncFunction("setSelected") { (view: ExpoSimpleGalleryView, uris: [String]) in
        let set = Set(uris)
        view.onSelectionChange(["selected": Array(set)])
        view.galleryView?.selectedAssets = set
      }

      AsyncFunction("setThumbnailPressAction") { (view: ExpoSimpleGalleryView, action: String) in
        view.galleryView?.setThumbnailPressAction(action)
      }
      AsyncFunction("setThumbnailLongPressAction") {
        (view: ExpoSimpleGalleryView, action: String) in
        view.galleryView?.setThumbnailLongPressAction(action)
      }
      AsyncFunction("setThumbnailPanAction") { (view: ExpoSimpleGalleryView, action: String) in
        view.galleryView?.setThumbnailPanAction(action)
      }
      AsyncFunction("setContextMenuOptions") { (view: ExpoSimpleGalleryView, options: [Any]) in
        view.galleryView?.setContextmenuOptions(options)
      }
    }
  }
}
