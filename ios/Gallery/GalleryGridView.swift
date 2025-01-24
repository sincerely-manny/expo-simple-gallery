final class GalleryGridView: UICollectionView {
  private var configuration = GalleryConfiguration()
  private var uris: [String] = []
  private var cellHierarchy = [Int: [Int: UIView]]()
  private var visibleOverlays = Set<Int>()
  private var prefetchIndexPaths = Set<IndexPath>()
  private let preloadBuffer = 10  // Number of items to preload in each direction
  private var mountedOverlays = Set<Int>()  // Track mounted overlays

  init() {
    let layout = UICollectionViewFlowLayout()
    super.init(frame: .zero, collectionViewLayout: layout)

    backgroundColor = .clear
    dataSource = self
    delegate = self
    prefetchDataSource = self
    register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.identifier)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setAssets(_ assets: [String]) {
    uris = assets
    reloadData()
  }

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

  func setThumbnailStyle(_ style: [String: Any], animated: Bool = true) {
    // Handle style properties
    if let aspectRatio = style["aspectRatio"] as? Double {
      configuration.imageAspectRatio = CGFloat(aspectRatio)
    }
    if let borderRadius = style["borderRadius"] as? Double {
      configuration.borderRadius = CGFloat(borderRadius)
    }
    // Add more style properties as needed

    updateLayout(animated: animated)
  }

  private func updateLayout(animated: Bool) {
    if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
      layout.minimumInteritemSpacing = configuration.spacing
      layout.minimumLineSpacing = configuration.spacing

      if configuration.columns == 1 {
        layout.sectionInset = .zero
      } else {
        layout.sectionInset = UIEdgeInsets(
          top: configuration.spacing,
          left: 0,
          bottom: configuration.spacing,
          right: 0
        )
      }
    }

    collectionViewLayout.invalidateLayout()

    if animated {
      UIView.animate(withDuration: 0.3) {
        self.layoutIfNeeded()
      }
    } else {
      reloadData()
    }
  }

  func setHierarchy(_ hierarchy: [Int: [Int: UIView]]) {
//    print("### Setting hierarchy for indices:", hierarchy.keys.sorted())
    cellHierarchy = hierarchy

    // Log visible cells
    let visibleIndices = indexPathsForVisibleItems.map { $0.item }
//    print("### Currently visible cells:", visibleIndices)

    // Check if we have overlays for visible cells
    for index in visibleIndices {
//      print("### Overlay for cell \(index) exists:", hierarchy[index] != nil)
    }

    // Only update cells that aren't already mounted correctly
    let visiblePaths = indexPathsForVisibleItems
    let cellsToUpdate = visiblePaths.filter { indexPath in
//      print("### Configuring cell at index:", indexPath.item)
      return !mountedOverlays.contains(indexPath.item) || cellHierarchy[indexPath.item] != nil
    }

    if !cellsToUpdate.isEmpty {
      reloadItems(at: cellsToUpdate)
    }
  }

}

extension GalleryGridView: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    prefetchIndexPaths.formUnion(indexPaths)

    // Try to configure overlays for prefetched cells
    for indexPath in indexPaths {
      if let cell = cellForItem(at: indexPath) as? GalleryCell {
        cell.configureOverlay(with: cellHierarchy[indexPath.item] ?? [:])
      }
    }
  }

  func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    prefetchIndexPaths.subtract(indexPaths)
  }
}

extension GalleryGridView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return uris.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: GalleryCell.identifier,
        for: indexPath
      ) as? GalleryCell
    else {
      return UICollectionViewCell()
    }

    let uri = uris[indexPath.item]
    let overlayHierarchy = cellHierarchy[indexPath.item]

    cell.configure(with: uri, index: indexPath.item, overlayHierarchy: overlayHierarchy)
    cell.setBorderRadius(configuration.borderRadius)

    if overlayHierarchy != nil {
      mountedOverlays.insert(indexPath.item)
    }

    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath
  ) {
    mountedOverlays.remove(indexPath.item)
  }
}

extension GalleryGridView: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let totalSpacing = CGFloat(max(configuration.columns - 1, 0)) * configuration.spacing
    let usableWidth = collectionView.bounds.width - totalSpacing

    let cellWidth =
      configuration.columns == 1
      ? floor(collectionView.bounds.width)
      : floor(usableWidth / CGFloat(configuration.columns))

    let cellHeight = floor(cellWidth / configuration.imageAspectRatio)
    return CGSize(width: cellWidth, height: cellHeight)
  }
}

// Configuration struct to hold all gallery settings
struct GalleryConfiguration {
  var columns: Int = 3
  var spacing: CGFloat = 0
  var imageAspectRatio: CGFloat = 1
  var borderRadius: CGFloat = 0
}
