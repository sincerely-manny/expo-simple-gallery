import PhotosUI
import UIKit

class LivePhotoViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let livePhotoView = PHLivePhotoView()
  private let activityIndicator = UIActivityIndicatorView(style: .large)

  weak var delegate: MediaViewControllerDelegate?
  private var panGesture: UIPanGestureRecognizer!
  private var isDraggingDown = false
  private var isPlaying = false

  private(set) var index: Int = 0
  private var uri: String = ""

  override func viewDidLoad() {
    super.viewDidLoad()
    setupScrollView()
    setupLivePhotoView()
    setupActivityIndicator()
    setupGestures()
  }

  private func setupScrollView() {
    view.backgroundColor = .clear
    scrollView.frame = view.bounds
    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 3.0
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.bounces = true
    scrollView.alwaysBounceVertical = true
    scrollView.isDirectionalLockEnabled = true
    scrollView.decelerationRate = .normal
    view.addSubview(scrollView)
  }

  private func setupLivePhotoView() {
    livePhotoView.delegate = self
    livePhotoView.frame = scrollView.bounds
    livePhotoView.contentMode = .scaleAspectFit
    scrollView.addSubview(livePhotoView)
  }

  private func setupActivityIndicator() {
    activityIndicator.color = .white
    activityIndicator.hidesWhenStopped = true
    view.addSubview(activityIndicator)
    activityIndicator.center = view.center
  }

  private func setupGestures() {
    // Pan gesture for dismissing
    panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    panGesture.delegate = self
    view.addGestureRecognizer(panGesture)

    // Tap gesture to play/stop the live photo
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    livePhotoView.addGestureRecognizer(tapGesture)
    livePhotoView.isUserInteractionEnabled = true
  }

  func configure(with livePhoto: PHLivePhoto, uri: String, index: Int) {
    self.index = index
    self.uri = uri
    livePhotoView.livePhoto = livePhoto
    updateViewFrames()
  }

  private func updateViewFrames() {
    scrollView.frame = view.bounds
    livePhotoView.frame = scrollView.bounds
    scrollView.contentSize = livePhotoView.bounds.size
    activityIndicator.center = view.center
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateViewFrames()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !isPlaying && livePhotoView.livePhoto != nil {
      livePhotoView.startPlayback(with: .hint)
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopPlaybackAndPrepareForReuse()
  }

  @objc private func handleTap() {
    if isPlaying {
      livePhotoView.stopPlayback()
    } else if livePhotoView.livePhoto != nil {
      livePhotoView.startPlayback(with: .full)
    }
  }

  @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: view)
    let velocity = gesture.velocity(in: view)

    switch gesture.state {
    case .began:
      isDraggingDown = scrollView.contentOffset.y <= 50

    case .changed:
      guard isDraggingDown else { return }

      let verticalDrag = translation.y
      let percentage = min(max(verticalDrag / 200.0, 0), 1)

      let scale = 1 - percentage * 0.2  // Scale down to 80% at most
      view.transform = CGAffineTransform(scaleX: scale, y: scale)
        .translatedBy(x: 0, y: verticalDrag / 2)

    case .ended, .cancelled:
      guard isDraggingDown else { return }

      let verticalVelocity = velocity.y
      let verticalTranslation = translation.y

      if verticalVelocity > 1000 || verticalTranslation > 100 {
        delegate?.mediaViewControllerDidRequestDismiss(self)
      } else {
        UIView.animate(withDuration: 0.3) {
          self.view.transform = .identity
        }
      }

      isDraggingDown = false

    default:
      break
    }
  }

  func stopPlaybackAndPrepareForReuse() {
    if isPlaying {
      livePhotoView.stopPlayback()
      isPlaying = false
    }
  }
}

extension LivePhotoViewController: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return livePhotoView
  }
}

extension LivePhotoViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer === panGesture {
      let velocity = panGesture.velocity(in: view)
      let isScrolledToTop = scrollView.contentOffset.y <= 0
      let isMainlyVertical = abs(velocity.y) > abs(velocity.x) * 1.5

      return isScrolledToTop && velocity.y > 0 && isMainlyVertical
    }
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    // Allow simultaneous recognition with scrollView's pan gesture
    if gestureRecognizer === panGesture && otherGestureRecognizer === scrollView.panGestureRecognizer {
      return true
    }

    return false
  }
}

extension LivePhotoViewController: PHLivePhotoViewDelegate {
  func livePhotoViewDidStartPlayback(_ livePhotoView: PHLivePhotoView) {
    isPlaying = true
  }

  func livePhotoViewDidStopPlayback(_ livePhotoView: PHLivePhotoView) {
    isPlaying = false
  }
}
