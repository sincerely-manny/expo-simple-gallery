import React

// MARK: Main View
final class GalleryGridView: UICollectionView {
  var configuration = GalleryConfiguration()
  var uris: [String] = []

  var sectionData: [[String: Int]] = []
  var isGroupedLayout: Bool = false

  var thumbnailPressAction: ThumbnailPressAction = .open
  var thumbnailLongPressAction: ThumbnailPressAction = .select
  var thumbnailPanAction: ThumbnailPressAction = .none

  weak var overlayPreloadingDelegate: OverlayPreloadingDelegate?
  weak var overlayMountingDelegate: OverlayMountingDelegate?
  weak var gestureEventDelegate: GestureEventDelegate?
  weak var contextMenuActionsDelegate: ContextMenuActionsDelegate?

  var contextMenuOptions: (Int, String) -> [UIAction] = { _, _ in [] }

  var selectedAssets = Set<String>()
  var lastVisitedIndexPath: IndexPath?
  var firstVisitedCellWasSelected = false

  init(
    gestureEventDelegate: GestureEventDelegate,
    overlayPreloadingDelegate: OverlayPreloadingDelegate,
    overlayMountingDelegate: OverlayMountingDelegate,
    contextMenuActionsDelegate: ContextMenuActionsDelegate
  ) {
    let layout = UICollectionViewFlowLayout()
    super.init(frame: .zero, collectionViewLayout: layout)
    self.gestureEventDelegate = gestureEventDelegate
    self.overlayPreloadingDelegate = overlayPreloadingDelegate
    self.overlayMountingDelegate = overlayMountingDelegate
    self.contextMenuActionsDelegate = contextMenuActionsDelegate
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

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    referenceSizeForHeaderInSection section: Int
  ) -> CGSize {
    guard isGroupedLayout else { return .zero }
    return CGSize(width: collectionView.bounds.width, height: configuration.sectionHeaderHeight)
  }
}

extension GalleryGridView {
  func visibleSectionIndices() -> [Int] {
    guard isGroupedLayout else { return [] }
    let visibleSections = Set(indexPathsForVisibleItems.map { $0.section })
    return Array(visibleSections).sorted()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if isGroupedLayout {
      let visibleSections = visibleSectionIndices()
      overlayPreloadingDelegate?.galleryGrid(self, sectionsVisible: visibleSections)
    }
  }
}

extension GalleryGridView {
  func updateSectionHeaderSize() {
    if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout, isGroupedLayout {
      flowLayout.headerReferenceSize = CGSize(width: bounds.width, height: configuration.sectionHeaderHeight)
    }
  }
}
