import React

// MARK: - Setup & Configuration
extension GalleryGridView {
  func setupView() {
    backgroundColor = .clear
    dataSource = self
    delegate = self
    prefetchDataSource = self
    register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.identifier)
    register(
      GallerySectionHeaderView.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: GallerySectionHeaderView.identifier
    )
  }

  func updateLayout(animated: Bool) {
    guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }

    flowLayout.minimumInteritemSpacing = configuration.spacing
    flowLayout.minimumLineSpacing = configuration.spacing
    flowLayout.sectionInset = configuration.sectionInsets
    self.contentInset = configuration.padding
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
  func setAssets(uris: [String]) {
    self.uris = uris
    self.isGroupedLayout = false
    self.sectionData = []

    if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
      flowLayout.headerReferenceSize = .zero
    }

    reloadData()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      guard let self = self else { return }

      if !uris.isEmpty {
        let visibleItems = self.indexPathsForVisibleItems.map { $0.item }
        if let minItem = visibleItems.min(), let maxItem = visibleItems.max() {
          let range = (minItem, maxItem)
          self.overlayPreloadingDelegate?.galleryGrid(self, prefetchOverlaysFor: range)
        } else {
          let initialRange = (0, min(uris.count - 1, 30))
          self.overlayPreloadingDelegate?.galleryGrid(self, prefetchOverlaysFor: initialRange)
        }
      }
    }
  }

  func setAssets(uris: [String], sectionData: [[String: Int]]) {
    self.uris = uris
    self.sectionData = sectionData
    self.isGroupedLayout = true

    // Update header size
    updateSectionHeaderSize()

    reloadData()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      guard let self = self else { return }

      if !uris.isEmpty {
        let visibleIndexPaths = self.indexPathsForVisibleItems
        let flatIndices = visibleIndexPaths.compactMap { indexPath -> Int? in
          // Find the corresponding flat index for this indexPath
          sectionData.firstIndex { dict in
            dict["sectionIndex"] == indexPath.section && dict["itemIndex"] == indexPath.item
          }
        }

        if let minItem = flatIndices.min(), let maxItem = flatIndices.max() {
          let range = (minItem, maxItem)
          self.overlayPreloadingDelegate?.galleryGrid(self, prefetchOverlaysFor: range)
        } else {
          let initialRange = (0, min(uris.count - 1, 30))
          self.overlayPreloadingDelegate?.galleryGrid(self, prefetchOverlaysFor: initialRange)
        }
      }
    }
  }

  func cell(withIndex index: Int) -> GalleryCell? {
    if isGroupedLayout {
      guard index < uris.count, index < sectionData.count else { return nil }

      if let sectionIndex = sectionData[index]["sectionIndex"],
        let itemIndex = sectionData[index]["itemIndex"]
      {

        let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
        return cellForItem(at: indexPath) as? GalleryCell
      }
      return nil
    } else {
      let indexPath = IndexPath(item: index, section: 0)
      return cellForItem(at: indexPath) as? GalleryCell
    }
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
    if let aspectRatio = (style["aspectRatio"] as? Double) ?? Optional(Double(1)) {
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

  func setMediaTypeIconIsVisible(_ isVisible: Bool) {
    configuration.showMediaTypeIcon = isVisible
    updateLayout(animated: false)
  }

  func setContentContainerStyle(_ style: [String: Any], animated: Bool = true) {
    var sectionInsets = UIEdgeInsets.zero
    var containerInsets = UIEdgeInsets.zero

    if let all = style["padding"] as? Double {
      sectionInsets = UIEdgeInsets(
        top: CGFloat(0),
        left: CGFloat(all),
        bottom: CGFloat(0),
        right: CGFloat(all)
      )

      containerInsets = UIEdgeInsets(
        top: CGFloat(all),
        left: CGFloat(0),
        bottom: CGFloat(all),
        right: CGFloat(0)
      )
    }
    if let vertical = style["paddingVertical"] as? Double {
      containerInsets.top = CGFloat(vertical)
      containerInsets.bottom = CGFloat(vertical)
    }
    if let horizontal = style["paddingHorizontal"] as? Double {
      sectionInsets.left = CGFloat(horizontal)
      sectionInsets.right = CGFloat(horizontal)
    }

    if let top = style["paddingTop"] as? Double {
      containerInsets.top = CGFloat(top)
    }
    if let left = style["paddingLeft"] as? Double {
      sectionInsets.left = CGFloat(left)
    }
    if let bottom = style["paddingBottom"] as? Double {
      containerInsets.bottom = CGFloat(bottom)
    }
    if let right = style["paddingRight"] as? Double {
      sectionInsets.right = CGFloat(right)
    }
    if let gap = style["gap"] as? Double ?? Optional(Double(0)) {
      setSpacing(CGFloat(gap))
    }

    configuration.padding = containerInsets
    configuration.sectionInsets = sectionInsets
    updateLayout(animated: animated)
  }

  func setSectionHeaderStyle(_ style: [String: Any]) {
    if let height = style["height"] as? Double {
      configuration.sectionHeaderHeight = CGFloat(height)
      updateSectionHeaderSize()
    }
  }

  func setContextmenuOptions(_ options: [Any]) {
    contextMenuOptions = { cellIndex, cellUri in
      options.enumerated().compactMap { index, option in
        if let dict = option as? [String: Any],
          let title = dict["title"] as? String
        {
          let imageName = dict["sfSymbol"] as? String
          let image = UIImage(systemName: imageName ?? "")
          let attributeNames = dict["attributes"] as? [String] ?? []
          let attributes = attributeNames.reduce(into: UIMenuElement.Attributes()) { result, attr in
            switch attr {
            case "disabled":
              result.insert(.disabled)
            case "destructive":
              result.insert(.destructive)
            case "hidden":
              result.insert(.hidden)
            default:
              break
            }
          }

          let state: UIMenuElement.State = {
            switch dict["state"] as? String {
            case "on": return .on
            case "off": return .off
            case "mixed": return .mixed
            default: return .off
            }
          }()

          return UIAction(title: title, image: image, attributes: attributes, state: state) {
            [weak self] _ in
            self?.contextMenuActionsDelegate?.onPreviewMenuOptionSelected([
              "optionIndex": index, "index": cellIndex, "uri": cellUri,
            ])
          }
        }
        return nil
      }
    }
  }
}
