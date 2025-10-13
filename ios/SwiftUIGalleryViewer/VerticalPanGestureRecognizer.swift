import SwiftUI
import UIKit

private final class VerticalPanGestureRecognizer: UIPanGestureRecognizer {
  private var hasDeterminedDirection = false
  private let tolerance: CGFloat = 3  // small slop before deciding

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    guard let view = self.view else { return }
    if !hasDeterminedDirection {
      let t = translation(in: view)
      // If clearly horizontal, fail fast so UIPageViewController can take over immediately
      if abs(t.x) > abs(t.y) + tolerance {
        state = .failed
      } else if t.y > 0, abs(t.y) > abs(t.x) + tolerance {
        hasDeterminedDirection = true  // lock-in vertical downward
      }
    }
  }

  override func reset() {
    super.reset()
    hasDeterminedDirection = false
  }
}

// UIKit-backed vertical pan overlay that coexists with TabView’s horizontal swipe by failing fast for horizontal drags.
struct VerticalPanOverlay: UIViewRepresentable {
  var onChanged: (_ translationY: CGFloat, _ translation: CGPoint) -> Void
  var onEnded: (_ translationY: CGFloat, _ velocityY: CGFloat, _ translation: CGPoint) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onChanged: onChanged, onEnded: onEnded)
  }

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear
    view.isUserInteractionEnabled = true

    let pan = VerticalPanGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
    pan.maximumNumberOfTouches = 1
    pan.cancelsTouchesInView = false  // do not block TabView’s paging
    pan.delaysTouchesBegan = false
    pan.delaysTouchesEnded = false
    pan.delegate = context.coordinator

    view.addGestureRecognizer(pan)
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {}

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    let onChanged: (_ translationY: CGFloat, _ translation: CGPoint) -> Void
    let onEnded: (_ translationY: CGFloat, _ velocityY: CGFloat, _ translation: CGPoint) -> Void

    init(
      onChanged: @escaping (_ translationY: CGFloat, _ translation: CGPoint) -> Void,
      onEnded:
        @escaping (_ translationY: CGFloat, _ velocityY: CGFloat, _ translation: CGPoint) -> Void
    ) {
      self.onChanged = onChanged
      self.onEnded = onEnded
    }

    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
      guard let view = pan.view else { return }
      let translation = pan.translation(in: view)
      let translationY = translation.y

      switch pan.state {
      case .changed:
        // Only update for downward motion
        if translationY > 0 {
          onChanged(translationY, translation)
        } else {
          onChanged(0, translation)
        }
      case .ended, .cancelled, .failed:
        let velocity = pan.velocity(in: view)
        onEnded(max(0, translationY), velocity.y, translation)
      default:
        break
      }
    }

    // No simultaneous recognition needed now that we fail fast on horizontal drags.
    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      return false
    }

    // Begin by default; our recognizer will quickly fail for horizontal.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      true
    }
  }
}
