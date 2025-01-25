import React

// MARK: - GalleryGridView.swift

// MARK: Main View
final class GalleryGridView: UICollectionView {
  private var configuration = GalleryConfiguration()
  private var uris: [String] = []
  private var cellHierarchy = [Int: [Int: UIView]]()
  private var prefetchIndexPaths = Set<IndexPath>()
  private var mountedOverlays = Set<Int>()

  private var thumbnailPressAction: ThumbnailPressAction = .open
  private var thumbnailLongPressAction: ThumbnailPressAction = .select

  weak var gestureEventDelegate: GestureEventDelegate?
  private var selectedAssets = Set<String>()
  private var isInSelectionMode = true {
    didSet {
      if !isInSelectionMode {
        selectedAssets.removeAll()
        gestureEventDelegate?.galleryGrid(self, didSelectCells: selectedAssets)
      }
    }
  }

  init(gestureEventDelegate: GestureEventDelegate) {
    let layout = UICollectionViewFlowLayout()
    super.init(frame: .zero, collectionViewLayout: layout)
    self.gestureEventDelegate = gestureEventDelegate
    setupView()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Setup & Configuration
extension GalleryGridView {
  fileprivate func setupView() {
    backgroundColor = .clear
    dataSource = self
    delegate = self
    prefetchDataSource = self
    register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.identifier)
  }

  fileprivate func updateLayout(animated: Bool) {
    guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }

    flowLayout.minimumInteritemSpacing = configuration.spacing
    flowLayout.minimumLineSpacing = configuration.spacing
    flowLayout.sectionInset = configuration.padding

    performLayoutUpdate(animated: animated)
  }

  private func performLayoutUpdate(animated: Bool) {
    collectionViewLayout.invalidateLayout()
    animated ? UIView.animate(withDuration: 0.3) { self.layoutIfNeeded() } : reloadData()
  }
}

// MARK: - Public Methods
extension GalleryGridView {
  func setAssets(_ assets: [String]) {
    uris = assets
    reloadData()
  }

  func setHierarchy(_ hierarchy: [Int: [Int: UIView]]) {
    cellHierarchy = hierarchy
    let visiblePaths = indexPathsForVisibleItems
    let cellsToUpdate = visiblePaths.filter {
      !mountedOverlays.contains($0.item) || cellHierarchy[$0.item] != nil
    }
    if !cellsToUpdate.isEmpty { reloadItems(at: cellsToUpdate) }
  }
}

// MARK: - Layout Configuration
extension GalleryGridView {
  func setColumns(_ count: Int, animated: Bool = true) {
    guard count > 0 else { return }
    configuration.columns = count
    updateLayout(animated: animated)
  }

  func setSpacing(_ value: CGFloat, animated: Bool = true) {
    guard value >= 0 else { return }
    configuration.spacing = value
    updateLayout(animated: animated)
  }
}

// MARK: - Style Configuration
extension GalleryGridView {
  func setThumbnailStyle(_ style: [String: Any]) {
    if let aspectRatio = (style["aspectRatio"] as? Double) ?? Optional(Double(0)) {
      configuration.imageAspectRatio = CGFloat(aspectRatio)
    }
    if let borderRadius = style["borderRadius"] as? Double ?? Optional(Double(0)) {
      configuration.borderRadius = CGFloat(borderRadius)
    }
    if let borderWidth = style["borderWidth"] as? Double ?? Optional(Double(0)) {
      configuration.borderWidth = CGFloat(borderWidth)
    }
    if let borderColor = style["borderColor"] as? Int {
      configuration.borderColor = RCTConvert.uiColor(borderColor)
    } else {
      configuration.borderColor = nil
    }

    updateLayout(animated: false)
  }

  func setContentContainerStyle(_ style: [String: Any], animated: Bool = true) {
    var insets = UIEdgeInsets.zero
    if let all = style["padding"] as? Double {
      insets = UIEdgeInsets(
        top: CGFloat(all),
        left: CGFloat(all),
        bottom: CGFloat(all),
        right: CGFloat(all)
      )
    }
    if let vertical = style["paddingVertical"] as? Double {
      insets.top = CGFloat(vertical)
      insets.bottom = CGFloat(vertical)
    }
    if let horizontal = style["paddingHorizontal"] as? Double {
      insets.left = CGFloat(horizontal)
      insets.right = CGFloat(horizontal)
    }

    if let top = style["paddingTop"] as? Double {
      insets.top = CGFloat(top)
    }
    if let left = style["paddingLeft"] as? Double {
      insets.left = CGFloat(left)
    }
    if let bottom = style["paddingBottom"] as? Double {
      insets.bottom = CGFloat(bottom)
    }
    if let right = style["paddingRight"] as? Double {
      insets.right = CGFloat(right)
    }

    configuration.padding = insets
    updateLayout(animated: animated)
  }
}

// MARK: - Gestures
extension GalleryGridView {
  func setThumbnailPressAction(_ action: String) {
    switch action {
    case "select":
      thumbnailPressAction = .select
    case "open":
      thumbnailPressAction = .open
    case "preview":
      thumbnailPressAction = .preview
    case "none":
      thumbnailPressAction = .none
    default:
      thumbnailPressAction = .open
    }
    updateLayout(animated: false)
  }

  func setThumbnailLongPressAction(_ action: String) {
    switch action {
    case "select":
      thumbnailLongPressAction = .select
    case "open":
      thumbnailLongPressAction = .open
    case "preview":
      thumbnailLongPressAction = .preview
    case "none":
      thumbnailLongPressAction = .none
    default:
      thumbnailLongPressAction = .select
    }
    updateLayout(animated: false)
  }
}

// MARK: - Prefetching
extension GalleryGridView: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {

    let visibleIndexPaths = collectionView.indexPathsForVisibleItems
    let combinedIndexPaths = indexPaths + visibleIndexPaths
    let allItems = combinedIndexPaths.map { $0.item }
    if let minItem = allItems.min(), let maxItem = allItems.max() {
      let range = [minItem, maxItem]

      print("Combined range: \(range)")
    }

    prefetchIndexPaths.formUnion(indexPaths)
    indexPaths.forEach { prefetchOverlayIfNeeded(at: $0) }
  }

  func collectionView(
    _ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]
  ) {
    prefetchIndexPaths.subtract(indexPaths)
  }

  private func prefetchOverlayIfNeeded(at indexPath: IndexPath) {
    guard let cell = cellForItem(at: indexPath) as? GalleryCell else { return }
    cell.configureOverlay(with: cellHierarchy[indexPath.item] ?? [:])
  }
}

// MARK: - Data Source
extension GalleryGridView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
    -> Int
  {
    uris.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell
  {
    let cell =
      collectionView.dequeueReusableCell(
        withReuseIdentifier: GalleryCell.identifier, for: indexPath) as! GalleryCell
    configureCell(cell, at: indexPath)
    return cell
  }

  private func configureCell(_ cell: GalleryCell, at indexPath: IndexPath) {
    let uri = uris[indexPath.item]
    let overlay = cellHierarchy[indexPath.item]

    cell.configure(with: uri, index: indexPath.item, overlayHierarchy: overlay)
    cell.applyStyle(configuration: configuration)

    if overlay != nil { mountedOverlays.insert(indexPath.item) }
  }

  func collectionView(
    _ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    mountedOverlays.remove(indexPath.item)
  }
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

// MARK: - Helper Types
struct GalleryConfiguration {
  var columns: Int = 3
  var spacing: CGFloat = 0
  var imageAspectRatio: CGFloat = 1
  var borderRadius: CGFloat = 0
  var borderWidth: CGFloat = 0
  var borderColor: UIColor?
  var padding: UIEdgeInsets = .zero
}

enum ThumbnailPressAction { case select, open, preview, none }

struct ThumbnailStyle {
  let aspectRatio: CGFloat
  let borderRadius: CGFloat
  let borderWidth: CGFloat
  let borderColor: UIColor?
}

struct ContentContainerStyle {
  let padding: UIEdgeInsets
}

// MARK: - Layout Calculator
private enum LayoutCalculator {
  static func cellSize(for config: GalleryConfiguration, in collectionView: UICollectionView)
    -> CGSize
  {
    let horizontalPadding = config.padding.left + config.padding.right
    let totalSpacing = CGFloat(max(config.columns - 1, 0)) * config.spacing
    let usableWidth = collectionView.bounds.width - totalSpacing - horizontalPadding

    let cellWidth =
      config.columns == 1 ? floor(usableWidth) : floor(usableWidth / CGFloat(config.columns))
    let cellHeight = floor(cellWidth / config.imageAspectRatio)
    return CGSize(width: cellWidth, height: cellHeight)
  }
}

extension GalleryGridView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    guard let cell = collectionView.cellForItem(at: indexPath) as? GalleryCell else {
      return
    }
    guard let cellIndex = cell.cellIndex, let cellUri = cell.cellUri else { return }

    let pressedCell = PressedCell(index: cellIndex, uri: cellUri)

    if isInSelectionMode {
      if selectedAssets.contains(cellUri) {
        selectedAssets.remove(cellUri)
      } else {
        selectedAssets.insert(cellUri)
      }
      gestureEventDelegate?.galleryGrid(self, didSelectCells: selectedAssets)
    }
    gestureEventDelegate?.galleryGrid(self, didPressCell: pressedCell)

  }
}
