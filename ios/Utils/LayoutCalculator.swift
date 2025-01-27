enum LayoutCalculator {
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
