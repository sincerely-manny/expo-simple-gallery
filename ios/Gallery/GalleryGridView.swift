import React

// MARK: Main View
final class GalleryGridView: UICollectionView {
  private var configuration = GalleryConfiguration()
  private var uris: [String] = []

  private var thumbnailPressAction: ThumbnailPressAction = .open
  private var thumbnailLongPressAction: ThumbnailPressAction = .select

  weak var overlayPreloadingDelegate: OverlayPreloadingDelegate?
  weak var overlayMountingDelegate: OverlayMountingDelegate?
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
    flowLayout.invalidationContext(forBoundsChange: .zero)

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

    if !assets.isEmpty {
      let visibleItems = indexPathsForVisibleItems.map { $0.item }
      if let minItem = visibleItems.min(), let maxItem = visibleItems.max() {
        let range = (minItem, maxItem)
        overlayPreloadingDelegate?.galleryGrid(self, prefetchOverlaysFor: range)
      } else {
        let initialRange = (0, min(assets.count - 1, 30))
        overlayPreloadingDelegate?.galleryGrid(self, prefetchOverlaysFor: initialRange)
      }
    }
  }

  func cell(withIndex index: Int) -> GalleryCell? {
    let indexPath = IndexPath(item: index, section: 0)
    return cellForItem(at: indexPath) as? GalleryCell
  }

  func visibleCells() -> [GalleryCell] {
    let visibleIndexPaths = indexPathsForVisibleItems
    return visibleIndexPaths.compactMap { cellForItem(at: $0) as? GalleryCell }
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

// MARK: - Prefetching
extension GalleryGridView: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    let visibleIndexPaths = collectionView.indexPathsForVisibleItems
    let combinedIndexPaths = indexPaths + visibleIndexPaths
    let allItems = combinedIndexPaths.map { $0.item }
    if let minItem = allItems.min(), let maxItem = allItems.max() {
      let range = (minItem, maxItem)
      overlayPreloadingDelegate?.galleryGrid(self, prefetchOverlaysFor: range)
    }
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
    guard let overlayMountingDelegate else { return }
    cell.configure(
      with: uri, index: indexPath.item, withOverlayMountingDelegate: overlayMountingDelegate)
    cell.applyStyle(configuration: configuration)
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

extension GalleryGridView {
  func setupGestures() {
    let longPressGesture = UILongPressGestureRecognizer(
      target: self, action: #selector(handleLongPress(_:)))
    longPressGesture.minimumPressDuration = 0.5
    addGestureRecognizer(longPressGesture)

    let horizontalPan = HorizontalPanGestureRecognizer(
      target: self, action: #selector(handlePanGesture(_:)))
    horizontalPan.delegate = self
    addGestureRecognizer(horizontalPan)
  }

  @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began else { return }
    let location = gesture.location(in: self)
    guard let indexPath = indexPathForItem(at: location),
      let cell = cellForItem(at: indexPath) as? GalleryCell,
      let cellIndex = cell.cellIndex,
      let cellUri = cell.cellUri
    else {
      return
    }

    print("Long press detected on cell: \(cellIndex)")
  }

  @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
    let location = gesture.location(in: self)

    switch gesture.state {
    case .began:
      print("Pan began")

    case .changed:
      if let indexPath = indexPathForItem(at: location),
        let cell = cellForItem(at: indexPath) as? GalleryCell,
        let cellIndex = cell.cellIndex
      {
        print("New cell visited during pan: \(cellIndex)")
      }

    case .ended:
      print("Pan ended")

    default:
      break
    }
  }
}

extension GalleryGridView: UIGestureRecognizerDelegate {
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let panGesture = gestureRecognizer as? HorizontalPanGestureRecognizer {
      let velocity = panGesture.velocity(in: self)
      return abs(velocity.x) > abs(velocity.y) * 2.0
    }
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    // Don't allow simultaneous recognition between horizontal pan and scroll
    if (gestureRecognizer is HorizontalPanGestureRecognizer && otherGestureRecognizer == panGestureRecognizer)
      || (otherGestureRecognizer is HorizontalPanGestureRecognizer && gestureRecognizer == panGestureRecognizer)
    {
      return false
    }
    return true
  }

}


