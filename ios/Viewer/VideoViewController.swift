import AVFoundation
import UIKit

class VideoViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let videoContainerView = UIView()
  private let activityIndicator = UIActivityIndicatorView(style: .large)

  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var timeObserver: Any?

  weak var delegate: MediaViewControllerDelegate?
  private var panGesture: UIPanGestureRecognizer!
  private var initialScrollViewContentOffset = CGPoint.zero
  private var isDraggingDown = false

  private(set) var index: Int = 0
  private var uri: String = ""

  override func viewDidLoad() {
    super.viewDidLoad()
    setupScrollView()
    setupVideoContainer()
    setupActivityIndicator()
    setupPlayPauseButton()
    setupGestures()
  }

  private func setupScrollView() {
    view.backgroundColor = .clear
    scrollView.frame = view.bounds
    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 2.0  // Less zoom for videos
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.bounces = true
    scrollView.alwaysBounceVertical = true
    scrollView.isDirectionalLockEnabled = true
    view.addSubview(scrollView)
  }

  private func setupVideoContainer() {
    videoContainerView.frame = scrollView.bounds
    videoContainerView.backgroundColor = .clear
    scrollView.addSubview(videoContainerView)
  }

  private func setupActivityIndicator() {
    activityIndicator.color = .white
    activityIndicator.hidesWhenStopped = true
    view.addSubview(activityIndicator)
    activityIndicator.center = view.center
  }

  private let playPauseButton: UIButton = {
    let button = UIButton(type: .system)

    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: "play.circle")
    config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 65, weight: .bold)

    button.configuration = config
    button.tintColor = .white

    let blurEffect = UIBlurEffect(style: .dark)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
    blurView.layer.cornerRadius = 40
    blurView.clipsToBounds = true
    button.insertSubview(blurView, at: 0)

    button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
    button.layer.cornerRadius = 40
    button.clipsToBounds = true

    button.isUserInteractionEnabled = false

    return button
  }()

  private func setupPlayPauseButton() {
    playPauseButton.center = view.center
    view.addSubview(playPauseButton)
  }

  private func setupGestures() {
    // Pan gesture for dismissing
    panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    panGesture.delegate = self
    view.addGestureRecognizer(panGesture)

    // Tap gesture on video to toggle play/pause
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(togglePlayPause))
    videoContainerView.addGestureRecognizer(tapGesture)
    videoContainerView.isUserInteractionEnabled = true
  }

  func configure(with playerItem: AVPlayerItem, uri: String, index: Int) {
    self.index = index
    self.uri = uri

    // Clean up existing player if any
    cleanupPlayer()

    // Create new player and layer
    player = AVPlayer(playerItem: playerItem)
    playerLayer = AVPlayerLayer(player: player)
    playerLayer?.videoGravity = .resizeAspect

    playerLayer?.frame = videoContainerView.bounds
    videoContainerView.layer.addSublayer(playerLayer!)

    // Add time observer to update UI
    timeObserver = player?.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
      queue: DispatchQueue.main
    ) { [weak self] _ in
      self?.updatePlayPauseButton()
    }

    updateViewFrames()
    updatePlayPauseButton()

    // Listen for end of playback
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(playerDidFinishPlaying),
      name: .AVPlayerItemDidPlayToEndTime,
      object: playerItem
    )
  }

  private func updateViewFrames() {
    scrollView.frame = view.bounds
    videoContainerView.frame = scrollView.bounds
    playerLayer?.frame = videoContainerView.bounds
    scrollView.contentSize = videoContainerView.bounds.size
    activityIndicator.center = view.center
    playPauseButton.center = view.center
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateViewFrames()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updatePlayPauseButton()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    player?.pause()
  }

  @objc private func togglePlayPause() {
    guard let player = player else { return }

    if player.timeControlStatus == .playing {
      
      player.pause()
    } else {
      UIView.transition(with: playPauseButton, duration: 0.2, options: .transitionCrossDissolve) {
        self.playPauseButton.configuration?.image = UIImage(systemName: "pause.circle")
      }
      // If at end, rewind first
      if player.currentItem?.currentTime() == player.currentItem?.duration {
        player.seek(to: CMTime.zero)
      }
      player.play()
    }

    updatePlayPauseButton()
  }

  @objc private func playerDidFinishPlaying() {
    DispatchQueue.main.async {
      self.player?.seek(to: CMTime.zero)
      self.player?.pause()
      self.updatePlayPauseButton()
    }
  }

  private func updatePlayPauseButton() {
    guard let player = player else { return }

    if player.timeControlStatus == .playing {
      playPauseButton.isSelected = true
      UIView.transition(with: playPauseButton, duration: 0.2, options: .transitionCrossDissolve) {
        self.playPauseButton.configuration?.image = UIImage(systemName: "pause.circle")
      }
      // Hide the button after a short delay while playing
      UIView.animate(withDuration: 0.3) {
        self.playPauseButton.alpha = 0.0
      }
    } else {
      playPauseButton.isSelected = false
      UIView.transition(with: playPauseButton, duration: 0.2, options: .transitionCrossDissolve) {
        self.playPauseButton.configuration?.image = UIImage(systemName: "play.circle")
      }
      // Show the button when paused
      UIView.animate(withDuration: 0.3) {
        self.playPauseButton.alpha = 1.0
      }
    }
  }

  private func cleanupPlayer() {
    if let timeObserver = timeObserver, let player = player {
      player.removeTimeObserver(timeObserver)
    }

    playerLayer?.removeFromSuperlayer()
    player?.pause()
    player = nil
    playerLayer = nil
    timeObserver = nil

    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
  }

  func pauseAndPrepareForReuse() {
    player?.pause()
    updatePlayPauseButton()
    player?.seek(to: .zero)
  }

  deinit {
    cleanupPlayer()
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
}

extension VideoViewController: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return videoContainerView
  }
}

extension VideoViewController: UIGestureRecognizerDelegate {
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
