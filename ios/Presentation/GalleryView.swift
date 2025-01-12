import Photos
import UIKit

class GalleryView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
  private var photoAssets: [PHAsset] = []

  init() {
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: 100, height: 100)  // Thumbnail size
    layout.minimumInteritemSpacing = 5
    layout.minimumLineSpacing = 5
    super.init(frame: .zero, collectionViewLayout: layout)
    backgroundColor = .white
    dataSource = self
    delegate = self
    register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
    fetchPhotos()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func fetchPhotos() {
    PHPhotoLibrary.requestAuthorization { [weak self] status in
      guard status == .authorized else { return }
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
      self?.photoAssets = (0..<assets.count).compactMap { assets.object(at: $0) }
      DispatchQueue.main.async {
        self?.reloadData()
      }
    }
  }

  // MARK: UICollectionViewDataSource

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
    -> Int
  {
    return photoAssets.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell
  {
    guard
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: PhotoCell.identifier, for: indexPath) as? PhotoCell
    else {
      return UICollectionViewCell()
    }
    let asset = photoAssets[indexPath.item]
    cell.configure(with: asset)
    return cell
  }

  // MARK: UICollectionViewDelegateFlowLayout

  func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let side = (collectionView.bounds.width - 20) / 3  // Three columns with spacing
    return CGSize(width: side, height: side)
  }
}
