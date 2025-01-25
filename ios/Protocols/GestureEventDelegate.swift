import ExpoModulesCore

struct PressedCell {
  let index: Int
  let uri: String

  func dict() -> [String: Any] {
    return ["index": index, "uri": uri]
  }

}

protocol GestureEventDelegate: AnyObject {
  func galleryGrid(_ gallery: GalleryGridView, didPressCell cell: PressedCell)
  func galleryGrid(_ gallery: GalleryGridView, didLongPressCell cell: PressedCell)
  func galleryGrid(_ gallery: GalleryGridView, didSelectCells assets: Set<String>)
}
