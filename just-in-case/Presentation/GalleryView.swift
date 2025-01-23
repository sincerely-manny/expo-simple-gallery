import ExpoModulesCore
import UIKit

final class GalleryView: UICollectionView {
  // MARK: - Types

  typealias OverlayCollection = [Int: WeakReference<UIView>]

  // MARK: - Properties

  @ThreadSafe private var configuration: GalleryConfiguration
  @ThreadSafe private var overlays: OverlayCollection = [:]
  private var uris: [String] = []
  private let imageLoader: ImageLoaderProtocol
  private weak var flowDelegate: UICollectionViewDelegateFlowLayout?

  // MARK: - Initialization

  init(
    configuration: GalleryConfiguration = .init(),
    imageLoader: ImageLoaderProtocol = ImageLoader()
  ) {
    self.configuration = configuration
    self.imageLoader = imageLoader

    let layout = UICollectionViewFlowLayout()
    super.init(frame: .zero, collectionViewLayout: layout)

    setupCollectionView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  private func setupCollectionView() {
    backgroundColor = .clear
    dataSource = self
    flowDelegate = self
    register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
  }

  // MARK: - Public Methods

  func setAssets(_ assets: [String]) {
    uris = assets
    updateLayout(animated: false)
  }

  func mountOverlay(index: Int, overlay: UIView) {
    assert(Thread.isMainThread)

    overlays[index] = WeakReference(overlay)

    guard let cell = cellForItem(at: IndexPath(item: index, section: 0)) as? PhotoCell else {
      return
    }

    cell.setOverlay(overlay)
  }

  func unmountOverlay(index: Int) {
    assert(Thread.isMainThread)

    overlays.removeValue(forKey: index)

    guard let cell = cellForItem(at: IndexPath(item: index, section: 0)) as? PhotoCell else {
      return
    }

    cell.setOverlay(nil)
  }

  func updateConfiguration(_ update: (inout GalleryConfiguration) -> Void) {
    update(&configuration)
    updateLayout(animated: true)
  }

  // MARK: - Configuration Convenience Methods

  func setColumns(_ count: Int, animated: Bool = true) {
    guard count > 0 else { return }
    configuration.columns = count
    updateLayout(animated: animated)
  }

  func setImageAspectRatio(_ ratio: CGFloat, animated: Bool = true) {
    guard ratio > 0 else { return }
    configuration.imageAspectRatio = ratio
    updateLayout(animated: animated)
  }

  func setSpacing(_ value: CGFloat, animated: Bool = true) {
    guard value >= 0 else { return }
    configuration.spacing = value
    updateLayout(animated: animated)
  }

  func setBorderRadius(_ radius: CGFloat, animated: Bool = true) {
    configuration.borderRadius = radius
    updateLayout(animated: animated)
  }

  // MARK: - Private Methods

  private func updateLayout(animated: Bool) {
    collectionViewLayout.invalidateLayout()
    if animated {
      UIView.animate(withDuration: 0.3) {
        self.layoutIfNeeded()
      }
    } else {
      reloadData()
    }
  }

  private func calculateItemSize(for indexPath: IndexPath, in collectionView: UICollectionView)
    -> CGSize
  {
    let totalSpacing = CGFloat(max(configuration.columns - 1, 0)) * configuration.spacing
    let usableWidth = collectionView.bounds.width - totalSpacing

    let cellWidth: CGFloat
    if configuration.columns == 1 {
      cellWidth = floor(collectionView.bounds.width)
    } else {
      cellWidth = floor(usableWidth / CGFloat(configuration.columns))
    }

    let cellHeight = floor(cellWidth / configuration.imageAspectRatio)
    return CGSize(width: cellWidth, height: cellHeight)
  }
}

// MARK: - UICollectionViewDataSource

extension GalleryView: UICollectionViewDataSource {
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
        withReuseIdentifier: PhotoCell.identifier,
        for: indexPath
      ) as? PhotoCell
    else {
      return UICollectionViewCell()
    }

    let uri = uris[indexPath.item]
    cell.configure(with: uri, imageLoader: imageLoader)

    if let overlay = overlays[indexPath.item]?.value {
      cell.setOverlay(overlay)
    }

    return cell
  }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension GalleryView: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    return calculateItemSize(for: indexPath, in: collectionView)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    if configuration.columns == 1 {
      return .zero
    } else {
      return UIEdgeInsets(
        top: configuration.spacing,
        left: 0,
        bottom: configuration.spacing,
        right: 0
      )
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumInteritemSpacingForSectionAt section: Int
  ) -> CGFloat {
    return configuration.spacing
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int
  ) -> CGFloat {
    return configuration.spacing
  }

  override weak var delegate: UICollectionViewDelegate? {
    get { return super.delegate }
    set {
      super.delegate = newValue
      flowDelegate = newValue as? UICollectionViewDelegateFlowLayout
    }
  }
}

// MARK: - Style Configuration

extension GalleryView {
  func setThumbnailStyle(_ style: [String: Any], animated: Bool = true) {
    // TODO: Implement style configuration
    for (key, value) in style {
      print("Style key:", key, "value:", value)
    }
  }
}

extension GalleryView {
  func getStoredOverlay(for index: Int) -> UIView? {
    return overlays[index]?.value
  }
}
