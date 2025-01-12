import ExpoModulesCore

class ExpoSimpleGalleryView: ExpoView {
  let galleryView = GalleryView()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    addSubview(galleryView)
    galleryView.frame = bounds
    galleryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }
}
