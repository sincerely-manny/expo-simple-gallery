import Photos
import UIKit

class PhotoCell: UICollectionViewCell {
  static let identifier = "PhotoCell"
  private let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(imageView)
    imageView.frame = contentView.bounds
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with asset: PHAsset) {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.isSynchronous = true
    options.resizeMode = .fast
    manager.requestImage(
      for: asset, targetSize: contentView.bounds.size, contentMode: .aspectFill, options: options
    ) { [weak self] image, _ in
      self?.imageView.image = image
    }
  }
}
