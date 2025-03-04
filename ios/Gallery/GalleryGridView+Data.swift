// MARK: - Data Source
extension GalleryGridView: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    if isGroupedLayout {
      // Find the highest section index + 1
      let maxSection = sectionData.compactMap { $0["sectionIndex"] }.max() ?? 0
      return maxSection + 1
    }
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if isGroupedLayout {
      // Count items in this section
      return sectionData.filter { $0["sectionIndex"] == section }.count
    }
    return uris.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
    let flatIndex: Int

    if isGroupedLayout {
      // Find the flat index from section and item (not row)
      flatIndex =
        sectionData.firstIndex { dict in
          dict["sectionIndex"] == indexPath.section && dict["itemIndex"] == indexPath.item
        } ?? 0
    } else {
      flatIndex = indexPath.item
    }

    guard flatIndex < uris.count else { return }
    let uri = uris[flatIndex]

    guard let overlayMountingDelegate else { return }
    cell.configure(
      with: uri, index: flatIndex, withOverlayMountingDelegate: overlayMountingDelegate)
    cell.applyStyle(configuration: configuration)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    willDisplaySupplementaryView view: UICollectionReusableView,
    forElementKind elementKind: String,
    at indexPath: IndexPath
  ) {
    if elementKind == UICollectionView.elementKindSectionHeader,
      let headerView = view as? GallerySectionHeaderView
    {
      overlayMountingDelegate?.mount(to: headerView)
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    guard isGroupedLayout && kind == UICollectionView.elementKindSectionHeader else {
      return UICollectionReusableView()
    }

    let headerView =
      collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: GallerySectionHeaderView.identifier,
        for: indexPath
      ) as! GallerySectionHeaderView

    // Set the overlay mounting delegate (now the same for all container types)
    headerView.overlayMountingDelegate = overlayMountingDelegate

    // Configure the header
    headerView.configure(for: indexPath.section)
    return headerView
  }
}

// MARK: - Prefetching
extension GalleryGridView: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    let visibleIndexPaths = collectionView.indexPathsForVisibleItems
    let combinedIndexPaths = indexPaths + visibleIndexPaths

    // Convert to flat indices
    var flatIndices: [Int] = []

    for indexPath in combinedIndexPaths {
      if isGroupedLayout {
        if let flatIndex = sectionData.firstIndex(where: { dict in
          dict["sectionIndex"] == indexPath.section && dict["itemIndex"] == indexPath.item
        }) {
          flatIndices.append(flatIndex)
        }
      } else {
        flatIndices.append(indexPath.item)
      }
    }

    if let minItem = flatIndices.min(), let maxItem = flatIndices.max() {
      let range = (minItem, maxItem)
      overlayPreloadingDelegate?.galleryGrid(self, prefetchOverlaysFor: range)
    }
  }
}
