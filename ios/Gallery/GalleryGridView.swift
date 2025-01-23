final class GalleryGridView: UICollectionView {
  private var configuration = GalleryConfiguration()
  private var uris: [String] = []
  private var cellHierarchy = [Int: [Int: UIView]]()

  init() {
    let layout = UICollectionViewFlowLayout()
    super.init(frame: .zero, collectionViewLayout: layout)

    backgroundColor = .clear
    dataSource = self
    delegate = self
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
    // Store old hierarchy for cleanup
    let oldHierarchy = cellHierarchy
    cellHierarchy = hierarchy

    // Find cells that need updating
    let changedIndices = Set(oldHierarchy.keys).union(hierarchy.keys)
    let indexPaths = changedIndices.map { IndexPath(item: $0, section: 0) }

    // Update visible cells only
    for indexPath in indexPaths {
      if let cell = cellForItem(at: indexPath) as? GalleryCell {
        cell.configureOverlay(with: hierarchy[indexPath.item] ?? [:])
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
