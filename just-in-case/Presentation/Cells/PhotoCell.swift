final class PhotoCell: UICollectionViewCell {
  static let identifier = "PhotoCell"

  public let cellView: PhotoCellView

  override init(frame: CGRect) {
    cellView = PhotoCellView(frame: .zero)
    super.init(frame: frame)

    contentView.addSubview(cellView)
    cellView.frame = contentView.bounds
    cellView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with uri: String, imageLoader: ImageLoaderProtocol) {
    cellView.configure(with: uri, imageLoader: imageLoader)
  }

  func setOverlay(_ overlay: UIView?) {
    if let overlay {
      cellView.setOverlay(overlay)
    } else {
      cellView.clearOverlay()
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    cellView.prepareForReuse()
  }
}
