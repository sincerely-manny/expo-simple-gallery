final class GalleryGridView: UICollectionView {
  private var configuration = GalleryConfiguration()
  private var uris: [String] = []
  private var cellHierarchy = [Int: [Int: UIView]]()
  private var visibleOverlays = Set<Int>()
  private var prefetchIndexPaths: Set<IndexPath> = []

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
    cellHierarchy = hierarchy

    // Update all visible and prefetched cells
    let indexPaths = Set(indexPathsForVisibleItems).union(prefetchIndexPaths)
    for indexPath in indexPaths {
      if let cell = cellForItem(at: indexPath) as? GalleryCell {
        cell.configureOverlay(with: hierarchy[indexPath.item] ?? [:])
      }
    }
  }

  // Handle cleanup
  func cleanup() {
    // Clear all overlays
    for cell in visibleCells.compactMap({ $0 as? GalleryCell }) {
      cell.prepareForReuse()
    }
    cellHierarchy.removeAll()
    visibleOverlays.removeAll()
  }
}

extension GalleryGridView: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    prefetchIndexPaths.formUnion(indexPaths)
  }

  func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    prefetchIndexPaths.subtract(indexPaths)
  }
}

extension GalleryGridView: UICollectionViewDelegate {
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateVisibleCells()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      updateVisibleCells()
    }
  }

  private func updateVisibleCells() {
    let visibleIndexPaths = indexPathsForVisibleItems
    for indexPath in visibleIndexPaths {
      if let cell = cellForItem(at: indexPath) as? GalleryCell {
        cell.configureOverlay(with: cellHierarchy[indexPath.item] ?? [:])
      }
    }
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

    // Configure cell with URI
    let uri = uris[indexPath.item]
    cell.configure(with: uri)
    cell.setBorderRadius(configuration.borderRadius)

    // Configure overlay if exists
    if let viewHierarchy = cellHierarchy[indexPath.item] {
      cell.configureOverlay(with: viewHierarchy)
    }

    return cell
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
