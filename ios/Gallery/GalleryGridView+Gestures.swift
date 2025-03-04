// MARK: - Gestures
extension GalleryGridView {
  func setThumbnailPressAction(_ action: String) {
    switch action {
    case "select":
      thumbnailPressAction = .select
    case "open":
      thumbnailPressAction = .open
    //case "preview":
    //  thumbnailPressAction = .preview
    case "none":
      thumbnailPressAction = .none
    default:
      thumbnailPressAction = .open
    }
    //    updateLayout(animated: false)
    //    reloadData()
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
    //updateLayout(animated: false)
    //    reloadData()
  }

  func setThumbnailPanAction(_ action: String) {
    switch action {
    case "select":
      thumbnailPanAction = .select
    default:
      thumbnailPanAction = .none
    }
    //updateLayout(animated: false)
    //    reloadData()
  }
}

extension GalleryGridView: UICollectionViewDelegate {
  // Handle tap selection
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) as? GalleryCell,
      let cellIndex = cell.cellIndex,
      let cellUri = cell.cellUri
    else { return }

    switch thumbnailPressAction {
    case .select:
      handleSelect(cell: cell)
    case .open:
      handleOpen(cell: cell)
    case .preview:
      handlePreview(cell: cell)
    case .none:
      break
    }

    gestureEventDelegate?.galleryGrid(
      self,
      didPressCell: PressedCell(index: cellIndex, uri: cellUri)
    )
  }

  // Context menu configuration (long press)
  func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfigurationForItemAt indexPath: IndexPath,
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    if thumbnailLongPressAction != .preview { return nil }

    guard let cell = cellForItem(at: indexPath) as? GalleryCell,
      let urlString = cell.cellUri,
      let cellIndex = cell.cellIndex,
      let url = URL(string: urlString)
    else { return nil }

    gestureEventDelegate?.galleryGrid(
      self,
      didLongPressCell: PressedCell(index: cellIndex, uri: urlString)
    )

    return UIContextMenuConfiguration(
      identifier: indexPath as NSCopying,
      previewProvider: {
        PreviewViewController(imageUrl: url)
      },
      actionProvider: { _ in
        return UIMenu(title: "", children: self.contextMenuOptions(cellIndex, urlString))
      }
    )
  }

  // Preview animation customization
  func collectionView(
    _ collectionView: UICollectionView,
    previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
  ) -> UITargetedPreview? {
    guard let indexPath = configuration.identifier as? IndexPath,
      let cell = collectionView.cellForItem(at: indexPath) as? GalleryCell
    else { return nil }

    let parameters = UIPreviewParameters()
    parameters.backgroundColor = .clear
    parameters.visiblePath = UIBezierPath(
      roundedRect: cell.bounds, cornerRadius: self.configuration.borderRadius)

    return UITargetedPreview(
      view: cell,
      parameters: parameters
    )
  }

  // Dismissal animation customization
  func collectionView(
    _ collectionView: UICollectionView,
    previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
  ) -> UITargetedPreview? {
    guard let indexPath = configuration.identifier as? IndexPath,
      let cell = collectionView.cellForItem(at: indexPath) as? GalleryCell
    else { return nil }

    let parameters = UIPreviewParameters()
    parameters.backgroundColor = .clear
    parameters.visiblePath = UIBezierPath(
      roundedRect: cell.bounds, cornerRadius: self.configuration.borderRadius)

    return UITargetedPreview(
      view: cell,
      parameters: parameters
    )
  }

  // Optional: Handle context menu dismissal
  func collectionView(
    _ collectionView: UICollectionView,
    didEndContextMenuInteractionForItemAt indexPath: IndexPath
  ) {
    //    print("Context menu dismissed for item at \(indexPath)")
  }
}

extension GalleryGridView {
  func setupGestures() {
    let preLongPressGesture = UILongPressGestureRecognizer(
      target: self, action: #selector(handlePreLongPress(_:)))
    addGestureRecognizer(preLongPressGesture)
    preLongPressGesture.minimumPressDuration = 0.2
    preLongPressGesture.cancelsTouchesInView = false
    preLongPressGesture.delegate = self
    addGestureRecognizer(preLongPressGesture)

    let longPressGesture = UILongPressGestureRecognizer(
      target: self, action: #selector(handleLongPress(_:)))
    longPressGesture.minimumPressDuration = 0.5
    preLongPressGesture.delegate = self
    addGestureRecognizer(longPressGesture)

    let horizontalPan = HorizontalPanGestureRecognizer(
      target: self, action: #selector(handlePanGesture(_:)))
    horizontalPan.delegate = self
    addGestureRecognizer(horizontalPan)
  }

  @objc private func handlePreLongPress(_ gesture: UILongPressGestureRecognizer) {
    switch thumbnailLongPressAction {
    case .select, .open:
      break
    default:
      return
    }

    let location = gesture.location(in: self)
    guard let indexPath = indexPathForItem(at: location),
      let cell = cellForItem(at: indexPath) as? GalleryCell
    else { return }

    switch gesture.state {
    case .began:
      UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
        cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
      }
    default:
      UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseInOut]) {
        cell.transform = .identity
      }
    }
  }

  @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    switch thumbnailLongPressAction {
    case .select, .open:
      break
    default:
      return
    }

    let location = gesture.location(in: self)
    guard let indexPath = indexPathForItem(at: location),
      let cell = cellForItem(at: indexPath) as? GalleryCell,
      let cellIndex = cell.cellIndex,
      let cellUri = cell.cellUri
    else { return }

    switch gesture.state {
    case .began:
      gestureEventDelegate?.galleryGrid(
        self,
        didLongPressCell: PressedCell(index: cellIndex, uri: cellUri)
      )
      UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
        if self.thumbnailLongPressAction == .select {
          cell.transform = .identity
        } else {
          cell.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
      }
    default:
      UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseInOut]) {
        cell.transform = .identity
      }
    }

    guard gesture.state == .began else { return }
    switch thumbnailLongPressAction {
    case .select:
      handleSelect(cell: cell)
    case .open:
      handleOpen(cell: cell)
    //case .preview:
    //  handlePreview(cell: cell)
    case .preview, .none:
      break
    }
  }

  @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
    guard thumbnailPanAction != .none else { return }
    let location = gesture.location(in: self)
    let indexPath = indexPathForItem(at: location)
    guard indexPath != lastVisitedIndexPath else { return }
    lastVisitedIndexPath = indexPath
    guard let indexPath = indexPath,
      let cell = cellForItem(at: indexPath) as? GalleryCell,
      cell.cellIndex != nil,
      let cellUri = cell.cellUri
    else {
      return
    }

    switch gesture.state {
    case .began:
      firstVisitedCellWasSelected = selectedAssets.contains(cellUri)
      handleSelect(cell: cell, newState: !firstVisitedCellWasSelected)
    case .changed:
      handleSelect(cell: cell, newState: !firstVisitedCellWasSelected)
    default:
      break
    }
  }

  private func handleSelect(cell: GalleryCell, newState: Bool? = nil) {
    guard let cellUri = cell.cellUri else { return }
    let currentState = selectedAssets.contains(cellUri)
    if currentState == newState { return }
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()

    if let newState = newState {
      if newState {
        selectedAssets.insert(cellUri)
      } else {
        selectedAssets.remove(cellUri)
      }
    } else {
      if selectedAssets.contains(cellUri) {
        selectedAssets.remove(cellUri)
      } else {
        selectedAssets.insert(cellUri)
      }
    }
    gestureEventDelegate?.galleryGrid(self, didSelectCells: selectedAssets)
  }

  private func handleOpen(cell: GalleryCell) {
    // handled in JS
  }

  private func handlePreview(cell: GalleryCell) {
    // handled with Preview API
  }
}

extension GalleryGridView: UIGestureRecognizerDelegate {
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let panGesture = gestureRecognizer as? HorizontalPanGestureRecognizer {
      let velocity = panGesture.velocity(in: self)
      let touchPoint = panGesture.location(in: self)

      // Check for left edge swipe - don't begin our gesture if it's near the edge
      let isNearLeftEdge = touchPoint.x < 50
      if isNearLeftEdge && velocity.x > 0 {
        return false
      }

      return abs(velocity.x) > abs(velocity.y) * 2.0
    }
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    if gestureRecognizer is UILongPressGestureRecognizer {
      if otherGestureRecognizer is UILongPressGestureRecognizer {
        return true
      } else {
        return false
      }
    }
    // Don't allow simultaneous recognition between horizontal pan and scroll
    if (gestureRecognizer is HorizontalPanGestureRecognizer
      && otherGestureRecognizer == panGestureRecognizer)
      || (otherGestureRecognizer is HorizontalPanGestureRecognizer
        && gestureRecognizer == panGestureRecognizer)
    {
      return false
    }
    return true
  }

}

extension GalleryGridView: ScrollableToIndexDelegate {
  func centerOnIndex(_ index: Int) {
    if isGroupedLayout {
      guard index < uris.count, index < sectionData.count else { return }
      if let sectionIndex = sectionData[index]["sectionIndex"],
        let itemIndex = sectionData[index]["itemIndex"]
      {
        let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
        scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
      }
    } else {
      let indexPath = IndexPath(item: index, section: 0)
      scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }
  }
}
