protocol OverlayPreloadingDelegate: AnyObject {
  func galleryGrid(
    _ gallery: GalleryGridView,
    prefetchOverlaysFor range: (Int, Int)
  )
}
