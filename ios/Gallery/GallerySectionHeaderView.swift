import ExpoModulesCore
import UIKit

class GallerySectionHeaderView: UICollectionReusableView, OverlayContainer {
  static let identifier = "GallerySectionHeader"

  let overlayContainer: ExpoView
  var sectionIndex: Int?
  var containerIdentifier: Int? { return sectionIndex }

  weak var overlayMountingDelegate: OverlayMountingDelegate?

  override init(frame: CGRect) {
    overlayContainer = ExpoView(frame: frame)
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    backgroundColor = .clear

    // Add the overlay container on top
    addSubview(overlayContainer)
    overlayContainer.translatesAutoresizingMaskIntoConstraints = false
    overlayContainer.clipsToBounds = true

    NSLayoutConstraint.activate([
      overlayContainer.topAnchor.constraint(equalTo: topAnchor),
      overlayContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
      overlayContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
      overlayContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  func configure(for section: Int) {
    sectionIndex = section
    overlayMountingDelegate?.mount(to: self)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    overlayMountingDelegate?.unmount(from: self)
  }
}
