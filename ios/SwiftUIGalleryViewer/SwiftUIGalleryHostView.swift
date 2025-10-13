import ExpoModulesCore
import SwiftUI
import UIKit

// Hosts the SwiftUI view inside an ExpoView, bridging props and events
final class SwiftUIGalleryHostView: ExpoView {
  // Events exposed to JS
  let onPageChange = EventDispatcher()
  let onImageLoaded = EventDispatcher()
  let onDismissAttempt = EventDispatcher()

  private let viewModel = SwiftUIGalleryViewModel()

  // Lazy so we can capture `self` safely after `super.init`
  private lazy var hostingController: UIHostingController<SwiftUIGalleryView> = {
    let swiftUIView = SwiftUIGalleryView(
      viewModel: viewModel,
      onPageChange: { [weak self] index, uri in
        guard let self = self else { return }
        self.viewModel.index = index
        self.onPageChange(["index": index, "uri": uri])
      },
      onImageLoaded: { [weak self] index, uri in
        self?.onImageLoaded(["index": index, "uri": uri])
      },
      onDismissAttempt: { [weak self] in
        guard let self = self else { return }
        guard self.currentIndex >= 0, self.currentIndex < self.currentUris.count else { return }
        self.onDismissAttempt([
          "index": self.currentIndex,
          "uri": self.currentUris[self.currentIndex],
        ])
      }
    )
    let hc = UIHostingController(rootView: swiftUIView)
    hc.view.backgroundColor = .black
    return hc
  }()

  private var currentUris: [String] = []
  private var currentIndex: Int = 0

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)

    clipsToBounds = true

    // Attach hostingController's view as a subview (triggers lazy init safely)
    let hostedView = hostingController.view!
    hostedView.backgroundColor = .black
    hostedView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(hostedView)

    // Pin to edges
    NSLayoutConstraint.activate([
      hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
      hostedView.topAnchor.constraint(equalTo: topAnchor),
      hostedView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  // Prop: imageData { uris, startIndex }
  func setImageData(uris: [String], startIndex: Int) {
    currentUris = uris
    let clamped = max(0, min(startIndex, max(uris.count - 1, 0)))
    currentIndex = clamped

    viewModel.uris = uris
    viewModel.index = clamped

    if clamped >= 0, clamped < uris.count {
      // Emit initial page to match UIKit behavior
      onPageChange(["index": clamped, "uri": uris[clamped]])
    }
  }

  // Prop: goToPage index
  func goToPage(_ index: Int) {
    guard !currentUris.isEmpty else { return }
    let clamped = max(0, min(index, currentUris.count - 1))
    currentIndex = clamped
    viewModel.index = clamped
    onPageChange(["index": clamped, "uri": currentUris[clamped]])
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    hostingController.view.frame = bounds
  }
}
