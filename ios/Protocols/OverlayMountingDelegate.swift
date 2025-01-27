protocol OverlayMountingDelegate: AnyObject {
  func mount(to cell: GalleryCell, overlay: ReactMountingComponent)
  func mount(to cell: GalleryCell)
  func unmount(from cell: GalleryCell, overlay: ReactMountingComponent)
  func unmount(from cell: GalleryCell)
  func getMountedOverlayComponent(for cell: GalleryCell) -> ReactMountingComponent?
}
