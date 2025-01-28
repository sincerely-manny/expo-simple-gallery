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

  func collectionView(
    _ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    if let cell = cell as? GalleryCell {
      overlayMountingDelegate?.mount(to: cell)
    }
  }

  private func configureCell(_ cell: GalleryCell, at indexPath: IndexPath) {
    let uri = uris[indexPath.item]
    guard let overlayMountingDelegate else { return }
    cell.configure(
      with: uri, index: indexPath.item, withOverlayMountingDelegate: overlayMountingDelegate)
    cell.applyStyle(configuration: configuration)
  }
}
