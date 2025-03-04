protocol OverlayPreloadingDelegate: AnyObject {
  func galleryGrid(
    _ gallery: GalleryGridView,
    prefetchOverlaysFor range: (Int, Int)
  )

  func galleryGrid(
    _ gallery: GalleryGridView,
    sectionsVisible sections: [Int]
  )
}

extension OverlayPreloadingDelegate {
  func galleryGrid(
    _ gallery: GalleryGridView,
    sectionsVisible sections: [Int]
  ) {
    // Default empty implementation
  }
}
