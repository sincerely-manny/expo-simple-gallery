import React

// MARK: - Setup & Configuration
extension GalleryGridView {
  func setupView() {
    backgroundColor = .clear
    dataSource = self
    delegate = self
    prefetchDataSource = self
    register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.identifier)
  }

  func updateLayout(animated: Bool) {
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
