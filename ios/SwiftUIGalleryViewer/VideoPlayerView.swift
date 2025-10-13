import AVFoundation
import SwiftUI

struct PlayerView: UIViewRepresentable {
  let player: AVPlayer

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIView(context: Context) -> PlayerUIView {
    let view = PlayerUIView()
    view.playerLayer.player = player
    view.playerLayer.videoGravity = .resizeAspect

    // Looping via notification
    context.coordinator.installLoop(for: player)

    // Autoplay
    player.play()
    return view
  }

  func updateUIView(_ uiView: PlayerUIView, context: Context) {
    if uiView.playerLayer.player !== player {
      uiView.playerLayer.player = player
      context.coordinator.installLoop(for: player)
      player.play()
    }
  }

  static func dismantleUIView(_ uiView: PlayerUIView, coordinator: Coordinator) {
    if let p = uiView.playerLayer.player {
      p.pause()
    }
    coordinator.removeLoop()
  }

  final class Coordinator {
    private var observer: NSObjectProtocol?

    func installLoop(for player: AVPlayer) {
      removeLoop()
      guard let item = player.currentItem else { return }
      observer = NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime,
        object: item,
        queue: .main
      ) { [weak player] _ in
        player?.seek(to: .zero)
        player?.play()
      }
    }

    func removeLoop() {
      if let obs = observer {
        NotificationCenter.default.removeObserver(obs)
        observer = nil
      }
    }
  }
}

final class PlayerUIView: UIView {
  override class var layerClass: AnyClass { AVPlayerLayer.self }
  var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
