import React

final class GalleryGridView: UICollectionView {
  private var configuration = GalleryConfiguration()
  private var uris: [String] = []
  private var cellHierarchy = [Int: [Int: UIView]]()
  private var prefetchIndexPaths = Set<IndexPath>()
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

  private func updateLayout(animated: Bool) {
    if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
      layout.minimumInteritemSpacing = configuration.spacing
      layout.minimumLineSpacing = configuration.spacing
      layout.sectionInset = configuration.padding
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

    // Only update cells that aren't already mounted correctly
    let visiblePaths = indexPathsForVisibleItems
    let cellsToUpdate = visiblePaths.filter { indexPath in
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

  func collectionView(
    _ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]
  ) {
    prefetchIndexPaths.subtract(indexPaths)
  }
}

extension GalleryGridView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
    -> Int
  {
    return uris.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell
  {
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
    cell.setBorderWidth(configuration.borderWidth)
    cell.setBorderColor(configuration.borderColor)

    if overlayHierarchy != nil {
      mountedOverlays.insert(indexPath.item)
    }

    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
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
    // Account for padding in width calculation
    let horizontalPadding = configuration.padding.left + configuration.padding.right
    let totalSpacing = CGFloat(max(configuration.columns - 1, 0)) * configuration.spacing
    let usableWidth = collectionView.bounds.width - totalSpacing - horizontalPadding

    let cellWidth =
      configuration.columns == 1
      ? floor(usableWidth)
      : floor(usableWidth / CGFloat(configuration.columns))

    let cellHeight = floor(cellWidth / configuration.imageAspectRatio)
    return CGSize(width: cellWidth, height: cellHeight)
  }
}

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

  func setThumbnailStyle(_ style: [String: Any]) {
    // Handle style properties
    if let aspectRatio = style["aspectRatio"] as? Double {
      configuration.imageAspectRatio = CGFloat(aspectRatio)
    }
    if let borderRadius = style["borderRadius"] as? Double {
      configuration.borderRadius = CGFloat(borderRadius)
    }
    if let borderWidth = style["borderWidth"] as? Double {
      configuration.borderWidth = CGFloat(borderWidth)
    }
    if let borderColor = style["borderColor"] as? Int {
      configuration.borderColor = RCTConvert.uiColor(borderColor)
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

// Configuration struct to hold all gallery settings
struct GalleryConfiguration {
  var columns: Int = 3
  var spacing: CGFloat = 0

  var imageAspectRatio: CGFloat = 1
  var borderRadius: CGFloat = 0
  var borderWidth: CGFloat = 0
  var borderColor: UIColor? = nil

  var padding: UIEdgeInsets = .zero
}
