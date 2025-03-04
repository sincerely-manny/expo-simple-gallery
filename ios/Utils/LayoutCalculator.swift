enum LayoutCalculator {
  static func cellSize(for config: GalleryConfiguration, in collectionView: UICollectionView) -> CGSize {
    // Use section inset for horizontal padding in cell calculations
    let horizontalPadding = config.sectionInsets.left + config.sectionInsets.right
    let totalSpacing = CGFloat(max(config.columns - 1, 0)) * config.spacing
    
    // Calculate usable width considering section insets only (not container insets)
    let usableWidth = collectionView.bounds.width - totalSpacing - horizontalPadding

    let cellWidth =
      config.columns == 1 ? floor(usableWidth) : floor(usableWidth / CGFloat(config.columns))
    let cellHeight = floor(cellWidth / config.imageAspectRatio)
    return CGSize(width: cellWidth, height: cellHeight)
  }
}
