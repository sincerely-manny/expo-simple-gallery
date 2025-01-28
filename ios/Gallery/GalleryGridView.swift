import React

// MARK: Main View
final class GalleryGridView: UICollectionView {
  var configuration = GalleryConfiguration()
  var uris: [String] = []

  var thumbnailPressAction: ThumbnailPressAction = .open
  var thumbnailLongPressAction: ThumbnailPressAction = .select
  var thumbnailPanAction: ThumbnailPressAction = .none

  weak var overlayPreloadingDelegate: OverlayPreloadingDelegate?
  weak var overlayMountingDelegate: OverlayMountingDelegate?
  weak var gestureEventDelegate: GestureEventDelegate?
  var selectedAssets = Set<String>()
  var lastVisitedIndexPath: IndexPath?
  var firstVisitedCellWasSelected = false

  init(
    gestureEventDelegate: GestureEventDelegate,
    overlayPreloadingDelegate: OverlayPreloadingDelegate,
    overlayMountingDelegate: OverlayMountingDelegate
  ) {
    let layout = UICollectionViewFlowLayout()
    super.init(frame: .zero, collectionViewLayout: layout)
    self.gestureEventDelegate = gestureEventDelegate
    self.overlayPreloadingDelegate = overlayPreloadingDelegate
    self.overlayMountingDelegate = overlayMountingDelegate
    setupView()
    setupGestures()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Layout Delegate
extension GalleryGridView: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    LayoutCalculator.cellSize(for: configuration, in: collectionView)
  }
}
